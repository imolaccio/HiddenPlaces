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
    
    func createPlace(name: String, description: String, history: String, categoryId: Int, latitude: Double?, longitude: Double?) async throws {
        let url = URL(string: baseURL + "sources.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": name,
            "description": description,
            "history": history,
            "category_id": categoryId,
            "latitude": latitude as Any,
            "longitude": longitude as Any
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func report(type: String, targetId: Int, reason: String, details: String) async throws {
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
        _ = try await URLSession.shared.data(for: request)
    }
}
