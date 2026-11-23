import Foundation

struct Category: Identifiable, Codable {
    let id: Int
    let name: String
    let icon: String?
    
    var iconName: String {
        icon ?? "mappin"
    }
}

struct Place: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let history: String?
    let latitude: Double?
    let longitude: Double?
    let categoryId: Int?
    let imageUrl: String?
    var photos: [String] = []
    var analyses: [WaterAnalysis] = []
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, history, latitude, longitude
        case categoryId = "category_id"
        case imageUrl = "image_url"
        case photos, analyses
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        history = try container.decodeIfPresent(String.self, forKey: .history)
        categoryId = try container.decodeIfPresent(Int.self, forKey: .categoryId)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        
        if let latString = try? container.decode(String.self, forKey: .latitude) {
            latitude = Double(latString)
        } else {
            latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        }
        
        if let lonString = try? container.decode(String.self, forKey: .longitude) {
            longitude = Double(lonString)
        } else {
            longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        }
        
        photos = (try? container.decode([String].self, forKey: .photos)) ?? []
        analyses = (try? container.decode([WaterAnalysis].self, forKey: .analyses)) ?? []
    }
    
    var allPhotos: [String] {
        var result: [String] = []
        if let imageUrl, !imageUrl.isEmpty {
            result.append(imageUrl)
        }
        result.append(contentsOf: photos.filter { !$0.isEmpty })
        return result
    }
    
    var thumbnailUrl: String? {
        allPhotos.first
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
