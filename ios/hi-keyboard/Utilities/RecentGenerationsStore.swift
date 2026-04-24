import Foundation

struct StoredImage: Codable {
    let id: String
    let url: String
    var loadedAt: Date?
}

struct StoredGeneration: Codable {
    let prompt: String
    let generatedAt: Date
    var images: [StoredImage]
}

enum RecentGenerationsStore {
    private static let appGroupID = "group.ai.hi-key"
    private static let key = "keyboard.recentGenerations.v1"
    private static let maxGenerations = 2
    private static let ttl: TimeInterval = 60 * 60  // 1 hour

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Returns generations that are still within the TTL window, oldest first.
    static func loadValid(now: Date = Date()) -> [StoredGeneration] {
        guard let data = defaults?.data(forKey: key),
              let all = try? JSONDecoder().decode([StoredGeneration].self, from: data)
        else { return [] }

        let valid = all.filter { now.timeIntervalSince($0.generatedAt) < ttl }
        return valid.sorted { $0.generatedAt < $1.generatedAt }
    }

    /// Appends a generation, trims to the most recent `maxGenerations`, drops expired entries, and persists.
    static func append(_ generation: StoredGeneration, now: Date = Date()) {
        var kept = loadValid(now: now)
        kept.append(generation)
        if kept.count > maxGenerations {
            kept.removeFirst(kept.count - maxGenerations)
        }
        guard let data = try? JSONEncoder().encode(kept) else { return }
        defaults?.set(data, forKey: key)
    }

    /// Records the first-reveal time for an image so the original order is
    /// preserved across sessions. No-op if the image already has a loadedAt
    /// (we never overwrite, so restored images keep their original reveal
    /// order even after they re-load in a later session).
    static func updateLoadedAt(imageID: String, loadedAt: Date, now: Date = Date()) {
        var generations = loadValid(now: now)
        for i in 0..<generations.count {
            guard let imgIdx = generations[i].images.firstIndex(where: { $0.id == imageID })
            else { continue }
            guard generations[i].images[imgIdx].loadedAt == nil else { return }
            generations[i].images[imgIdx].loadedAt = loadedAt
            guard let data = try? JSONEncoder().encode(generations) else { return }
            defaults?.set(data, forKey: key)
            return
        }
    }

    static func clear() {
        defaults?.removeObject(forKey: key)
    }
}
