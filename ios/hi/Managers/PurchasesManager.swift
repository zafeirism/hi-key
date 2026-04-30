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
        didSet {
            mirrorToAppGroup()
            // Once the active subscription disappears (cancel/refund/expiry),
            // drop any pending trial-end reminder so it doesn't fire with
            // stale copy. Idempotent — safe to call when nothing is scheduled.
            if customerInfo?.activeSubscriptions.isEmpty ?? true {
                TrialReminderManager.shared.cancelPendingReminder()
            }
        }
    }
    @Published private(set) var offerings: Offerings?
    @Published private(set) var introEligibility: [String: IntroEligibility] = [:]

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
        static let subscriptionWeeklyBaseCredits = "subscriptionWeeklyBaseCredits"
        static let removeWatermarkEntitlementActive = "removeWatermarkEntitlementActive"
    }

    private func mirrorToAppGroup() {
        guard let defaults = appGroupDefaults else { return }
        defaults.set(tierDisplayName, forKey: AppGroupKeys.subscriptionTier)
        if let id = activeSubscriptionProductID, let weekly = weeklyCredits(for: id) {
            defaults.set(weekly, forKey: AppGroupKeys.subscriptionWeeklyBaseCredits)
        } else {
            defaults.removeObject(forKey: AppGroupKeys.subscriptionWeeklyBaseCredits)
        }
        defaults.set(canRemoveWatermark, forKey: AppGroupKeys.removeWatermarkEntitlementActive)
    }

    // MARK: - Pack Catalog
    // One-time credit packs. Tier subscription catalog lives in
    // SubscriptionCatalog (shared with the keyboard extension). Both move
    // to the backend in Step 6 of purchases.md.

    private struct PackInfo {
        let displayName: String
        let credits: Int
    }

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
            await refreshIntroEligibility()
        } catch {
            HiLogger.error("Failed to load RC offerings", error: error)
        }
    }

    /// Asks RC whether the current Apple ID is eligible for the intro offer
    /// on each subscription product. Returns `.eligible` only when the user
    /// has not previously consumed the trial. Refresh after offerings load
    /// and after `customerInfo` updates that may flip eligibility.
    private func refreshIntroEligibility() async {
        guard let offerings else { return }
        let productIDs = offerings.all.values
            .flatMap { $0.availablePackages }
            .map { $0.storeProduct.productIdentifier }
        let unique = Array(Set(productIDs))
        guard !unique.isEmpty else { return }
        introEligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: unique)
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
        let productID = package.storeProduct.productIdentifier
        // Capture eligibility before the purchase — RC will flip it to
        // ineligible immediately after, so we'd lose this signal otherwise.
        let wasTrialEligible = isTrialEligible(for: productID)

        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled {
            throw PurchasesManagerError.cancelled
        }
        customerInfo = result.customerInfo

        if wasTrialEligible,
           let expiration = result.customerInfo.expirationDate(forProductIdentifier: productID) {
            await TrialReminderManager.shared.requestPermissionAndSchedule(trialExpiration: expiration)
        }

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

    /// True when restoring this `CustomerInfo` should let the user past a
    /// paywall: any active entitlement, any active subscription, or any past
    /// consumable (`pack.mini` / `pack.mega`). The consumable case unblocks
    /// reinstalling users whose backend `extra_credits` survived — they may
    /// still have credits to spend, so they shouldn't be stuck on the paywall.
    func hasRestorablePurchases(_ info: CustomerInfo) -> Bool {
        !info.entitlements.active.isEmpty
            || !info.activeSubscriptions.isEmpty
            || !info.nonSubscriptionTransactions.isEmpty
    }

    var activeSubscriptionProductID: String? {
        customerInfo?.activeSubscriptions.first
    }

    var tierDisplayName: String? {
        guard let id = activeSubscriptionProductID else { return nil }
        return SubscriptionCatalog.displayName(for: id)
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
            .filter { SubscriptionCatalog.tiers[$0.storeProduct.productIdentifier] != nil }
            .sorted { lhs, rhs in
                // Starter (level 3) first, Super (level 1) last.
                let lhsLevel = SubscriptionCatalog.level(for: lhs.storeProduct.productIdentifier) ?? .max
                let rhsLevel = SubscriptionCatalog.level(for: rhs.storeProduct.productIdentifier) ?? .max
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
        SubscriptionCatalog.displayName(for: productID)
    }

    func weeklyCredits(for productID: String) -> Int? {
        SubscriptionCatalog.weeklyCredits(for: productID)
    }

    func trialCredits(for productID: String) -> Int? {
        SubscriptionCatalog.trialCredits(for: productID)
    }

    func packDisplayName(for productID: String) -> String? {
        packCatalog[productID]?.displayName
    }

    func packCredits(for productID: String) -> Int? {
        packCatalog[productID]?.credits
    }

    func level(for productID: String) -> Int? {
        SubscriptionCatalog.level(for: productID)
    }

    // MARK: - Trial Eligibility

    /// True when RC says the user can still claim the free-trial intro offer
    /// on this product, AND the StoreKit product actually has a free-trial
    /// intro discount configured. Paid intro offers (e.g. discounted weeks)
    /// would need different copy, so they're excluded here.
    func isTrialEligible(for productID: String) -> Bool {
        //return productID == "super.weekly" ? true : false
        guard introEligibility[productID]?.status == .eligible else { return false }
        guard let package = package(forProductID: productID),
              let intro = package.storeProduct.introductoryDiscount else {
            return false
        }
        return intro.paymentMode == .freeTrial
    }
}

// MARK: - PurchasesDelegate

extension PurchasesManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            await self.refreshIntroEligibility()
        }
    }
}
