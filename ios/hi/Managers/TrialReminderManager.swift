import Foundation
import Combine
import UserNotifications

/// Owns the local-notification reminder fired before a free trial ends.
/// Preference is persisted to app-group defaults so the picker remembers
/// across paywall opens. Permission is requested only after a successful
/// trial purchase, so we don't add a system prompt to the paywall flow.
@MainActor
final class TrialReminderManager: ObservableObject {
    static let shared = TrialReminderManager()

    enum Lead: Int, CaseIterable, Identifiable {
        case none = 0
        case oneDay = 1
        case twoDays = 2

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .none: return "No reminder"
            case .oneDay: return "1 day before"
            case .twoDays: return "2 days before"
            }
        }

        var leadDays: Int? {
            switch self {
            case .none: return nil
            case .oneDay: return 1
            case .twoDays: return 2
            }
        }
    }

    // MARK: - Published State

    @Published var preference: Lead {
        didSet { persistPreference() }
    }

    // MARK: - Constants

    private static let appGroupID = "group.ai.hi-key"
    private static let preferenceKey = "trialReminderPreference"
    private static let notificationIdentifier = "trial.end.reminder"
    /// Fire at 18:00 local time on the chosen day. Late enough that the
    /// user is off work, early enough to act before the next morning.
    private static let fireHourLocal = 18

    // MARK: - Init

    private init() {
        let stored = UserDefaults(suiteName: Self.appGroupID)?.object(forKey: Self.preferenceKey) as? Int
        if let stored, let lead = Lead(rawValue: stored) {
            self.preference = lead
        } else {
            self.preference = .twoDays
        }
    }

    private func persistPreference() {
        UserDefaults(suiteName: Self.appGroupID)?.set(preference.rawValue, forKey: Self.preferenceKey)
    }

    // MARK: - Schedule / Cancel

    /// Call after a successful purchase of a trial-eligible product. Requests
    /// notification permission if not yet determined; if granted (or already
    /// authorized), schedules a single local notification. Silently no-ops if
    /// permission is denied or the user picked `.none`.
    func requestPermissionAndSchedule(trialExpiration: Date) async {
        guard let leadDays = preference.leadDays else { return }
        guard let fireDate = fireDate(forExpiration: trialExpiration, leadDays: leadDays) else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
        case .denied:
            return
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            return
        }

        await scheduleNotification(at: fireDate)
    }

    /// Removes any pending trial-end reminder. Called when the active
    /// subscription disappears (cancel/refund/expiry) so the notification
    /// doesn't fire with stale copy.
    func cancelPendingReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
    }

    // MARK: - Helpers

    private func fireDate(forExpiration expiration: Date, leadDays: Int) -> Date? {
        let calendar = Calendar.current
        guard let candidateDay = calendar.date(byAdding: .day, value: -leadDays, to: expiration) else { return nil }
        var components = calendar.dateComponents([.year, .month, .day], from: candidateDay)
        components.hour = Self.fireHourLocal
        components.minute = 0
        guard let fireDate = calendar.date(from: components) else { return nil }
        // If the computed fire time is already in the past (short trial,
        // late purchase), skip — Apple's own trial-end notification still
        // fires, and a local notification scheduled in the past won't.
        guard fireDate > Date() else { return nil }
        return fireDate
    }

    private func scheduleNotification(at fireDate: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Your hi-key trial is ending soon"
        content.body = "Your free trial wraps up soon — keep your subscription or cancel anytime in Settings."
        content.sound = .default

        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Replace any previously scheduled reminder before adding a new one,
        // so re-scheduling (e.g. on restore) doesn't stack notifications.
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            HiLogger.error("Failed to schedule trial-end reminder", error: error)
        }
    }
}
