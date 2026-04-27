import Foundation

// MARK: - Keyboard Account Summary
// Read-only view over the App Group defaults populated by CreditsManager and
// PurchasesManager in the main app. The keyboard extension uses this to
// render credits, referral code, and subscription info in the menu without
// running its own /api/me or RevenueCat fetch.

struct KeyboardAccountSummary {
    static let appGroupID = "group.ai.hi-key"

    // Keep keys in sync with CreditsManager.Keys and PurchasesManager.AppGroupKeys.
    private enum Keys {
        // From CreditsManager
        static let credits = "credits"
        static let extraCredits = "extraCredits"
        static let referralCode = "referralCode"
        static let doubleCredits = "doubleCredits"
        // From PurchasesManager
        static let subscriptionTier = "subscriptionTier"
        static let subscriptionRenewsAt = "subscriptionRenewsAt"
        static let subscriptionWeeklyBaseCredits = "subscriptionWeeklyBaseCredits"
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    let credits: Int
    let extraCredits: Int
    let referralCode: String?
    let doubleCredits: Bool
    let subscriptionTier: String?
    let subscriptionRenewsAt: Date?
    let subscriptionWeeklyBaseCredits: Int

    static func load() -> KeyboardAccountSummary {
        let d = defaults
        return KeyboardAccountSummary(
            credits: d?.integer(forKey: Keys.credits) ?? 0,
            extraCredits: d?.integer(forKey: Keys.extraCredits) ?? 0,
            referralCode: d?.string(forKey: Keys.referralCode),
            doubleCredits: d?.bool(forKey: Keys.doubleCredits) ?? false,
            subscriptionTier: d?.string(forKey: Keys.subscriptionTier),
            subscriptionRenewsAt: d?.object(forKey: Keys.subscriptionRenewsAt) as? Date,
            subscriptionWeeklyBaseCredits: d?.integer(forKey: Keys.subscriptionWeeklyBaseCredits) ?? 0
        )
    }

    // MARK: - Writers
    // Called from the keyboard when generate or /api/me returns fresh data,
    // so the menu reflects the latest server-authoritative balance without
    // needing the main app to be opened. Subscription tier/renewal stay
    // owned by the main app's PurchasesManager (RevenueCat-derived).

    static func applyMe(_ response: APIClient.MeResponse) {
        let d = defaults
        d?.set(response.credits.sub_credits, forKey: Keys.credits)
        d?.set(response.credits.extra_credits, forKey: Keys.extraCredits)
        d?.set(response.profile?.referral_code, forKey: Keys.referralCode)
        d?.set(response.double_credits ?? false, forKey: Keys.doubleCredits)
    }

    static func applyBalance(_ balance: APIClient.CreditsBalance) {
        let d = defaults
        d?.set(balance.sub_credits, forKey: Keys.credits)
        d?.set(balance.extra_credits, forKey: Keys.extraCredits)
    }

    // MARK: - Derived

    var totalCredits: Int { credits + extraCredits }

    var hasActiveSubscription: Bool { subscriptionTier != nil }

    var weeklyCreditAllowance: Int {
        guard subscriptionWeeklyBaseCredits > 0 else { return 0 }
        return doubleCredits ? subscriptionWeeklyBaseCredits * 2 : subscriptionWeeklyBaseCredits
    }

    var planLabel: String {
        (subscriptionTier ?? "Free").uppercased()
    }

    /// Mirrors HomeView's `weeklyCreditsCaption`: "X of Y weekly · resets MMM d".
    var weeklyCreditsCaption: String? {
        guard hasActiveSubscription else { return nil }
        let weekly = weeklyCreditAllowance
        let suffix: String
        if let date = subscriptionRenewsAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            suffix = " · resets \(formatter.string(from: date))"
        } else {
            suffix = ""
        }
        return "\(credits) of \(weekly) weekly\(suffix)"
    }

    var extraCreditsCaption: String? {
        guard extraCredits > 0 else { return nil }
        return "+\(extraCredits) extra \(extraCredits == 1 ? "credit" : "credits")"
    }

    /// Single-line description for the keyboard menu row. Compresses plan,
    /// weekly progress, renewal date, and extras into one caption.
    var creditsRowDescription: String {
        if hasActiveSubscription {
            var parts: [String] = []
            if let tier = subscriptionTier { parts.append(tier) }
            if subscriptionWeeklyBaseCredits > 0 {
                parts.append("\(credits) of \(weeklyCreditAllowance)")
            }
            if extraCredits > 0 {
                parts.append("+\(extraCredits) extra")
            }
            return parts.joined(separator: " · ")
        } else {
            return "Free plan"
        }
    }
}
