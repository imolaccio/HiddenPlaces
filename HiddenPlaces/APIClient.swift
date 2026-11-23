import Foundation

class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://imolaccio.it/sourcedrop/api/"
    
    func fetchCategories() async throws -> [Category] {
        let url = URL(string: baseURL + "categories.php")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Category].self, from: data)
    }
    
    func fetchPlaces(categoryId: Int? = nil) async throws -> [Place] {
        var components = URLComponents(string: baseURL + "places_with_ads.php")!
        if let categoryId {
            components.queryItems = [URLQueryItem(name: "category_id", value: "\(categoryId)")]
        }
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([Place].self, from: data)
    }
    
    func fetchPhotos() async throws -> [PhotoItem] {
        let url = URL(string: baseURL + "photos.php")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([PhotoItem].self, from: data)
    }
    
    func addPlace(name: String, description: String, history: String?, categoryId: Int, latitude: Double, longitude: Double) async throws -> Int {
        let url = URL(string: baseURL + "add_place.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "description": description,
            "history": history ?? "",
            "category_id": categoryId,
            "latitude": latitude,
            "longitude": longitude
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode([String: Int].self, from: data)
        return result["id"] ?? 0
    }
    
    func uploadPhoto(placeId: Int, imageData: Data) async throws -> String {
        let url = URL(string: baseURL + "upload_photo.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"place_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(placeId)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let result = try? JSONDecoder().decode([String: String].self, from: data) {
            return result["url"] ?? ""
        }
        return ""
    }
    
    func requestCategory(name: String, reason: String) async throws {
        let url = URL(string: baseURL + "request_category.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["name": name, "reason": reason]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    func fetchPlacePhotos(placeId: Int) async throws -> [PlacePhoto] {
        let url = URL(string: baseURL + "place_photos.php?place_id=\(placeId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([PlacePhoto].self, from: data)
    }
    
    func sendMessage(placeId: Int, message: String) async throws {
        let url = URL(string: baseURL + "send_message.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["place_id": placeId, "message": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}
