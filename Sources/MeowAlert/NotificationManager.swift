import AppKit
import UserNotifications

@MainActor
final class NotificationManager {
    enum AuthorizationState {
        case authorized
        case unavailable(String)
    }

    private var isBundleBackedApp: Bool {
        let isAppBundle = Bundle.main.bundleURL.pathExtension.lowercased() == "app"
        let hasBundleIdentifier = (Bundle.main.bundleIdentifier?.isEmpty == false)
        return isAppBundle && hasBundleIdentifier
    }

    private let audioInterruptionManager = AudioInterruptionManager()
    private(set) var lastUnavailableMessage: String?
    private let alertSoundCooldown: TimeInterval = 15
    private var lastAlertSoundPlaybackAt: Date?

    private func playBundledSoundFallback(named soundFileName: String) {
        let playbackDuration: TimeInterval
        guard let soundURL = AlertSoundCatalog.soundURL(for: soundFileName),
              let sound = NSSound(contentsOf: soundURL, byReference: true) else {
            NSSound.beep()
            playbackDuration = 1.2
            audioInterruptionManager.interruptForAlarmPlayback(duration: playbackDuration)
            return
        }

        playbackDuration = sound.duration > 0 ? sound.duration : 3.0
        audioInterruptionManager.interruptForAlarmPlayback(duration: playbackDuration)
        sound.play()
    }

    private func playAlertSoundWithCooldown(named soundFileName: String) {
        let now = Date()
        if let lastPlaybackAt = lastAlertSoundPlaybackAt,
           now.timeIntervalSince(lastPlaybackAt) < alertSoundCooldown {
            return
        }

        lastAlertSoundPlaybackAt = now
        playBundledSoundFallback(named: soundFileName)
    }

    func requestAuthorization() async -> String? {
        switch await ensureAuthorization() {
        case .authorized:
            return nil
        case .unavailable(let message):
            return message
        }
    }

    private func ensureAuthorization() async -> AuthorizationState {
        guard isBundleBackedApp else {
            let message = "התראות אינן זמינות בהרצה מ-Swift Package. יש להריץ מיעד .app אמיתי ב-Xcode."
            lastUnavailableMessage = message
            return .unavailable(message)
        }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            lastUnavailableMessage = nil
            return .authorized
        case .denied:
            let message = "התראות מושבתות עבור פיקוד אלרט בהגדרות המערכת."
            lastUnavailableMessage = message
            return .unavailable(message)
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    lastUnavailableMessage = nil
                    return .authorized
                }
                let message = "לא ניתנה הרשאה להתראות."
                lastUnavailableMessage = message
                return .unavailable(message)
            } catch {
                playBundledSoundFallback(named: AlertSoundCatalog.defaultSoundFileName())
                let message = "בקשת ההרשאה להתראות נכשלה: \(error.localizedDescription)"
                lastUnavailableMessage = message
                return .unavailable(message)
            }
        @unknown default:
            let message = "סטטוס הרשאת ההתראות אינו זמין."
            lastUnavailableMessage = message
            return .unavailable(message)
        }
    }

    func postNotification(for alert: AlertResponse, matchingCities: [String], soundEnabled: Bool, soundFileName: String) async -> Bool {
        switch await ensureAuthorization() {
        case .authorized:
            break
        case .unavailable:
            if soundEnabled {
                playAlertSoundWithCooldown(named: soundFileName)
            }
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.subtitle = alert.desc
        content.body = matchingCities.joined(separator: ", ")
        // Keep notification delivery reliable and play the selected bundled sound ourselves.
        // This avoids macOS falling back to the default sound when custom formats are unsupported.
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: alert.id,
            content: content,
            trigger: nil
        )

        let center = UNUserNotificationCenter.current()
        return await withCheckedContinuation { continuation in
            center.add(request) { error in
                if let error {
                    DispatchQueue.main.async {
                        self.lastUnavailableMessage = "שליחת ההתראה נכשלה: \(error.localizedDescription)"
                    }
                    if soundEnabled {
                        DispatchQueue.main.async {
                            self.playAlertSoundWithCooldown(named: soundFileName)
                        }
                    }
                    print("Notification scheduling failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                } else {
                    if soundEnabled {
                        DispatchQueue.main.async {
                            self.playAlertSoundWithCooldown(named: soundFileName)
                        }
                    }
                    continuation.resume(returning: true)
                }
            }
        }
    }
}

@MainActor
private final class AudioInterruptionManager {
    private struct PlayerSnapshot {
        let wasMusicPlaying: Bool
        let wasSpotifyPlaying: Bool
    }

    private var pendingResumeTask: Task<Void, Never>?
    private var didReportAutomationPermissionDenied = false

    func interruptForAlarmPlayback(duration: TimeInterval) {
        pendingResumeTask?.cancel()
        let snapshot = pauseKnownPlayersIfNeeded()
        guard snapshot.wasMusicPlaying || snapshot.wasSpotifyPlaying else { return }

        let resumeDelay = max(0.8, duration + 0.3)
        pendingResumeTask = Task { [snapshot] in
            try? await Task.sleep(for: .seconds(resumeDelay))
            guard !Task.isCancelled else { return }
            resumePlayers(from: snapshot)
        }
    }

    private func pauseKnownPlayersIfNeeded() -> PlayerSnapshot {
        let wasMusicPlaying = pauseMusicIfPlaying()
        let wasSpotifyPlaying = pauseSpotifyIfPlaying()
        return PlayerSnapshot(
            wasMusicPlaying: wasMusicPlaying,
            wasSpotifyPlaying: wasSpotifyPlaying
        )
    }

    private func pauseMusicIfPlaying() -> Bool {
        let script = """
        tell application "Music"
            if it is running then
                if player state is playing then
                    pause
                    return "playing"
                end if
            end if
        end tell
        return "not-playing"
        """

        return runAppleScript(script) == "playing"
    }

    private func pauseSpotifyIfPlaying() -> Bool {
        let script = """
        tell application "Spotify"
            if it is running then
                if player state is playing then
                    pause
                    return "playing"
                end if
            end if
        end tell
        return "not-playing"
        """

        return runAppleScript(script) == "playing"
    }

    private func resumePlayers(from snapshot: PlayerSnapshot) {
        if snapshot.wasMusicPlaying {
            _ = runAppleScript("""
            tell application "Music"
                if it is running then
                    play
                end if
            end tell
            """)
        }

        if snapshot.wasSpotifyPlaying {
            _ = runAppleScript("""
            tell application "Spotify"
                if it is running then
                    play
                end if
            end tell
            """)
        }
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else {
            return nil
        }

        var error: NSDictionary?
        let descriptor = script.executeAndReturnError(&error)
        if let error {
            let errorNumber = (error["NSAppleScriptErrorNumber"] as? NSNumber)?.intValue
            if errorNumber == -1743 {
                if !didReportAutomationPermissionDenied {
                    didReportAutomationPermissionDenied = true
                    print("AppleScript audio control unavailable: grant Automation permission in System Settings > Privacy & Security > Automation.")
                }
                return nil
            }
            print("AppleScript audio control failed with code \(errorNumber ?? 0).")
            return nil
        }

        let value = descriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }
}
