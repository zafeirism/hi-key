import SwiftUI
import Combine

// MARK: - Keyboard Mode

enum KeyboardMode: Equatable {
    case composing              // Typing prompt, showing suggestions + keyboard
    case results                // Showing image carousel
    case menu                   // Showing settings / credits / referral menu
}

// MARK: - View Model

@MainActor
class HiKeyboardViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var prompt = ""
    @Published var isPromptFocused = true
    @Published var isGenerating = false
    @Published var cursorPosition = 0
    @Published var errorMessage: String?
    @Published var showingResults = false
    @Published var showSuggestions = false
    @Published var fullscreenImageIndex: Int?
    @Published var mode: KeyboardMode = .composing

    // Transient one-line message shown by `StatusBarView` in place of the
    // default copy hint. Used to surface generation failures without
    // interrupting the carousel. Always reverts to the default after a few
    // seconds.
    @Published var transientStatusMessage: String?

    // Snapshot of credits / referral / subscription state pulled from the
    // App Group. Refreshed after /api/me on keyboard load and after every
    // /api/generate so the menu reflects fresh balance without the user
    // having to reopen the main app.
    @Published var accountSummary: KeyboardAccountSummary = .load()

    // Drives the transient "Credits running low" status shown in the
    // suggestion bar. Triggered on SuggestionBarView appearance when the
    // user can still generate but the balance is approaching empty.
    @Published var showCreditsRunningLow: Bool = false

    // Tracks the mode the user was in before opening the menu, so closing
    // the menu returns them to results vs composing as appropriate.
    private var modeBeforeMenu: KeyboardMode = .composing

    // All generated images (cumulative)
    @Published var allImages: [GeneratedImage] = []

    // Reference to action handler for syncing focus state
    weak var actionHandler: HiActionHandler?

    // Injected by KeyboardViewController so the menu can open hi-key:// URLs
    // through `extensionContext.open(_:completionHandler:)` — the only
    // sanctioned way for a keyboard extension to launch its host app.
    var openURLHandler: ((URL) -> Void)?

    // MARK: - Computed Properties

    var hasResults: Bool {
        !allImages.isEmpty
    }

    var isShowingFullscreen: Bool {
        fullscreenImageIndex != nil
    }

    // Images sorted for display: grouped into batches by generation time
    // (oldest batch first), and within each batch by their first-reveal
    // time (loadedAt) — ascending, with not-yet-revealed images last. The
    // loadedAt is persisted across sessions, so restored images keep the
    // original order they were first shown in.
    var sortedImages: [GeneratedImage] {
        let groups = Dictionary(grouping: allImages, by: \.generatedAt)
        return groups.keys.sorted().flatMap { key in
            sortByLoaded(groups[key] ?? [])
        }
    }

    private func sortByLoaded(_ images: [GeneratedImage]) -> [GeneratedImage] {
        images.sorted { lhs, rhs in
            switch (lhs.loadedAt, rhs.loadedAt) {
            case let (l?, r?): return l < r
            case (_?, nil):    return true
            case (nil, _?):    return false
            case (nil, nil):   return false
            }
        }
    }

    // Images the carousel should actually render. Three reasons to render
    // a placeholder/image:
    //  - `isLoaded`: bytes are in memory.
    //  - `loadedAt != nil`: image was successfully loaded in a previous
    //     session and just needs the card to re-fetch from R2.
    //  - age < `placeholderTimeout`: fresh, still has a reasonable chance
    //     to arrive. Once it ages past the deadline without ever loading,
    //     we hide it so stale URLs don't leave lingering shimmer tiles.
    var visibleImages: [GeneratedImage] {
        let now = Date()
        return sortedImages.filter { image in
            image.isLoaded
                || image.loadedAt != nil
                || now.timeIntervalSince(image.generatedAt) < Self.placeholderTimeout
        }
    }
    
    // MARK: - Dependencies
    
    private let apiClient = APIClient.shared
    private var sessionID: String
    
    // MARK: - Init
    
    init() {
        self.sessionID = apiClient.newSessionID()
        self.showingResults = false
        self.mode = .composing

        hydrateFromStore()
    }

    private func hydrateFromStore() {
        let generations = RecentGenerationsStore.loadValid()
        guard !generations.isEmpty else { return }

        let hydrated: [GeneratedImage] = generations.flatMap { gen in
            gen.images.map {
                GeneratedImage(
                    id: $0.id,
                    url: $0.url,
                    prompt: gen.prompt,
                    generatedAt: gen.generatedAt,
                    loadedAt: $0.loadedAt
                )
            }
        }

        allImages = hydrated

        for image in hydrated {
            startLoadTracking(for: image)
        }

        if let lastPrompt = generations.last?.prompt {
            prompt = lastPrompt
            cursorPosition = lastPrompt.count
        }

        showingResults = true
        mode = .results
        isPromptFocused = false

        let now = Date()
        let summary = hydrated.map { img -> String in
            let age = Int(now.timeIntervalSince(img.generatedAt))
            let loaded = img.loadedAt != nil ? "loadedBefore" : "neverLoaded"
            return "\(img.id)(age=\(age)s,\(loaded))"
        }
        ensureStatusPollerRunning()
    }
    
    // MARK: - Prompt Editing (called by action handler)
    
    func addToPrompt(_ text: String) {
        // Insert at cursor position instead of end
        let index = prompt.index(prompt.startIndex, offsetBy: cursorPosition)
        prompt.insert(contentsOf: text, at: index)
        setCursorPosition(cursorPosition + text.count)
    }
    
    func deleteCharacter() {
        // Delete character before cursor position
        guard cursorPosition > 0 else { return }
        let index = prompt.index(prompt.startIndex, offsetBy: cursorPosition - 1)
        prompt.remove(at: index)
        setCursorPosition(cursorPosition - 1)
    }
    
    // MARK: - Cursor Management
    
    func setCursorPosition(_ position: Int) {
        cursorPosition = min(max(0, position), prompt.count)
        autoCapitalizeIfNeeded()
    }
    
    func moveCursorToEnd() {
        setCursorPosition(prompt.count)
    }
    
    func promptUpToCursor() -> String {
        guard cursorPosition > 0 else { return "" }
        
        let index = prompt.index(prompt.startIndex, offsetBy: cursorPosition)
        let promptUpToCursor = String(prompt[..<index])
        return promptUpToCursor
    }
    
    // MARK: - Focus Management
    
    func focusPrompt() {
        isPromptFocused = true
        moveCursorToEnd()
        showingResults = false
        mode = .composing
    }
    
    func clearPrompt() {
        prompt = ""
        setCursorPosition(0)
        // Keep focus so user can start typing again
    }

    func dismissError() {
        errorMessage = nil
        focusPrompt()
    }
    
    func unfocusPrompt() {
        isPromptFocused = false
    }
    
    // MARK: - Auto-Capitalization Logic
    
    func autoCapitalizeIfNeeded() {
        guard let actionHandler = actionHandler else { return }
        
        let shouldCapitalize = shouldAutoCapitalize()
        actionHandler.autoCapitalize(shouldCapitalize: shouldCapitalize)
    }
    
    private func shouldAutoCapitalize() -> Bool {
        guard cursorPosition > 0 else { return true }
        
        let promptUpToCursor = promptUpToCursor()
        
        let trimmed = promptUpToCursor.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }
        
        // Capitalize after sentence-ending punctuation followed by space
        if let lastChar = trimmed.last {
            let sentenceEnders: Set<Character> = [".", "!", "?"]
            if sentenceEnders.contains(lastChar) && promptUpToCursor.last == " " {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Generation
    
    private let maxStoredImages = 16
    
    func generate() async {
        guard !prompt.isEmpty else {
            HiLogger.warning("Generate called with empty prompt", category: .keyboard)
            return
        }

        isGenerating = true
        unfocusPrompt()
        showingResults = true
        mode = .results
        errorMessage = nil

        do {
            let requestID = apiClient.newRequestID()

            let randomStyles = ImageStylePreferences.randomStylesEnabled
                ? ImageStylePreferences.randomEnabledStyles(count: 4)
                : []

            let response = try await apiClient.generate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                randomStyles: randomStyles
            )

            HiLogger.info("✅ Got \(response.images.count) urls back for requestID \(requestID)", category: .keyboard)

            let batchGeneratedAt = Date()
            let newImages = response.images.map { image in
                GeneratedImage(
                    id: image.id,
                    url: image.signedUrl,
                    prompt: prompt,
                    generatedAt: batchGeneratedAt
                )
            }

            let totalAfterAdd = allImages.count + newImages.count
            if totalAfterAdd > maxStoredImages {
                let removeCount = totalAfterAdd - maxStoredImages
                allImages.removeFirst(removeCount)
            }

            allImages.append(contentsOf: newImages)

            for image in newImages {
                startLoadTracking(for: image)
            }
            
            let stored = StoredGeneration(
                prompt: prompt,
                generatedAt: batchGeneratedAt,
                images: newImages.map { StoredImage(id: $0.id, url: $0.url) }
            )
            RecentGenerationsStore.append(stored)

            if let balance = response.balance {
                KeyboardAccountSummary.applyBalance(balance)
                accountSummary = .load()
            }

            isGenerating = false
            ensureStatusPollerRunning()

        } catch {
            HiLogger.error("Generate failed!", error: error, category: .keyboard)
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }

    // Hard upper bound on how long a placeholder may sit unresolved. The
    // status poller is the primary signal for `error` removals; this is the
    // safety net for the case where status polling itself fails repeatedly.
    static let placeholderTimeout: TimeInterval = 90

    // Stale (already-loaded-once-but-not-yet-rehydrated) images get a brief
    // window to refetch via the card's normal load path before we give up.
    private static let staleRefetchTimeout: TimeInterval = 30

    /// Schedules a removal-by-deadline for any image that hasn't loaded yet.
    /// Fresh images get the full `placeholderTimeout` from `generatedAt`.
    /// Restored images that were previously loaded get a short refetch
    /// window from now (their card will pick them up via `visibleImages`
    /// because `loadedAt != nil`). Restored images that were never loaded
    /// follow the same age-based deadline as fresh ones.
    private func startLoadTracking(for image: GeneratedImage) {
        let age = Date().timeIntervalSince(image.generatedAt)
        let delay: TimeInterval
        if image.loadedAt != nil && age >= Self.placeholderTimeout {
            delay = Self.staleRefetchTimeout
        } else {
            delay = max(0, Self.placeholderTimeout - age)
        }
        scheduleRemovalAtDeadline(imageID: image.id, delay: delay)
    }

    private func scheduleRemovalAtDeadline(imageID: String, delay: TimeInterval) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self,
                  let idx = self.allImages.firstIndex(where: { $0.id == imageID }),
                  !self.allImages[idx].isLoaded
            else { return }
            self.removeImageEverywhere(id: imageID, reason: "deadline")
        }
    }

    // MARK: - Status Polling

    // Poll cadence for `/api/generations`. Hits Vercel + Supabase, so we
    // pace it deliberately; image bytes are fetched separately from R2 by
    // the card, which is the cheap path and stays fast.
    private static let statusPollInterval: TimeInterval = 5
    private static let transientStatusDuration: TimeInterval = 3

    private var statusPollTask: Task<Void, Never>?
    private var transientStatusTask: Task<Void, Never>?
    private var creditsRunningLowTask: Task<Void, Never>?

    // Threshold at which we surface the soft "running low" warning. Above
    // `minCreditsForGeneration` (the hard "can't generate" cutoff) but low
    // enough that the next handful of generations will exhaust the balance.
    private static let creditsRunningLowThreshold: Int = 30
    private static let creditsRunningLowDuration: TimeInterval = 5

    // Ids the backend has confirmed `ready`. Bytes are now available on
    // R2 and the card will fetch them on its own; further status polls
    // would just repeat the same answer. Excluded from `pendingImageIDs`.
    private var statusKnownReadyIDs = Set<String>()

    private var pendingImageIDs: [String] {
        allImages
            .filter { !$0.isLoaded && !statusKnownReadyIDs.contains($0.id) }
            .map(\.id)
    }

    /// Removes an image from the carousel AND from the persistent store,
    /// so it doesn't reappear on the next keyboard launch. Call this from
    /// any path that decides an image is no longer useful (status `error`,
    /// safety-net deadline).
    private func removeImageEverywhere(id imageID: String, reason: String) {
        if let idx = allImages.firstIndex(where: { $0.id == imageID }) {
            allImages.remove(at: idx)
        }
        statusKnownReadyIDs.remove(imageID)
        RecentGenerationsStore.removeImage(id: imageID)
    }

    /// Starts a single poller that batches every currently-pending id into
    /// one `/api/generations` call every 5s, removes any that come back
    /// with `error`, and stops once nothing remains pending. Idempotent —
    /// if a poll is already running, new generations just join the next
    /// tick.
    private func ensureStatusPollerRunning() {
        guard statusPollTask == nil else { return }
        guard !pendingImageIDs.isEmpty else { return }
        statusPollTask = Task { [weak self] in
            await self?.runStatusPoller()
            self?.statusPollTask = nil
        }
    }

    private func runStatusPoller() async {
        var anyErrored = false

        while !Task.isCancelled {
            let pending = pendingImageIDs
            if pending.isEmpty { break }

            HiLogger.info("Status poll for ids: \(pending)", category: .keyboard)
            do {
                let statuses = try await apiClient.generationStatuses(ids: pending)
                HiLogger.info("Status poll response: \(statuses.map { "\($0.id):\($0.status.rawValue)" })", category: .keyboard)

                // Stop polling ids the backend has confirmed ready — bytes
                // are on R2 and the card will fetch them; further polls
                // would just repeat the same answer.
                for entry in statuses where entry.status == .ready {
                    statusKnownReadyIDs.insert(entry.id)
                }

                let errored = statuses.filter { $0.status == .error }
                if !errored.isEmpty {
                    anyErrored = true
                    for entry in errored {
                        removeImageEverywhere(id: entry.id, reason: "status=error")
                    }
                    showTransientStatus("Some images failed. Credits refunded.")
                }
            } catch {
                HiLogger.error("Status poll failed", error: error, category: .keyboard)
            }

            if pendingImageIDs.isEmpty { break }

            try? await Task.sleep(nanoseconds: UInt64(Self.statusPollInterval * 1_000_000_000))
        }

        if anyErrored {
            await refreshFromBackend()
        }
    }

    /// Flashes the "Credits running low" status in the suggestion bar for
    /// `creditsRunningLowDuration` seconds. Skipped when the user can no
    /// longer generate at all — the hard "not enough credits" status owns
    /// that case and stays visible until they buy.
    func triggerCreditsRunningLowIfNeeded() {
        let summary = accountSummary
        guard summary.hasEnoughCredits,
              summary.totalCredits < Self.creditsRunningLowThreshold
        else { return }

        creditsRunningLowTask?.cancel()
        showCreditsRunningLow = true
        creditsRunningLowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.creditsRunningLowDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.showCreditsRunningLow = false
            self?.creditsRunningLowTask = nil
        }
    }

    private func showTransientStatus(_ message: String) {
        transientStatusTask?.cancel()
        transientStatusMessage = message
        transientStatusTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.transientStatusDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.transientStatusMessage = nil
            self?.transientStatusTask = nil
        }
    }
    
    // MARK: - Image Actions
    
    func copyImage(_ image: GeneratedImage) {
        guard let data = image.imageData, let watermarkedImage = Watermark.add(to: data)
        else { return }

        UIPasteboard.general.image = watermarkedImage
        HiLogger.info("Image copied to pasteboard: \(image.url)")
        markAsCopied(image.id)

        Task {
            try? await apiClient.reportCopy(generationId: image.id)
        }
    }
    
    func markImageLoaded(_ imageID: String, data: Data) {
        guard let index = allImages.firstIndex(where: { $0.id == imageID }) else { return }

        allImages[index].isLoaded = true
        if allImages[index].loadedAt == nil {
            // Only stamp loadedAt on the first reveal. Restored images carry
            // their original loadedAt from storage, and we preserve it so the
            // within-batch order stays stable across sessions.
            allImages[index].loadedAt = Date()
        }
        allImages[index].imageData = data

        if let loadedAt = allImages[index].loadedAt {
            RecentGenerationsStore.updateLoadedAt(imageID: imageID, loadedAt: loadedAt)
        }
    }
    
    private func markAsCopied(_ imageID: String) {
        if let index = allImages.firstIndex(where: { $0.id == imageID }) {
            allImages[index].isCopied = true
        }
    }
    
    // MARK: - Navigation
    
    func showResults() {
        isPromptFocused = false
        showingResults = true
        mode = .results
    }
    
    func openFullscreen(image: GeneratedImage) {
        if let index = visibleImages.firstIndex(where: { $0.id == image.id }) {
            fullscreenImageIndex = index
        }
    }

    func closeFullscreen() {
        fullscreenImageIndex = nil
    }

    func navigateToImage(index: Int) {
        guard index >= 0 && index < visibleImages.count else { return }
        fullscreenImageIndex = index
    }

    // MARK: - Mode Switching

    var isShowingMenu: Bool { mode == .menu }

    func toggleMenu() {
        if mode == .menu {
            closeMenu()
        } else {
            openMenu()
        }
    }

    func openMenu() {
        guard mode != .menu else { return }
        modeBeforeMenu = mode
        unfocusPrompt()
        mode = .menu
    }

    func closeMenu() {
        guard mode == .menu else { return }
        mode = modeBeforeMenu
        showingResults = (modeBeforeMenu == .results)
        if modeBeforeMenu == .composing {
            isPromptFocused = true
        }
    }

    /// Pull the latest credits / referral / double-credits state from the
    /// backend so the keyboard menu doesn't go stale when the user hasn't
    /// opened the main app for weeks (e.g. across a subscription renewal).
    func refreshFromBackend() async {
        do {
            let response = try await apiClient.me()
            KeyboardAccountSummary.applyMe(response)
            accountSummary = .load()
        } catch {
            HiLogger.error("Keyboard /api/me refresh failed", error: error, category: .keyboard)
        }
    }

    /// Open a hi-key:// URL via the host extensionContext. Closes the menu
    /// first so the keyboard isn't sitting in menu mode when the user comes
    /// back from the app.
    func openURL(_ url: URL) {
        closeMenu()
        guard let handler = openURLHandler else {
            HiLogger.error("openURL called without a handler", category: .keyboard)
            return
        }
        handler(url)
    }
}
