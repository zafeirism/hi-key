import Foundation
import Network
import Combine

// MARK: - Network Monitor
// Lightweight reachability for the keyboard extension. Uses NWPathMonitor so
// we react to connectivity changes immediately rather than discovering them
// only after a failed request. Exposes two pieces of state:
//   - `isOnline` — current connectivity, drives the offline indicator and
//     the action handler's CTA gating.
//   - `showBackOnline` — true for ~1.5s after a true offline → online
//     transition, so the suggestion bar can flash a "Back online" check
//     before snapping back to suggestions.

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isOnline: Bool = true
    @Published private(set) var showBackOnline: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ai.hi-key.network-monitor")
    private var backOnlineTask: Task<Void, Never>?

    private static let backOnlineDuration: TimeInterval = 1.5

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(isOnline: online)
            }
        }
        monitor.start(queue: queue)
    }

    private func handlePathUpdate(isOnline newValue: Bool) {
        let wasOnline = isOnline
        guard newValue != wasOnline else { return }

        if newValue {
            isOnline = true
            triggerBackOnline()
        } else {
            backOnlineTask?.cancel()
            backOnlineTask = nil
            showBackOnline = false
            isOnline = false
        }
    }

    private func triggerBackOnline() {
        backOnlineTask?.cancel()
        showBackOnline = true
        backOnlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.backOnlineDuration * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            self.showBackOnline = false
        }
    }
}
