import AppKit
import SwiftUI
import UserNotifications

@main
struct MeowAlert: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings: SettingsStore
    @StateObject private var monitor: AlertMonitor

    init() {
        let settings = SettingsStore()
        _settings = StateObject(wrappedValue: settings)
        _monitor = StateObject(wrappedValue: AlertMonitor(settings: settings))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(monitor: monitor, settings: settings)
                .environment(\.layoutDirection, .rightToLeft)
                .onAppear {
                    monitor.start()
                }
        } label: {
            Label {
                Text("האפליקציה")
            } icon: {
                menuBarLabelIcon
            }
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarIcon: String {
        switch monitor.status {
        case .alert:
            return "light.beacon.max.fill"
        case .error:
            return "light.beacon.max.fill"
        case .monitoring:
            return "light.beacon.max.fill"
        case .idle:
            return "light.beacon.max.fill"
        }
    }

    private var menuBarLabelIcon: Image {
        if let customIcon = loadMenuBarIcon() {
            return Image(nsImage: customIcon).renderingMode(.original)
        }
        return Image(systemName: menuBarIcon)
    }

    private func loadMenuBarIcon() -> NSImage? {
        if let image = NSImage(named: "menu-bar-icon") {
            return image
        }
        guard let iconURL = Bundle.main.url(forResource: "menu-bar-icon", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: iconURL)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        applyNotificationIcon()
#if DEBUG
        let info = Bundle.main.infoDictionary ?? [:]
        let iconName = info["CFBundleIconName"] as? String ?? "<missing>"
        let bundleURL = Bundle.main.bundleURL.path
        print("Icon debug: bundle=\(bundleURL), CFBundleIconName=\(iconName), hasApplicationIcon=\(NSImage(named: NSImage.applicationIconName) != nil)")
#endif
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    private func applyNotificationIcon() {
        if let icon = NSImage(named: NSImage.applicationIconName) {
            NSApp.applicationIconImage = icon
            return
        }

        if let icon = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = icon
            return
        }

        guard let iconURL = Bundle.main.url(forResource: "new_icon", withExtension: "png"),
              let icon = NSImage(contentsOf: iconURL) else {
            return
        }
        NSApp.applicationIconImage = icon
    }
}
