import SwiftUI
import Combine
import PostHog

// MARK: - Credits Manager
// Thin read-only cache over the backend-authoritative ledger and profile
// (/api/me). Balance and referral fields are never mutated locally —
// purchases, generations, refunds, and referral code mint/redeem all
// round-trip through the backend. Display name is the only locally-owned
// field (user-editable, used for "Welcome, {name}"). Credits and referral
// code mirror into app-group UserDefaults so the keyboard extension can
// render them without its own fetch.

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
    @Published private(set) var referredBy: String? = nil
    @Published private(set) var doubleCredits: Bool = false

    // MARK: - Keys

    private enum Keys {
        static let credits = "credits"
        static let extraCredits = "extraCredits"
        static let userName = "userName"
        static let referralCode = "referralCode"
        static let doubleCredits = "doubleCredits"
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
        doubleCredits = userDefaults?.bool(forKey: Keys.doubleCredits) ?? false
    }

    // MARK: - /api/me Sync

    /// Pull the latest balance + profile from the backend. Safe to call often —
    /// triggered on app foreground, purchase success, generation response.
    func refresh() async {
        do {
            let response = try await APIClient.shared.me()
            apply(me: response)
        } catch {
            HiLogger.error("CreditsManager refresh failed", error: error)
        }
    }

    /// Update cached state from a full /api/me response.
    func apply(me response: APIClient.MeResponse) {
        apply(balance: response.credits)
        referralCode = response.profile?.referral_code
        referredBy = response.referred_by
        doubleCredits = response.double_credits ?? false
        userDefaults?.set(referralCode, forKey: Keys.referralCode)
        userDefaults?.set(doubleCredits, forKey: Keys.doubleCredits)
    }

    /// Update balance-only from a backend snapshot (e.g. /api/generate
    /// response `balance`, insufficient-credits 402 payload, redeem response).
    func apply(balance: APIClient.CreditsBalance) {
        credits = balance.sub_credits
        extraCredits = balance.extra_credits
        userDefaults?.set(credits, forKey: Keys.credits)
        userDefaults?.set(extraCredits, forKey: Keys.extraCredits)
    }

    var hasCredits: Bool {
        credits > 0 || extraCredits > 0
    }

    // MARK: - User Profile (local display name)

    func setUserName(_ name: String) {
        userName = name
        userDefaults?.set(name, forKey: Keys.userName)
    }

    // MARK: - Referral Code Mint / Redeem

    /// Mint this user's immutable referral code from a display name. Backend
    /// sanitizes (letters only, uppercased, truncated to 6 chars) and builds
    /// `{PREFIX}-{6-char Crockford Base32}`. Idempotent on the backend —
    /// repeated calls return the existing code.
    func createReferralCode(name: String) async throws -> String {
        let response = try await APIClient.shared.createReferralCode(name: name)
        referralCode = response.code
        userDefaults?.set(response.code, forKey: Keys.referralCode)
        // PostHog: Track referral code creation
        PostHogSDK.shared.capture("referral_code_created", properties: [
            "code": response.code,
        ])
        return response.code
    }

    /// Redeem a friend's referral code. Backend stamps `referred_by` on this
    /// user; the 50-credit bonus for both sides is paid when this user starts a
    /// trial or buys credits (immediately if they already have). One-shot — a
    /// second call with a different code returns `alreadyRedeemed`.
    /// Returns whether the bonus is still pending.
    @discardableResult
    func redeemReferralCode(_ code: String) async throws -> Bool {
        let response = try await APIClient.shared.redeemReferralCode(code: code)
        apply(balance: response.credits)
        return response.bonus_pending ?? false
    }

    // MARK: - Waitlist Claim Code

    /// Apply a waitlist claim code. Backend flips `double_credits = true`
    /// (permanent — 2x on all future purchases and renewals) and may top up
    /// sub credits by one tier if the user has an active sub.
    func claimWaitlistCode(_ code: String) async throws {
        let balance = try await APIClient.shared.claimWaitlistCode(code: code)
        apply(balance: balance)
        doubleCredits = true
        userDefaults?.set(true, forKey: Keys.doubleCredits)
    }

    // MARK: - Debug

    func resetCredits() {
        credits = 0
        extraCredits = 0
        userName = ""
        referralCode = nil
        referredBy = nil
        doubleCredits = false
        userDefaults?.removeObject(forKey: Keys.credits)
        userDefaults?.removeObject(forKey: Keys.extraCredits)
        userDefaults?.removeObject(forKey: Keys.userName)
        userDefaults?.removeObject(forKey: Keys.referralCode)
        userDefaults?.removeObject(forKey: Keys.doubleCredits)
    }
}
