import SwiftUI
import Combine

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case none = "none"
    case lite = "lite"
    case plus = "plus"
    case pro = "pro"
    
    var displayName: String {
        switch self {
        case .none: return "Free"
        case .lite: return "Lite"
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }
    
    var monthlyPrompts: Int {
        switch self {
        case .none: return 0
        case .lite: return 25
        case .plus: return 50
        case .pro: return 110
        }
    }
    
    var price: String {
        switch self {
        case .none: return "Free"
        case .lite: return "$4.99/mo"
        case .plus: return "$6.99/mo"
        case .pro: return "$12.99/mo"
        }
    }
    
    var features: [String] {
        switch self {
        case .none:
            return ["5 free credits to start"]
        case .lite:
            return ["25 prompts per month", "4 images per prompt"]
        case .plus:
            return ["50 prompts per month", "4 images per prompt"]
        case .pro:
            return ["110 prompts per month", "4 images per prompt", "No watermark", "Early access to new features"]
        }
    }
    
    var canRemoveWatermark: Bool {
        self == .pro
    }
}

// MARK: - One-Time Pack

enum CreditPack: String, CaseIterable {
    case mini = "mini"
    case big = "big"
    
    var displayName: String {
        switch self {
        case .mini: return "Mini Pack"
        case .big: return "Big Pack"
        }
    }
    
    var credits: Int {
        switch self {
        case .mini: return 10
        case .big: return 25
        }
    }
    
    var price: String {
        switch self {
        case .mini: return "$2.99"
        case .big: return "$5.99"
        }
    }
}

// MARK: - Credits Manager

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
    @Published private(set) var subscriptionTier: SubscriptionTier = .none
    @Published private(set) var userName: String = ""
    @Published private(set) var referralCode: String? = nil
    
    // MARK: - Keys
    
    private enum Keys {
        static let credits = "credits"
        static let extraCredits = "extraCredits"
        static let subscriptionTier = "subscriptionTier"
        static let userName = "userName"
        static let referralCode = "referralCode"
        static let hasReceivedInitialCredits = "hasReceivedInitialCredits"
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
        
        if let tierString = userDefaults?.string(forKey: Keys.subscriptionTier),
           let tier = SubscriptionTier(rawValue: tierString) {
            subscriptionTier = tier
        }
    }
    
    // MARK: - Credits Management
    
    /// Grant initial credits (5 base, +5 if referral applied)
    func grantInitialCredits(withReferral: Bool) {
        guard !(userDefaults?.bool(forKey: Keys.hasReceivedInitialCredits) ?? false) else {
            return // Already received initial credits
        }
        
        let initialAmount = withReferral ? 10 : 5
        credits = initialAmount
        userDefaults?.set(credits, forKey: Keys.credits)
        userDefaults?.set(true, forKey: Keys.hasReceivedInitialCredits)
        objectWillChange.send()
    }
    
    /// Add credits (from purchase or referral bonus)
    func addCredits(_ amount: Int) {
        credits += amount
        userDefaults?.set(credits, forKey: Keys.credits)
        objectWillChange.send()
    }
    
    /// Use a credit (called when generating images)
    func useCredit() -> Bool {
        guard credits > 0 else { return false }
        credits -= 1
        userDefaults?.set(credits, forKey: Keys.credits)
        objectWillChange.send()
        return true
    }
    
    /// Add extra one-time credits (from pack purchase)
    func addExtraCredits(_ amount: Int) {
        extraCredits += amount
        credits += amount
        userDefaults?.set(extraCredits, forKey: Keys.extraCredits)
        userDefaults?.set(credits, forKey: Keys.credits)
        objectWillChange.send()
    }

    /// Check if user has credits available
    var hasCredits: Bool {
        credits > 0
    }
    
    // MARK: - Subscription Management
    
    func setSubscription(_ tier: SubscriptionTier) {
        subscriptionTier = tier
        userDefaults?.set(tier.rawValue, forKey: Keys.subscriptionTier)
        objectWillChange.send()
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
        subscriptionTier = .none
        userName = ""
        referralCode = nil
        userDefaults?.removeObject(forKey: Keys.credits)
        userDefaults?.removeObject(forKey: Keys.extraCredits)
        userDefaults?.removeObject(forKey: Keys.subscriptionTier)
        userDefaults?.removeObject(forKey: Keys.userName)
        userDefaults?.removeObject(forKey: Keys.referralCode)
        userDefaults?.removeObject(forKey: Keys.hasReceivedInitialCredits)
        objectWillChange.send()
    }
}
