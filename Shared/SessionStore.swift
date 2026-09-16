import Foundation
import Observation

/// Single source of truth. Used by the app UI and by the Live Activity intents
/// (which the system runs inside the app's process).
///
/// Persistence: two small JSON files in the app's Documents directory.
/// Every change is written to disk immediately, then the Live Activity is updated.
@MainActor
@Observable
final class SessionStore {
    static let shared = SessionStore()

    private(set) var active: ActiveSession?
    private(set) var history: [CompletedSession] = []
    /// Set when a session ends so the app can show the summary screen. Not persisted.
    var lastCompleted: CompletedSession?

    private let activeURL: URL
    private let historyURL: URL

    private init() {
        let dir = URL.documentsDirectory
        activeURL = dir.appending(path: "active-session.json")
        historyURL = dir.appending(path: "history.json")
        load()
    }

    // MARK: - Actions

    func startSession() async {
        guard active == nil else { return }
        let session = ActiveSession()
        active = session
        saveActive()
        await LiveActivityManager.start(session)
    }

    func switchTo(_ state: SessionState) async {
        guard var session = active else { return }
        session.switchTo(state)
        active = session
        saveActive()
        await LiveActivityManager.update(session)
    }

    func endSession() async {
        guard let session = active else { return }
        let completed = session.finish()
        history.insert(completed, at: 0)
        active = nil
        lastCompleted = completed
        saveActive()
        saveHistory()
        await LiveActivityManager.end()
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    /// Re-read disk and make sure the Live Activity matches. Called when the app becomes active.
    func refresh() async {
        load()
        await LiveActivityManager.reconcile(with: active)
    }

    // MARK: - Persistence

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: activeURL) {
            active = try? decoder.decode(ActiveSession.self, from: data)
        } else {
            active = nil
        }
        if let data = try? Data(contentsOf: historyURL),
           let saved = try? decoder.decode([CompletedSession].self, from: data) {
            history = saved
        }
    }

    private func saveActive() {
        if let active {
            write(active, to: activeURL)
        } else {
            try? FileManager.default.removeItem(at: activeURL)
        }
    }

    private func saveHistory() {
        write(history, to: historyURL)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            try encoder.encode(value).write(to: url, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }
}
