import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://app.hi-key.ai"
    
    private init() {}
    
    struct GenerateRequest: Codable {
        let prompt: String
        let session_id: String  // UUID for this keyboard session
        let request_id: String  // UUID for this specific request
        let random_styles: [String]  // Random styles from user preferences; empty when disabled
    }
    
    struct GenerateImageEntry: Codable {
        let id: String
        let signedUrl: String
    }

    struct CreditsBalance: Codable {
        let sub_credits: Int
        let extra_credits: Int
    }

    struct GenerateResponse: Codable {
        let images: [GenerateImageEntry]
        let balance: CreditsBalance?
    }

    enum GenerationStatusValue: String, Codable {
        case initializing
        case generating
        case ready
        case error

        // Treat unknown statuses as still-in-progress so a backend addition
        // never causes us to drop a placeholder or claim a refund prematurely.
        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = GenerationStatusValue(rawValue: raw) ?? .generating
        }
    }

    struct GenerationStatusEntry: Codable {
        let id: String
        let status: GenerationStatusValue
    }

    struct GenerationStatusRequest: Codable {
        let ids: [String]
    }

    struct GenerationStatusResponse: Codable {
        let generations: [GenerationStatusEntry]
    }

    struct ProfileDTO: Codable {
        let name: String?
        let referral_code: String?
    }

    struct MeResponse: Codable {
        let credits: CreditsBalance
        let profile: ProfileDTO?
        let referred_by: String?
        let double_credits: Bool?
        let active_sub_product_id: String?
    }

    struct InsufficientCreditsPayload: Codable {
        let error: String
        let balance: CreditsBalance
    }

    struct ReferralCodeResponse: Codable {
        let name: String
        let code: String
    }

    struct ReferralRedeemResponse: Codable {
        let credits: CreditsBalance
        /// True until this user starts a trial or buys credits, which pays the
        /// bonus to both sides. Optional for backends that predate the field.
        let bonus_pending: Bool?
    }

    private struct ReferralErrorPayload: Codable {
        let error: String?
        let credits: CreditsBalance?
    }

    struct ClaimCodeResponse: Codable {
        let credits: CreditsBalance
    }
    
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

    func generate(prompt: String, sessionID: String, requestID: String, randomStyles: [String]) async throws -> GenerateResponse {
        let accessToken = try await getValidAccessToken()

        do {
            return try await performGenerate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                randomStyles: randomStyles,
                accessToken: accessToken
            )
        } catch APIError.httpError(statusCode: 401) {
            // Token expired during request - refresh and retry once
            let newToken = try await getValidAccessToken()
            return try await performGenerate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                randomStyles: randomStyles,
                accessToken: newToken
            )
        }
    }

    // Call /api/generate endpoint
    private func performGenerate(prompt: String, sessionID: String, requestID: String, randomStyles: [String], accessToken: String) async throws -> GenerateResponse {
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
            request_id: requestID,
            random_styles: randomStyles
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 402 {
            let payload = try? JSONDecoder().decode(InsufficientCreditsPayload.self, from: data)
            throw APIError.insufficientCredits(balance: payload?.balance)
        }

        if httpResponse.statusCode == 403 {
            throw APIError.promptFlagged
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(GenerateResponse.self, from: data)
        return result
    }

    // MARK: - Generation Status

    func generationStatuses(ids: [String]) async throws -> [GenerationStatusEntry] {
        let accessToken = try await getValidAccessToken()

        do {
            return try await performGenerationStatuses(ids: ids, accessToken: accessToken)
        } catch APIError.httpError(statusCode: 401) {
            let newToken = try await getValidAccessToken()
            return try await performGenerationStatuses(ids: ids, accessToken: newToken)
        }
    }

    private func performGenerationStatuses(ids: [String], accessToken: String) async throws -> [GenerationStatusEntry] {
        guard let url = URL(string: "\(baseURL)/api/generations") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body = GenerationStatusRequest(ids: ids)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(GenerationStatusResponse.self, from: data)
        return result.generations
    }

    // MARK: - Credits

    func me() async throws -> MeResponse {
        let accessToken = try await getValidAccessToken()
        do {
            return try await performMe(accessToken: accessToken)
        } catch APIError.httpError(statusCode: 401) {
            let newToken = try await getValidAccessToken()
            return try await performMe(accessToken: newToken)
        }
    }

    private func performMe(accessToken: String) async throws -> MeResponse {
        guard let url = URL(string: "\(baseURL)/api/me") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(MeResponse.self, from: data)
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

    // MARK: - Copy Tracking

    struct CopyRequest: Codable {
        let generationId: String
    }

    func reportCopy(generationId: String) async throws {
        let accessToken = try await getValidAccessToken()

        guard let url = URL(string: "\(baseURL)/api/copy") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body = CopyRequest(generationId: generationId)
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Referrals

    struct ReferralCodeRequest: Codable {
        let name: String
    }

    struct ReferralRedeemRequest: Codable {
        let code: String
    }

    func createReferralCode(name: String) async throws -> ReferralCodeResponse {
        let accessToken = try await getValidAccessToken()
        do {
            return try await performCreateReferralCode(name: name, accessToken: accessToken)
        } catch APIError.httpError(statusCode: 401) {
            let newToken = try await getValidAccessToken()
            return try await performCreateReferralCode(name: name, accessToken: newToken)
        }
    }

    private func performCreateReferralCode(name: String, accessToken: String) async throws -> ReferralCodeResponse {
        guard let url = URL(string: "\(baseURL)/api/referral") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(ReferralCodeRequest(name: name))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(ReferralCodeResponse.self, from: data)
        }

        let payload = try? JSONDecoder().decode(ReferralErrorPayload.self, from: data)
        switch (httpResponse.statusCode, payload?.error) {
        case (400, "invalid_name"):
            throw APIError.invalidReferralName
        case (403, _):
            throw APIError.referralBypassUser
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    func redeemReferralCode(code: String) async throws -> ReferralRedeemResponse {
        let accessToken = try await getValidAccessToken()
        do {
            return try await performRedeemReferralCode(code: code, accessToken: accessToken)
        } catch APIError.httpError(statusCode: 401) {
            let newToken = try await getValidAccessToken()
            return try await performRedeemReferralCode(code: code, accessToken: newToken)
        }
    }

    private func performRedeemReferralCode(code: String, accessToken: String) async throws -> ReferralRedeemResponse {
        guard let url = URL(string: "\(baseURL)/api/referral/redeem") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(ReferralRedeemRequest(code: code))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(ReferralRedeemResponse.self, from: data)
        }

        let payload = try? JSONDecoder().decode(ReferralErrorPayload.self, from: data)
        switch (httpResponse.statusCode, payload?.error) {
        case (400, "invalid_code"):
            throw APIError.invalidReferralCode
        case (400, "self_referral"):
            throw APIError.selfReferral
        case (404, "code_not_found"):
            throw APIError.referralCodeNotFound
        case (409, "already_redeemed"):
            throw APIError.referralAlreadyRedeemed(balance: payload?.credits)
        case (403, _):
            throw APIError.referralBypassUser
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Waitlist Claim Code

    struct ClaimCodeRequest: Codable {
        let code: String
    }

    func claimWaitlistCode(code: String) async throws -> CreditsBalance {
        let accessToken = try await getValidAccessToken()
        do {
            return try await performClaimWaitlistCode(code: code, accessToken: accessToken)
        } catch APIError.httpError(statusCode: 401) {
            let newToken = try await getValidAccessToken()
            return try await performClaimWaitlistCode(code: code, accessToken: newToken)
        }
    }

    private func performClaimWaitlistCode(code: String, accessToken: String) async throws -> CreditsBalance {
        guard let url = URL(string: "\(baseURL)/api/me/claim-code") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(ClaimCodeRequest(code: code))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            let decoded = try JSONDecoder().decode(ClaimCodeResponse.self, from: data)
            return decoded.credits
        }

        // 400 invalid_code, 404 code_not_found, 409 already_claimed, 409 already_doubled
        // all collapse to a single user-facing "invalid code" message.
        if [400, 404, 409].contains(httpResponse.statusCode) {
            throw APIError.invalidClaimCode
        }

        throw APIError.httpError(statusCode: httpResponse.statusCode)
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
        case insufficientCredits(balance: CreditsBalance?)
        case promptFlagged
        case invalidReferralName
        case invalidReferralCode
        case selfReferral
        case referralCodeNotFound
        case referralAlreadyRedeemed(balance: CreditsBalance?)
        case referralBypassUser
        case invalidClaimCode

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let code):
                return "Server error: \(code)"
            case .notAuthenticated:
                return "Please re-install the hi-key app."
            case .insufficientCredits:
                return "You're out of credits"
            case .promptFlagged:
                return "Content moderated. Please try a different idea."
            case .invalidReferralName:
                return "That name isn't valid. Use at least one letter."
            case .invalidReferralCode:
                return "That code doesn't look right."
            case .selfReferral:
                return "That's your own code."
            case .referralCodeNotFound:
                return "We couldn't find that code."
            case .referralAlreadyRedeemed:
                return "You've already used a referral code."
            case .referralBypassUser:
                return "Referrals aren't available for this account."
            case .invalidClaimCode:
                return "That code isn't valid. Check it and try again."
            }
        }
    }
}
