import Foundation

/// The origin of the page. It has to be https, except http on localhost, 127.0.0.1 or [::1] (the sandbox accepts those on any port).
/// The same rule as the registered origins in Hub.
struct PageOrigin: Equatable {
    let scheme: String
    let host: String
    let port: Int

    enum Failure: Error, CustomStringConvertible {
        case notAWebAddress(String)
        case notHttps

        var description: String {
            switch self {
            case .notAWebAddress(let value): return "HbEmbed: \"\(value)\" is not a web address."
            case .notHttps: return "HbEmbed: the page must be https (http is allowed only on localhost)."
            }
        }
    }

    init(_ url: URL) throws {
        guard let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased() else {
            throw Failure.notAWebAddress(url.absoluteString)
        }
        let local = ["localhost", "127.0.0.1", "::1"].contains(host)
        guard scheme == "https" || (scheme == "http" && local) else { throw Failure.notHttps }
        self.scheme = scheme
        self.host = host
        self.port = url.port ?? (scheme == "https" ? 443 : 80)
    }

    func matches(_ url: URL?) -> Bool {
        guard let url, let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased() else { return false }
        return scheme == self.scheme && host == self.host && (url.port ?? (scheme == "https" ? 443 : 80)) == port
    }

    func matches(scheme: String, host: String, port: Int) -> Bool {
        scheme.lowercased() == self.scheme && host.lowercased() == self.host && (port == 0 ? (scheme == "https" ? 443 : 80) : port) == self.port
    }
}
