import Foundation

@MainActor
final class AlertMonitor: ObservableObject {
    enum Status: String {
        case idle = "לא פעיל"
        case monitoring = "ניטור פעיל"
        case alert = "התראה"
        case error = "שגיאת חיבור"
    }

    enum StatusMessageKind {
        case alert
        case error
        case warning
        case info
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var activeAlert: AlertResponse?
    @Published private(set) var matchingCities: [String] = []
    @Published private(set) var lastPollAt: Date?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var notificationWarning: String?
    @Published private(set) var lastActionMessage: String?
    @Published var isMonitoring = false

    private let settings: SettingsStore
    private let client: OrefAPIClient
    private let notifications: NotificationManager
    private var monitoringTask: Task<Void, Never>?
    private var lastHandledAlertID: String?

    init(
        settings: SettingsStore,
        client: OrefAPIClient = OrefAPIClient(),
        notifications: NotificationManager = NotificationManager()
    ) {
        self.settings = settings
        self.client = client
        self.notifications = notifications
    }

    var statusMessage: String? {
        if activeAlert != nil, !matchingCities.isEmpty {
            return "היכנסו למרחב מוגן עכשיו. אזורים תואמים: \(matchingCities.joined(separator: ", "))"
        }

        if let lastErrorMessage, !lastErrorMessage.isEmpty {
            return lastErrorMessage
        }

        if let notificationWarning, !notificationWarning.isEmpty {
            return notificationWarning
        }

        if let lastActionMessage, !lastActionMessage.isEmpty {
            return lastActionMessage
        }

        return nil
    }

    var statusMessageKind: StatusMessageKind? {
        if activeAlert != nil, !matchingCities.isEmpty {
            return .alert
        }

        if let lastErrorMessage, !lastErrorMessage.isEmpty {
            return .error
        }

        if let notificationWarning, !notificationWarning.isEmpty {
            return .warning
        }

        if let lastActionMessage, !lastActionMessage.isEmpty {
            return .info
        }

        return nil
    }

    func start() {
        guard monitoringTask == nil else { return }
        isMonitoring = true
        status = .monitoring

        monitoringTask = Task { [weak self] in
            guard let self else { return }
            self.notificationWarning = await self.notifications.requestAuthorization()

            while !Task.isCancelled {
                await self.pollOnce()
                let pollingDelay = max(2, self.settings.pollingIntervalSeconds)
                try? await Task.sleep(for: .seconds(pollingDelay))
            }
        }
    }

    func stop() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        activeAlert = nil
        matchingCities = []
        lastErrorMessage = nil
        notificationWarning = nil
        lastActionMessage = nil
        status = .idle
    }

    func toggleMonitoring() {
        isMonitoring ? stop() : start()
    }

    func sendTestNotification() async {
        let testCity = settings.watchedCities.randomElement() ?? "תל אביב - מזרח"
        let alert = AlertResponse(
            id: "test-\(UUID().uuidString)",
            cat: "1",
            title: "ירי רקטות וטילים",
            data: [testCity],
            desc: "היכנסו למרחב המוגן"
        )
        let matchingCities = alert.data

        let posted = await notifications.postNotification(
            for: alert,
            matchingCities: matchingCities,
            soundEnabled: settings.soundEnabled,
            soundFileName: settings.selectedAlertSoundFileName
        )

        if posted {
            notificationWarning = nil
            lastActionMessage = "התראת בדיקה נשלחה בשעה \(Date.now.formatted(date: .omitted, time: .standard))."
        } else {
            notificationWarning = notifications.lastUnavailableMessage ?? "התראות מערכת אינן זמינות כרגע. הופעל צליל גיבוי."
            lastActionMessage = "התראת בדיקה הופעלה (גיבוי) בשעה \(Date.now.formatted(date: .omitted, time: .standard))."
        }
    }

    func pollOnce() async {
        do {
            let response = try await client.fetchAlert()
            lastPollAt = .now
            lastErrorMessage = nil

            guard let response else {
                activeAlert = nil
                matchingCities = []
                status = isMonitoring ? .monitoring : .idle
                return
            }

            let matches = AlertMatcher.matchingCities(
                in: response.data,
                watchedCities: settings.watchedCities
            )

            if matches.isEmpty {
                activeAlert = nil
                matchingCities = []
                status = isMonitoring ? .monitoring : .idle
                return
            }

            activeAlert = response
            matchingCities = matches
            status = .alert

            if response.id != lastHandledAlertID {
                lastHandledAlertID = response.id
                let posted = await notifications.postNotification(
                    for: response,
                    matchingCities: matches,
                    soundEnabled: settings.soundEnabled,
                    soundFileName: settings.selectedAlertSoundFileName
                )
                if posted {
                    notificationWarning = nil
                } else {
                    notificationWarning = notifications.lastUnavailableMessage ?? "התראות מערכת אינן זמינות כרגע. הופעל צליל גיבוי."
                }
            }
        } catch {
            lastPollAt = .now
            lastErrorMessage = error.localizedDescription
            status = .error
        }
    }

}
