import Foundation

struct OrefAPIClient: Sendable {
    private let session: URLSession
    private let endpoint = URL(string: "https://www.oref.org.il/warningMessages/alert/alerts.json")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchAlert() async throws -> AlertResponse? {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("https://www.oref.org.il/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OrefAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw OrefAPIError.httpStatus(httpResponse.statusCode)
        }

        if data.isEmpty {
            return nil
        }

        let cleanedData = Self.cleanedPayload(from: data)
        if cleanedData.isEmpty || cleanedData == Data("[]".utf8) || cleanedData == Data("{}".utf8) {
            return nil
        }

        return try Self.decodeAlert(from: cleanedData)
    }

    private static func decodeAlert(from data: Data) throws -> AlertResponse? {
        let decoder = JSONDecoder()

        if let direct = try? decoder.decode(AlertResponse.self, from: data) {
            return direct.data.isEmpty ? nil : direct
        }

        if let array = try? decoder.decode([AlertResponse].self, from: data), let first = array.first {
            return first.data.isEmpty ? nil : first
        }

        if let raw = try? decoder.decode(RawAlertPayload.self, from: data) {
            return raw.asAlertResponse
        }

        if let rawArray = try? decoder.decode([RawAlertPayload].self, from: data), let first = rawArray.first {
            return first.asAlertResponse
        }

        // Some responses are wrapped as a JSON string containing JSON content.
        if
            let wrapped = try? decoder.decode(String.self, from: data),
            let nestedData = wrapped.data(using: .utf8)
        {
            let nestedCleaned = cleanedPayload(from: nestedData)
            if nestedCleaned != data {
                return try decodeAlert(from: nestedCleaned)
            }
        }

        throw OrefAPIError.decodingPreview(preview(from: data))
    }

    private static func cleanedPayload(from rawData: Data) -> Data {
        let withoutBOM = rawData.dropUTF8BOMIfNeeded()
        let trimmed = Data(withoutBOM.drop(while: { $0.isWhitespaceByte }))
        guard !trimmed.isEmpty else { return trimmed }

        // Keep only the outermost JSON object/array if the API prepends wrapper bytes.
        if let start = trimmed.firstIndex(where: { $0 == UInt8(ascii: "{") || $0 == UInt8(ascii: "[") }),
           let end = trimmed.lastIndex(where: { $0 == UInt8(ascii: "}") || $0 == UInt8(ascii: "]") }),
           start <= end
        {
            return trimmed[start...end]
        }

        return trimmed
    }

    private static func preview(from data: Data) -> String {
        let text = String(decoding: data, as: UTF8.self)
        return text.prefix(160).replacingOccurrences(of: "\n", with: " ")
    }
}

enum OrefAPIError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case decodingPreview(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "ממשק ההתראות החזיר תגובה לא תקינה."
        case .httpStatus(let statusCode):
            return "ממשק ההתראות החזיר HTTP \(statusCode)."
        case .decodingPreview(let preview):
            return "לא ניתן לפענח את תגובת ממשק ההתראות. תצוגה מקדימה של המטען: \(preview)"
        }
    }
}

private extension UInt8 {
    var isWhitespaceByte: Bool {
        self == 0x20 || self == 0x0A || self == 0x0D || self == 0x09
    }
}

private extension Data {
    func dropUTF8BOMIfNeeded() -> Data {
        guard count >= 3 else { return self }
        let bytes = [self[startIndex], self[index(after: startIndex)], self[index(startIndex, offsetBy: 2)]]
        if bytes == [0xEF, 0xBB, 0xBF] {
            return self.dropFirst(3)
        }
        return self
    }
}

private struct RawAlertPayload: Decodable {
    let id: String?
    let cat: String?
    let title: String?
    let desc: String?
    let alertDate: String?
    let data: RawCities

    enum CodingKeys: String, CodingKey {
        case id
        case cat
        case title
        case desc
        case alertDate
        case data
    }

    var asAlertResponse: AlertResponse? {
        let cities = data.cities
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cities.isEmpty else { return nil }

        let safeTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeDesc = desc?.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeCat = cat?.trimmingCharacters(in: .whitespacesAndNewlines)
        let stableID = id?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? alertDate?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? [safeTitle ?? "", safeDesc ?? "", cities.joined(separator: "|")].joined(separator: "#")

        return AlertResponse(
            id: stableID,
            cat: safeCat?.isEmpty == false ? safeCat! : "1",
            title: safeTitle?.isEmpty == false ? safeTitle! : "צבע אדום",
            data: cities,
            desc: safeDesc?.isEmpty == false ? safeDesc! : ""
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexibleString(forKey: .id)
        cat = container.decodeFlexibleString(forKey: .cat)
        title = container.decodeFlexibleString(forKey: .title)
        desc = container.decodeFlexibleString(forKey: .desc)
        alertDate = container.decodeFlexibleString(forKey: .alertDate)
        data = (try? container.decode(RawCities.self, forKey: .data)) ?? .none
    }
}

private enum RawCities: Decodable {
    case array([String])
    case single(String)
    case none

    var cities: [String] {
        switch self {
        case .array(let values):
            return values
        case .single(let value):
            return value.isEmpty ? [] : [value]
        case .none:
            return []
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let values = try? container.decode([String].self) {
            self = .array(values)
        } else if let value = try? container.decode(String.self) {
            self = .single(value)
        } else {
            self = .none
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) -> String? {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }
        if let doubleValue = try? decode(Double.self, forKey: key) {
            return String(doubleValue)
        }
        return nil
    }
}
