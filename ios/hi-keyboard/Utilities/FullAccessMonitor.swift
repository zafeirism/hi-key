import Foundation
import Combine

// MARK: - Full Access Monitor
// Mirrors `NetworkMonitor`'s shape for the Full Access permission. The
// keyboard extension itself is the only place that knows the truthful
// answer (via `UIInputViewController.hasFullAccess`); this monitor just
// republishes that value as observable state and animates a brief
// "Full access enabled" flash on a no-access → access transition, so the
// suggestion bar can react the same way it does for connectivity.
//
// `KeyboardViewController` is responsible for pushing updates into this
// monitor on `viewDidLoad` and `viewWillAppear` — `hasFullAccess` is not
// observable, so checking on each view-show covers the user toggling the
// setting in iOS Settings and returning to the keyboard.

@MainActor
final class FullAccessMonitor: ObservableObject {
    static let shared = FullAccessMonitor()

    @Published private(set) var hasFullAccess: Bool = true
    @Published private(set) var showJustEnabled: Bool = false

    private var enabledTask: Task<Void, Never>?

    private static let enabledDuration: TimeInterval = 1.5

    private init() {}

    func update(_ value: Bool) {
        guard value != hasFullAccess else { return }

        if value {
            hasFullAccess = true
            triggerJustEnabled()
        } else {
            enabledTask?.cancel()
            enabledTask = nil
            showJustEnabled = false
            hasFullAccess = false
        }
    }

    private func triggerJustEnabled() {
        enabledTask?.cancel()
        showJustEnabled = true
        enabledTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.enabledDuration * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            self.showJustEnabled = false
        }
    }
}
