import Foundation

/// One event the page passes to the app. `data` is what the frame sent, as plain JSON.
public struct HbEvent {
    /// `ready`, `progress`, `completed`, `passed`, `failed`, `submitted`, `terms-accepted` or `error`. A page may send others.
    public let name: String
    public let data: [String: Any]

    /// The events that finish a session. Read the result from your server before you grant anything.
    public static let finalNames: Set<String> = ["completed", "passed", "failed", "submitted"]

    public var isFinal: Bool { Self.finalNames.contains(name) }

    /// Reads the text the page sent. Returns nil for anything that is not `{"name": "...", "data": {...}}`, so a stray message never reaches your app.
    static func parse(_ body: Any) -> HbEvent? {
        guard let text = body as? String, text.utf8.count <= 20_000,
              let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any],
              let name = object["name"] as? String, !name.isEmpty, name.count <= 64
        else { return nil }
        return HbEvent(name: name, data: object["data"] as? [String: Any] ?? [:])
    }
}
