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
    
    // ADD these new structs after GenerateResponse:
    struct AutocompleteRequest: Codable {
        let prompt: String
    }

    struct AutocompleteResponse: Codable {
        let completion: String
        let duration: Double
    }
    
    // Generate new session ID (call when keyboard loads)
    func newSessionID() -> String {
        return UUID().uuidString
    }
    
    // Generate new request ID (call for each generate request)
    func newRequestID() -> String {
        return UUID().uuidString
    }

    // MARK: - Public API Methods
    
    func warmup() async throws {
        guard let url = URL(string: "\(baseURL)/api/warmup") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Warming up...")
        _ = try await URLSession.shared.data(for: request)
    }

    func generate(prompt: String, sessionID: String, requestID: String) async throws -> GenerateResponse {
        let accessToken = try await getValidAccessToken()
        
        do {
            return try await performGenerate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                accessToken: accessToken
            )
        } catch APIError.httpError(statusCode: 401) {
            // Token expired during request - refresh and retry once
            let newToken = try await getValidAccessToken()
            return try await performGenerate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                accessToken: newToken
            )
        }
    }
    
    // Call /api/generate endpoint
    private func performGenerate(prompt: String, sessionID: String, requestID: String, accessToken: String) async throws -> GenerateResponse {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw APIError.invalidURL
        }
        
        if baseURL.hasPrefix("https://") {
            try? await Task.sleep(nanoseconds: 1_250_000_000)
            return GenerateResponse(signedUrls: [
                "***REMOVED***",
                "***REMOVED***",
                "***REMOVED***",
                "***REMOVED***"
            ])
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

    func autocomplete(prompt: String) async throws -> AutocompleteResponse {
        let accessToken = try await getValidAccessToken()
        
        do {
            return try await performAutocomplete(prompt: prompt, accessToken: accessToken)
        } catch APIError.httpError(statusCode: 401) {
            // Token expired during request - refresh and retry once
            let newToken = try await getValidAccessToken()
            return try await performAutocomplete(prompt: prompt, accessToken: newToken)
        }
    }

    private func performAutocomplete(prompt: String, accessToken: String) async throws -> AutocompleteResponse {
        guard let url = URL(string: "\(baseURL)/api/autocomplete") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body = AutocompleteRequest(prompt: prompt)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(AutocompleteResponse.self, from: data)
        return result
    }

    // MARK: - Token Management
    
    private func getValidAccessToken() async throws -> String {
        guard let token = await AuthManager.shared.getAccessToken() else {
            throw APIError.notAuthenticated
        }
        
        return token
    }
        
    // MARK: - Error Types
    
    enum APIError: LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int)
        case notAuthenticated
        case sessionExpired
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let code):
                return "Server error: \(code)"
            case .notAuthenticated:
                return "Please login in the hi app first"
            case .sessionExpired:
                return "Session expired. Please login again in the hi app"
            }
        }
    }
}
