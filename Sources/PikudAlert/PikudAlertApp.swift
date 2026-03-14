import AppKit
import SwiftUI
import UserNotifications

@main
struct PikudAlertApp: App {
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
            return "paperplane.fill"
        case .error:
            return "paperplane.circle.fill"
        case .monitoring:
            return "paperplane"
        case .idle:
            return "paperplane"
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

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
