import Foundation

struct AlertResponse: Decodable, Equatable, Sendable {
    let id: String
    let cat: String
    let title: String
    let data: [String]
    let desc: String
}

extension AlertResponse {
    var matchingAreaSummary: String {
        data.joined(separator: ", ")
    }
}
