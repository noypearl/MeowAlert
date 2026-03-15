import Foundation

enum AlertMatcher {
    static func matchingCities(in alertCities: [String], watchedCities: [String]) -> [String] {
        let normalizedWatched = watchedCities
            .map(normalize)
            .filter { !$0.isEmpty }

        guard !normalizedWatched.isEmpty else { return [] }

        return alertCities.filter { alertCity in
            let normalizedAlert = normalize(alertCity)
            guard !normalizedAlert.isEmpty else { return false }

            return normalizedWatched.contains(where: { watched in
                normalizedAlert == watched ||
                normalizedAlert.contains(watched) ||
                watched.contains(normalizedAlert)
            })
        }
    }

    private static func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
