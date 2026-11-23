import Foundation

class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://www.imolaccio.it/sourcedrop/api/"
    
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
        let base64 = imageData.base64EncodedString()
        
        // Codifica correttamente per form-urlencoded (+ / = diventano %2B %2F %3D)
        let encodedBase64 = base64
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "=", with: "%3D")
        
        let url = URL(string: baseURL + "upload_photo.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "place_id=\(placeId)&photo_base64=\(encodedBase64)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log per debug
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("Risposta server: \(responseString)")
        }
        
        // Parsing robusto della risposta
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = json["error"] as? String {
                throw NSError(domain: "Upload", code: 2, userInfo: [NSLocalizedDescriptionKey: error])
            }
            if let url = json["url"] as? String, !url.isEmpty {
                return url
            }
            if let success = json["success"] as? Bool, success, let filename = json["filename"] as? String {
                // Fallback se manca l'url
                return "https://www.imolaccio.it/sourcedrop/uploads/\(filename)"
            }
        }
        
        // Se non è JSON valido, mostra il testo
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            throw NSError(domain: "Upload", code: 3, userInfo: [NSLocalizedDescriptionKey: "Errore server: \(text.prefix(300))"])
        }
        
        throw NSError(domain: "Upload", code: 4, userInfo: [NSLocalizedDescriptionKey: "Risposta vuota dal server"])
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
    
    func report(type: String, targetId: Int, reason: String, details: String = "") async throws {
        let url = URL(string: baseURL + "report.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "type": type,
            "target_id": targetId,
            "reason": reason,
            "details": details
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let text = String(data: data, encoding: .utf8), text.contains("error") {
            throw NSError(domain: "Report", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
        }
    }
}
