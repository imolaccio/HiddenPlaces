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
    var analyses: [WaterAnalysis] = []
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, history, latitude, longitude
        case categoryId = "category_id"
        case analyses
    }
}

struct WaterAnalysis: Identifiable, Codable {
    let id: Int
    let sourceId: Int
    let date: String?
    let ph: Double?
    let conductivity: Double?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sourceId = "source_id"
        case date, ph, conductivity, notes
    }
}

struct PhotoItem: Codable {
    let url: String
}
