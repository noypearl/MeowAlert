import Foundation

@MainActor
final class CityCatalog: ObservableObject {
    @Published private(set) var cities: [String] = []
    private var searchableCities: [SearchableCity] = []

    init() {
        loadCities()
    }

    func suggestions(for query: String, excluding selectedCities: [String], limit: Int = 20) -> [String] {
        let selected = Set(selectedCities.map(Self.normalize))
        let normalizedQuery = Self.normalize(query)

        let filtered = searchableCities.filter { city in
            guard !selected.contains(city.normalizedValue) else { return false }
            if normalizedQuery.isEmpty { return true }
            return city.searchTokens.contains { $0.contains(normalizedQuery) }
        }

        return Array(filtered.map(\.value).prefix(limit))
    }

    func isKnownCity(_ city: String) -> Bool {
        let normalizedCity = Self.normalize(city)
        guard !normalizedCity.isEmpty else { return false }
        return searchableCities.contains { city in
            city.normalizedValue == normalizedCity || city.searchTokens.contains(normalizedCity)
        }
    }

    private func loadCities() {
        guard let url = resourceBundle.url(forResource: "cities", withExtension: "json") else {
            searchableCities = []
            cities = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedCities = try JSONDecoder().decode([CityEntry].self, from: data)
            searchableCities = Self.makeSearchableCities(from: decodedCities)
            cities = searchableCities.map(\.value)
        } catch {
            searchableCities = []
            cities = []
        }
    }

    private static func makeSearchableCities(from entries: [CityEntry]) -> [SearchableCity] {
        var seen = Set<String>()
        var result: [SearchableCity] = []

        for entry in entries {
            let value = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, value != "all" else { continue }

            let normalizedValue = normalize(value)
            guard !normalizedValue.isEmpty, !seen.contains(normalizedValue) else { continue }

            let rawTokens = [
                value,
                entry.name,
                entry.nameEn
            ]
            let normalizedTokens = Set(
                rawTokens
                    .compactMap { $0 }
                    .map(normalize)
                    .filter { !$0.isEmpty }
            )

            seen.insert(normalizedValue)
            result.append(
                SearchableCity(
                    value: value,
                    normalizedValue: normalizedValue,
                    searchTokens: normalizedTokens
                )
            )
        }

        return result
    }

    private var resourceBundle: Bundle {
#if SWIFT_PACKAGE
        return .module
#else
        return .main
#endif
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

private struct CityEntry: Decodable {
    let value: String
    let name: String?
    let nameEn: String?

    enum CodingKeys: String, CodingKey {
        case value
        case name
        case nameEn = "name_en"
    }
}

private struct SearchableCity {
    let value: String
    let normalizedValue: String
    let searchTokens: Set<String>
}
