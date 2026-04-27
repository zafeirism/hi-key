import SwiftUI
import Combine

// MARK: - Deep Link Router
// Receives `hi-key://` URLs (from the keyboard extension or external sources)
// and exposes a single `pendingRoute` for the UI to consume. The router only
// navigates — it never grants credits, mutates auth, or applies codes, since
// custom URL schemes are public and any app can invoke them.

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    private init() {}

    enum Route: Equatable {
        case openApp
        case buyCredits
        case referral
    }

    @Published var pendingRoute: Route?

    /// Parse an incoming URL into a route. Unknown hosts fall back to `.openApp`
    /// so a stale or malformed link still lands the user somewhere sensible.
    func handle(_ url: URL) {
        guard url.scheme == "hi-key" else { return }

        let route: Route
        switch url.host {
        case nil, "":
            route = .openApp
        case "buy-credits":
            route = .buyCredits
        case "referral":
            route = .referral
        default:
            HiLogger.warning("Unknown deep-link host: \(url.host ?? "nil")")
            route = .openApp
        }

        pendingRoute = route
    }

    /// Clear the route after the destination view has reacted to it.
    func consume() {
        pendingRoute = nil
    }
}
