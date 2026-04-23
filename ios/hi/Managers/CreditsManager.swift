import SwiftUI
import Combine

// MARK: - Credits Manager
// Thin read-only cache over the backend-authoritative ledger (/api/me).
// Balance is never mutated locally — purchases, generations, and refunds
// all round-trip through the backend. The app-group UserDefaults mirror
// lets the keyboard extension render the balance without its own fetch.

@MainActor
class CreditsManager: ObservableObject {
    static let shared = CreditsManager()

    private let appGroupID = "group.ai.hi-key"
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Published State

    @Published private(set) var credits: Int = 0
    @Published private(set) var extraCredits: Int = 0
    @Published private(set) var userName: String = ""
    @Published private(set) var referralCode: String? = nil

    // MARK: - Keys

    private enum Keys {
        static let credits = "credits"
        static let extraCredits = "extraCredits"
        static let userName = "userName"
        static let referralCode = "referralCode"
    }

    // MARK: - Init

    private init() {
        loadState()
    }

    private func loadState() {
        credits = userDefaults?.integer(forKey: Keys.credits) ?? 0
        extraCredits = userDefaults?.integer(forKey: Keys.extraCredits) ?? 0
        userName = userDefaults?.string(forKey: Keys.userName) ?? ""
        referralCode = userDefaults?.string(forKey: Keys.referralCode)
    }

    // MARK: - Balance Refresh

    /// Pull the latest balance from the backend. Safe to call often —
    /// triggered on app foreground, purchase success, generation response.
    func refresh() async {
        do {
            let response = try await APIClient.shared.me()
            apply(balance: response.credits)
        } catch {
            HiLogger.error("CreditsManager refresh failed", error: error)
        }
    }

    /// Update balance from a backend-provided snapshot (e.g. /api/generate
    /// response `balance`, insufficient-credits 402 payload).
    func apply(balance: APIClient.CreditsBalance) {
        credits = balance.sub_credits
        extraCredits = balance.extra_credits
        userDefaults?.set(credits, forKey: Keys.credits)
        userDefaults?.set(extraCredits, forKey: Keys.extraCredits)
        objectWillChange.send()
    }

    var hasCredits: Bool {
        credits > 0 || extraCredits > 0
    }

    // MARK: - User Profile

    func setUserName(_ name: String) {
        userName = name
        userDefaults?.set(name, forKey: Keys.userName)
        objectWillChange.send()
    }

    // MARK: - Referral Code Generation

    /// Generate a unique referral code for this user
    func generateReferralCode() -> String? {
        // Need a name to generate code
        guard !userName.isEmpty else { return nil }

        // If already generated, return existing
        if let existing = referralCode {
            return existing
        }

        // Generate: NAME-XXXXXX (NAME is first 6 chars uppercase, CODE is 6 char Crockford Base32)
        let namePrefix = String(userName.uppercased().filter { $0.isLetter }.prefix(6))
        let randomCode = generateCrockfordBase32(length: 6)
        let code = "\(namePrefix)-\(randomCode)"

        referralCode = code
        userDefaults?.set(code, forKey: Keys.referralCode)
        objectWillChange.send()

        return code
    }

    /// Generate random Crockford Base32 string
    private func generateCrockfordBase32(length: Int) -> String {
        // Crockford Base32 alphabet (excludes I, L, O, U to avoid confusion)
        let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        return String((0..<length).map { _ in alphabet.randomElement()! })
    }

    // MARK: - Debug

    func resetCredits() {
        credits = 0
        extraCredits = 0
        userName = ""
        referralCode = nil
        userDefaults?.removeObject(forKey: Keys.credits)
        userDefaults?.removeObject(forKey: Keys.extraCredits)
        userDefaults?.removeObject(forKey: Keys.userName)
        userDefaults?.removeObject(forKey: Keys.referralCode)
        objectWillChange.send()
    }
}
