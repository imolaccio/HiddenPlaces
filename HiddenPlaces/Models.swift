import Foundation

struct Category: Identifiable, Codable {
    let id: Int
    let name: String
}

struct Place: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let history: String?
    let latitude: Double?
    let longitude: Double?
    let categoryId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, history, latitude, longitude
        case categoryId = "category_id"
    }
}
