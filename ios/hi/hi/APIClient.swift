import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://app.havingfunwith.ai"
    
    private init() {}
    
    struct GenerateRequest: Codable {
        let prompt: String
        let session_id: String  // UUID for this keyboard session
        let request_id: String  // UUID for this specific request
    }
    
    struct GenerateResponse: Codable {
        let signedUrls: [String]  // 4 signed URLs for images
    }
    
    // Generate new session ID (call when keyboard loads)
    func newSessionID() -> String {
        return UUID().uuidString
    }
    
    // Generate new request ID (call for each generate request)
    func newRequestID() -> String {
        return UUID().uuidString
    }
    
    // Call /api/generate endpoint
    func generate(prompt: String, sessionID: String, requestID: String, accessToken: String) async throws -> GenerateResponse {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body = GenerateRequest(
            prompt: prompt,
            session_id: sessionID,
            request_id: requestID
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(GenerateResponse.self, from: data)
        return result
    }

    
    enum APIError: LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let code):
                return "Server error: \(code)"
            }
        }
    }
}
