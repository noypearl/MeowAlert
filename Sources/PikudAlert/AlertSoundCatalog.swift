import Foundation

struct AlertSoundOption: Identifiable, Hashable {
    let fileName: String
    let displayName: String

    var id: String { fileName }
}

enum AlertSoundCatalog {
    static let soundsDirectoryName = "Sounds"
    private static let supportedExtensions: Set<String> = ["aif", "aiff", "caf", "m4a", "mp3", "wav"]

    static func availableSounds(in bundle: Bundle = resourceBundle) -> [AlertSoundOption] {
        let soundsInDirectory = soundFileURLs(in: bundle.resourceURL?.appendingPathComponent(soundsDirectoryName, isDirectory: true))
        if !soundsInDirectory.isEmpty {
            return makeOptions(from: soundsInDirectory)
        }

        let rootSounds = soundFileURLs(in: bundle.resourceURL)
        return makeOptions(from: rootSounds)
    }

    private static func soundFileURLs(in directoryURL: URL?) -> [URL] {
        let fileManager = FileManager.default
        guard let directoryURL,
              let resourceURLs = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return resourceURLs.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
    }

    private static func makeOptions(from resourceURLs: [URL]) -> [AlertSoundOption] {
        resourceURLs
            .map { url in
                AlertSoundOption(
                    fileName: url.lastPathComponent,
                    displayName: displayName(for: url.deletingPathExtension().lastPathComponent)
                )
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    static func defaultSoundFileName(in bundle: Bundle = resourceBundle) -> String {
        availableSounds(in: bundle).first?.fileName ?? "fa.mp3"
    }

    static func validatedSoundFileName(_ fileName: String?, in bundle: Bundle = resourceBundle) -> String {
        guard let fileName, !fileName.isEmpty else {
            return defaultSoundFileName(in: bundle)
        }

        let availableFileNames = Set(availableSounds(in: bundle).map(\.fileName))
        return availableFileNames.contains(fileName) ? fileName : defaultSoundFileName(in: bundle)
    }

    static func soundURL(for fileName: String, in bundle: Bundle = resourceBundle) -> URL? {
        let soundName = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        let soundExtension = URL(fileURLWithPath: fileName).pathExtension

        return bundle.url(forResource: soundName, withExtension: soundExtension, subdirectory: soundsDirectoryName)
            ?? bundle.url(forResource: soundName, withExtension: soundExtension)
    }

    private static func displayName(for baseName: String) -> String {
        baseName
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { word in
                let lowercased = word.lowercased()
                return lowercased.prefix(1).uppercased() + lowercased.dropFirst()
            }
            .joined(separator: " ")
    }

    private static var resourceBundle: Bundle {
#if SWIFT_PACKAGE
        return .module
#else
        return .main
#endif
    }
}
