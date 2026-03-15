import Foundation

struct AlertSoundOption: Identifiable, Hashable {
    let fileName: String
    let displayName: String

    var id: String { fileName }
}

enum AlertSoundCatalog {
    static let soundsDirectoryName = "Sounds"
    private static let supportedExtensions: Set<String> = ["aif", "aiff", "caf", "m4a", "mp3", "wav"]
    private static let customSoundPrefix = "custom:"
    private static let customSoundExtension = "mp3"
    private static let preferredDefaultSoundFileName = "wow.mp3"

    enum ImportError: LocalizedError {
        case notMP3
        case couldNotAccessFile
        case couldNotPrepareStorage
        case copyFailed

        var errorDescription: String? {
            switch self {
            case .notMP3:
                return "אפשר להעלות רק קובץ MP3."
            case .couldNotAccessFile:
                return "לא ניתן לגשת לקובץ שנבחר."
            case .couldNotPrepareStorage:
                return "לא ניתן להכין תיקיית שמירת צלילים."
            case .copyFailed:
                return "העתקת קובץ הצליל נכשלה."
            }
        }
    }

    static func availableSounds(in bundle: Bundle = resourceBundle) -> [AlertSoundOption] {
        let soundsInDirectory = soundFileURLs(in: bundle.resourceURL?.appendingPathComponent(soundsDirectoryName, isDirectory: true))
        let customSounds = customSoundFileURLs()
        if !soundsInDirectory.isEmpty {
            return makeOptions(from: soundsInDirectory, isCustom: false) + makeOptions(from: customSounds, isCustom: true)
        }

        let rootSounds = soundFileURLs(in: bundle.resourceURL)
        return makeOptions(from: rootSounds, isCustom: false) + makeOptions(from: customSounds, isCustom: true)
    }

    @discardableResult
    static func importCustomMP3(from sourceURL: URL) throws -> AlertSoundOption {
        guard sourceURL.pathExtension.lowercased() == customSoundExtension else {
            throw ImportError.notMP3
        }

        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        if accessed == false, !FileManager.default.isReadableFile(atPath: sourceURL.path) {
            throw ImportError.couldNotAccessFile
        }

        guard let customDirectoryURL = customSoundsDirectoryURL(shouldCreate: true) else {
            throw ImportError.couldNotPrepareStorage
        }

        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let normalizedBaseName = normalizedFileBaseName(baseName)
        let destinationURL = customDirectoryURL.appendingPathComponent("\(normalizedBaseName).\(customSoundExtension)")

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw ImportError.copyFailed
        }

        return AlertSoundOption(
            fileName: customSoundPrefix + destinationURL.lastPathComponent,
            displayName: displayName(for: normalizedBaseName)
        )
    }

    private static func makeOptions(from resourceURLs: [URL], isCustom: Bool) -> [AlertSoundOption] {
        resourceURLs
            .map { url in
                AlertSoundOption(
                    fileName: (isCustom ? customSoundPrefix : "") + url.lastPathComponent,
                    displayName: displayName(for: url.deletingPathExtension().lastPathComponent)
                )
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    static func defaultSoundFileName(in bundle: Bundle = resourceBundle) -> String {
        let sounds = availableSounds(in: bundle)
        let availableFileNames = Set(sounds.map(\.fileName))
        if availableFileNames.contains(preferredDefaultSoundFileName) {
            return preferredDefaultSoundFileName
        }
        return sounds.first?.fileName ?? preferredDefaultSoundFileName
    }

    static func validatedSoundFileName(_ fileName: String?, in bundle: Bundle = resourceBundle) -> String {
        guard let fileName, !fileName.isEmpty else {
            return defaultSoundFileName(in: bundle)
        }

        let availableFileNames = Set(availableSounds(in: bundle).map(\.fileName))
        return availableFileNames.contains(fileName) ? fileName : defaultSoundFileName(in: bundle)
    }

    static func soundURL(for fileName: String, in bundle: Bundle = resourceBundle) -> URL? {
        if let customFileName = customFileName(fromStorageKey: fileName),
           let customDirectoryURL = customSoundsDirectoryURL(shouldCreate: false) {
            let customURL = customDirectoryURL.appendingPathComponent(customFileName)
            return FileManager.default.fileExists(atPath: customURL.path) ? customURL : nil
        }

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

    private static func customSoundFileURLs() -> [URL] {
        soundFileURLs(
            in: customSoundsDirectoryURL(shouldCreate: false),
            allowedExtensions: [customSoundExtension]
        )
    }

    private static func soundFileURLs(in directoryURL: URL?, allowedExtensions: Set<String>) -> [URL] {
        let fileManager = FileManager.default
        guard let directoryURL,
              let resourceURLs = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return resourceURLs.filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
    }

    private static func soundFileURLs(in directoryURL: URL?) -> [URL] {
        soundFileURLs(in: directoryURL, allowedExtensions: supportedExtensions)
    }

    private static func customSoundsDirectoryURL(shouldCreate: Bool) -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directory = appSupport.appendingPathComponent("MeowAlert", isDirectory: true)
            .appendingPathComponent("CustomSounds", isDirectory: true)
        if shouldCreate {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }
        return directory
    }

    private static func customFileName(fromStorageKey storageKey: String) -> String? {
        guard storageKey.hasPrefix(customSoundPrefix) else {
            return nil
        }

        let start = storageKey.index(storageKey.startIndex, offsetBy: customSoundPrefix.count)
        return String(storageKey[start...])
    }

    private static func normalizedFileBaseName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "custom-sound" : trimmed
    }
}
