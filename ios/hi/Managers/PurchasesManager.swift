import Foundation
import Combine
import RevenueCat

enum PurchasesManagerError: Error {
    case cancelled
    case offeringsUnavailable
}

@MainActor
final class PurchasesManager: NSObject, ObservableObject {
    static let shared = PurchasesManager()

    // MARK: - Published State

    @Published private(set) var customerInfo: CustomerInfo? {
        didSet { mirrorToAppGroup() }
    }
    @Published private(set) var offerings: Offerings?

    var currentOffering: Offering? { offerings?.current }

    // MARK: - App Group Mirror
    // Subscription fields mirror to the app-group defaults so the keyboard
    // extension can render the same credits/renewal info without its own RC
    // fetch. Written on every customerInfo update; read by the keyboard via
    // `KeyboardAccountSummary`.

    private static let appGroupID = "group.ai.hi-key"
    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupID)
    }

    enum AppGroupKeys {
        static let subscriptionTier = "subscriptionTier"
        static let subscriptionRenewsAt = "subscriptionRenewsAt"
        static let subscriptionWeeklyBaseCredits = "subscriptionWeeklyBaseCredits"
    }

    private func mirrorToAppGroup() {
        guard let defaults = appGroupDefaults else { return }
        defaults.set(tierDisplayName, forKey: AppGroupKeys.subscriptionTier)
        defaults.set(subscriptionRenewsAt, forKey: AppGroupKeys.subscriptionRenewsAt)
        if let id = activeSubscriptionProductID, let weekly = weeklyCredits(for: id) {
            defaults.set(weekly, forKey: AppGroupKeys.subscriptionWeeklyBaseCredits)
        } else {
            defaults.removeObject(forKey: AppGroupKeys.subscriptionWeeklyBaseCredits)
        }
    }

    // MARK: - Internal Catalog
    // Throwaway map: product ID → client-side metadata that RC can't give us
    // (credit allowance per tier, upgrade/downgrade ordering, pack sizes).
    // Moves to the backend in Step 6 of purchases.md.

    private struct TierInfo {
        let displayName: String
        let weeklyCredits: Int
        /// Lower level = higher tier. Super=1, Plus=2, Starter=3.
        /// Drives upgrade/downgrade labels in AllPlansSheet.
        let level: Int
    }

    private struct PackInfo {
        let displayName: String
        let credits: Int
    }

    private let tierCatalog: [String: TierInfo] = [
        "starter.weekly": TierInfo(displayName: "Starter", weeklyCredits: 100, level: 3),
        "plus.weekly":    TierInfo(displayName: "Plus",    weeklyCredits: 200, level: 2),
        "super.weekly":   TierInfo(displayName: "Super",   weeklyCredits: 300, level: 1),
    ]

    private let packCatalog: [String: PackInfo] = [
        "pack.mini": PackInfo(displayName: "Mini pack", credits: 50),
        "pack.mega": PackInfo(displayName: "Mega pack", credits: 300),
    ]

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Bootstrap

    /// Call once after `Purchases.configure(...)`. Wires the delegate and
    /// kicks off the initial offerings + customer-info fetch.
    func bootstrap() {
        Purchases.shared.delegate = self
        Task { await refresh() }
    }

    private func refresh() async {
        async let offeringsLoad: Void = loadOfferings()
        async let customerInfoLoad: Void = loadCustomerInfo()
        _ = await (offeringsLoad, customerInfoLoad)
    }

    private func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            HiLogger.error("Failed to load RC offerings", error: error)
        }
    }

    private func loadCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            HiLogger.error("Failed to load RC customer info", error: error)
        }
    }

    // MARK: - Identity

    /// Attach the RC app user to a stable identifier (Supabase user id).
    /// Safe to call multiple times; RC deduplicates.
    func logIn(userID: String) async {
        do {
            let result = try await Purchases.shared.logIn(userID)
            customerInfo = result.customerInfo
        } catch {
            HiLogger.error("RC logIn failed", error: error)
        }
    }

    // MARK: - Purchase / Restore

    @discardableResult
    func purchase(_ package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled {
            throw PurchasesManagerError.cancelled
        }
        customerInfo = result.customerInfo
        Task { await refreshCreditsAfterWebhook() }
        return result.customerInfo
    }

    @discardableResult
    func restore() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        customerInfo = info
        Task { await refreshCreditsAfterWebhook() }
        return info
    }

    /// The RC → backend webhook lands asynchronously. Give it ~1s to arrive,
    /// then refresh; re-poll once more at ~3s as belt-and-braces. Whatever's
    /// missed here gets picked up on the next foreground refresh.
    private func refreshCreditsAfterWebhook() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await CreditsManager.shared.refresh()
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await CreditsManager.shared.refresh()
    }

    // MARK: - Entitlement Accessors

    var canRemoveWatermark: Bool {
        customerInfo?.entitlements.active["remove_watermark"] != nil
    }

    var canUseModelPicker: Bool {
        customerInfo?.entitlements.active["model_picker"] != nil
    }

    var hasActiveSubscription: Bool {
        !(customerInfo?.activeSubscriptions.isEmpty ?? true)
    }

    var activeSubscriptionProductID: String? {
        customerInfo?.activeSubscriptions.first
    }

    var tierDisplayName: String? {
        guard let id = activeSubscriptionProductID else { return nil }
        return tierCatalog[id]?.displayName
    }

    var subscriptionRenewsAt: Date? {
        guard let id = activeSubscriptionProductID else { return nil }
        return customerInfo?.expirationDate(forProductIdentifier: id)
    }

    var isInGracePeriod: Bool {
        billingIssueDetectedAt != nil
    }

    var billingIssueDetectedAt: Date? {
        customerInfo?.entitlements.active.values.compactMap(\.billingIssueDetectedAt).first
    }

    // MARK: - Packages

    func subscriptionPackages() -> [Package] {
        guard let packages = currentOffering?.availablePackages else { return [] }
        return packages
            .filter { tierCatalog[$0.storeProduct.productIdentifier] != nil }
            .sorted { lhs, rhs in
                // Starter (level 3) first, Super (level 1) last.
                let lhsLevel = tierCatalog[lhs.storeProduct.productIdentifier]?.level ?? .max
                let rhsLevel = tierCatalog[rhs.storeProduct.productIdentifier]?.level ?? .max
                return lhsLevel > rhsLevel
            }
    }

    func packPackages() -> [Package] {
        guard let packages = currentOffering?.availablePackages else { return [] }
        return packages
            .filter { packCatalog[$0.storeProduct.productIdentifier] != nil }
            .sorted { lhs, rhs in
                let lhsCredits = packCatalog[lhs.storeProduct.productIdentifier]?.credits ?? 0
                let rhsCredits = packCatalog[rhs.storeProduct.productIdentifier]?.credits ?? 0
                return lhsCredits < rhsCredits
            }
    }

    func package(forProductID productID: String) -> Package? {
        currentOffering?.availablePackages.first { $0.storeProduct.productIdentifier == productID }
    }

    // MARK: - Catalog Lookups

    func tierDisplayName(for productID: String) -> String? {
        tierCatalog[productID]?.displayName
    }

    func weeklyCredits(for productID: String) -> Int? {
        tierCatalog[productID]?.weeklyCredits
    }

    func packDisplayName(for productID: String) -> String? {
        packCatalog[productID]?.displayName
    }

    func packCredits(for productID: String) -> Int? {
        packCatalog[productID]?.credits
    }

    func level(for productID: String) -> Int? {
        tierCatalog[productID]?.level
    }
}

// MARK: - PurchasesDelegate

extension PurchasesManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
        }
    }
}
