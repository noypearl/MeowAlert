import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var watchedCities: [String] {
        didSet {
            UserDefaults.standard.set(watchedCities, forKey: Self.watchedCitiesKey)
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Self.soundEnabledKey)
        }
    }

    @Published var selectedAlertSoundFileName: String {
        didSet {
            let validated = AlertSoundCatalog.validatedSoundFileName(selectedAlertSoundFileName)
            if validated != selectedAlertSoundFileName {
                selectedAlertSoundFileName = validated
                return
            }

            UserDefaults.standard.set(validated, forKey: Self.selectedAlertSoundKey)
        }
    }

    @Published var pollingIntervalSeconds: Double {
        didSet {
            let validated = Self.validatedPollingInterval(pollingIntervalSeconds)
            if validated != pollingIntervalSeconds {
                pollingIntervalSeconds = validated
                return
            }

            UserDefaults.standard.set(validated, forKey: Self.pollingIntervalSecondsKey)
        }
    }

    static let watchedCitiesKey = "watchedCities"
    static let legacyWatchedCitiesTextKey = "watchedCitiesText"
    static let soundEnabledKey = "soundEnabled"
    static let selectedAlertSoundKey = "selectedAlertSoundFileName"
    static let pollingIntervalSecondsKey = "pollingIntervalSeconds"

    init() {
        let defaults = UserDefaults.standard
        if let storedCities = defaults.stringArray(forKey: Self.watchedCitiesKey), !storedCities.isEmpty {
            self.watchedCities = Self.deduped(storedCities)
        } else if let legacyText = defaults.string(forKey: Self.legacyWatchedCitiesTextKey), !legacyText.isEmpty {
            self.watchedCities = Self.parseCities(from: legacyText)
        } else {
            self.watchedCities = ["תל אביב - מזרח"]
        }
        self.soundEnabled = defaults.object(forKey: Self.soundEnabledKey) as? Bool ?? true
        let storedSoundFileName = defaults.string(forKey: Self.selectedAlertSoundKey)
        self.selectedAlertSoundFileName = AlertSoundCatalog.validatedSoundFileName(storedSoundFileName)
        let storedPollingInterval = defaults.object(forKey: Self.pollingIntervalSecondsKey) as? Double
        self.pollingIntervalSeconds = Self.validatedPollingInterval(storedPollingInterval ?? 2)
    }

    func addCity(_ city: String) {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalized = Self.normalize(trimmed)
        guard !watchedCities.contains(where: { Self.normalize($0) == normalized }) else { return }
        watchedCities.append(trimmed)
    }

    func removeCity(_ city: String) {
        let normalized = Self.normalize(city)
        watchedCities.removeAll { Self.normalize($0) == normalized }
    }

    private static func parseCities(from text: String) -> [String] {
        let values = text
            .split(whereSeparator: \.isNewline)
            .flatMap { line in
                line.split(separator: ",")
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return deduped(values)
    }

    private static func deduped(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values {
            let normalized = normalize(value)
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            seen.insert(normalized)
            result.append(value)
        }
        return result
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private static func validatedPollingInterval(_ value: Double) -> Double {
        let clamped = min(max(value, 2), 20)
        return clamped.rounded()
    }
}
