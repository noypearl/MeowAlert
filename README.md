# Pikud Alert

Native macOS menu bar app that polls the Oref alert API every 4 seconds and raises a local macOS notification when one of your watched cities appears in the `data` array.

## What is included

- SwiftUI menu bar app for macOS 13+
- Oref API polling client
- Matching against watched cities
- Duplicate alert suppression by alert `id`
- Local notifications and optional sound
- Main panel city manager with autocomplete and polling interval

## Project structure

- `Package.swift` defines a Swift package executable target that can be opened directly in Xcode.
- `Sources/PikudAlert/` contains the app, monitor, API client, notification manager, and main panel UI.

## Run locally

1. Open the package in Xcode:
   - `open Package.swift`
2. Run the `PikudAlert` scheme.
3. Grant notification permission when macOS prompts you.
4. Add your watched cities in the main menu panel.
   - Open `Manage` in the `Watched Areas` card, then use search and suggestions.

If `xcodebuild` still points to Command Line Tools, switch it once:

`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## Run as real .app target (recommended for system notifications)

1. Generate the Xcode app project:
   - `xcodegen generate`
2. Open the generated project:
   - `open PikudAlertApp.xcodeproj`
3. Select scheme `PikudAlertApp` and run on `My Mac`.

This mode runs as a real macOS app bundle, so `UNUserNotificationCenter` banners work correctly.

## Notes

- The app starts monitoring immediately.
- Polling defaults to 4 seconds and can be increased in the main menu panel.
- City matching is tolerant to minor naming differences (exact or partial normalized match).
- Use `Send Test Notification` from the menu bar window to verify notification delivery and sound settings manually.
- The endpoint behavior can change. If the API needs extra headers or anti-bot handling later, adjust `OrefAPIClient.swift`.
- For a production-quality distributable `.app`, the next step is creating an Xcode app target with an `Info.plist`, app icon, signing, and launch-at-login support.
