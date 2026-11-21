import Foundation

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let isApproved: Bool
    let isSystem: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case isApproved = "is_approved"
        case isSystem = "is_system"
    }
}

struct WaterAnalysis: Codable, Identifiable {
    let id: Int
    let placeId: Int
    let ph: Double?
    let conductivity: Double?
    let nitrates: Double?
    let bacteria: String?
    let notes: String?
    let date: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case placeId = "place_id"
        case ph, conductivity, nitrates, bacteria, notes, date
    }
}

struct Place: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let history: String?
    let latitude: Double?
    let longitude: Double?
    let categoryId: Int?
    let categoryName: String?
    let createdAt: String?
    let analyses: [WaterAnalysis]?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, history, latitude, longitude
        case categoryId = "category_id"
        case categoryName = "category_name"
        case createdAt = "created_at"
        case analyses
        case imageUrl = "image_url"
    }
}
