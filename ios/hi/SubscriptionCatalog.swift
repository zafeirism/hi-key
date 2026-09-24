import Foundation

// MARK: - Subscription Catalog
// Static map from RC product IDs to display name, weekly credit allowance,
// and level (lower = higher tier — drives upgrade/downgrade ordering).
// Compiled into both the `hi` app and the keyboard extension via the
// keyboard target's membership exception, so both targets can map a
// product ID to a tier without depending on RevenueCat. Slated to move to
// the backend (see purchases.md, step 6).

enum SubscriptionCatalog {

    struct Tier {
        let displayName: String
        let weeklyCredits: Int
        /// One-time bonus credits granted by the backend during the free
        /// trial period; expire when the trial ends. nil for tiers without
        /// a free-trial intro offer. Backend-controlled — see purchases.md.
        let trialCredits: Int?
        /// Lower level = higher tier. Super=1, Plus=2, Starter=3.
        let level: Int
    }

    static let tiers: [String: Tier] = [
        "starter.weekly": Tier(displayName: "Starter", weeklyCredits: 100, trialCredits: nil, level: 3),
        "plus.weekly":    Tier(displayName: "Plus",    weeklyCredits: 200, trialCredits: nil, level: 2),
        "super.weekly":   Tier(displayName: "Super",   weeklyCredits: 300, trialCredits: 200, level: 1),
    ]

    static func displayName(for productID: String) -> String? {
        tiers[productID]?.displayName
    }

    static func weeklyCredits(for productID: String) -> Int? {
        tiers[productID]?.weeklyCredits
    }

    static func trialCredits(for productID: String) -> Int? {
        tiers[productID]?.trialCredits
    }

    static func level(for productID: String) -> Int? {
        tiers[productID]?.level
    }
}
