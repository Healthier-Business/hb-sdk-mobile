import SwiftUI
import WebKit

/// Lets your screen reload the page, which creates a new session. Use it after `session_expired`.
public final class HbEmbedController: ObservableObject {
    fileprivate weak var webView: WKWebView?

    public init() {}

    public func reload() {
        webView?.reload()
    }
}

/// A web view that shows the course or test page of your website and passes its events to your app.
///
/// It only trusts messages from the main page on the page's own origin, keeps the web view on that origin and opens other links in Safari.
/// The page must be on an origin registered under Developer > Embed in Hub, and the person must be signed in to your website before it opens.
public struct HbEmbedView: UIViewRepresentable {
    private let pageURL: URL
    private let origin: PageOrigin?
    private let controller: HbEmbedController?
    private let onEvent: (HbEvent) -> Void

    /// - Parameters:
    ///   - pageURL: for example `https://learn.example.com/mobile?kind=course`. It must be https (http is allowed only on localhost).
    ///   - controller: optional, to reload the page from your screen.
    ///   - onEvent: called on the main thread for every event the page sends.
    public init(pageURL: URL, controller: HbEmbedController? = nil, onEvent: @escaping (HbEvent) -> Void) {
        self.pageURL = pageURL
        self.origin = try? PageOrigin(pageURL)
        self.controller = controller
        self.onEvent = onEvent
        if origin == nil {
            assertionFailure("HbEmbed: the page must be https (http is allowed only on localhost).")
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(origin: origin, onEvent: onEvent)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // The page calls window.webkit.messageHandlers.hbEmbed.postMessage(json) for every event.
        configuration.userContentController.add(context.coordinator, name: "hbEmbed")
        // Course videos play inline and can go full screen.
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        controller?.webView = webView
        if origin != nil {
            webView.load(URLRequest(url: pageURL))
        }
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onEvent = onEvent
    }

    public static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "hbEmbed")
    }

    public final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let origin: PageOrigin?
        var onEvent: (HbEvent) -> Void

        init(origin: PageOrigin?, onEvent: @escaping (HbEvent) -> Void) {
            self.origin = origin
            self.onEvent = onEvent
        }

        public func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            // Only the main page of your origin: not the Hub frame inside it, and not another site.
            guard let origin, message.frameInfo.isMainFrame,
                  origin.matches(scheme: message.frameInfo.securityOrigin.protocol, host: message.frameInfo.securityOrigin.host, port: message.frameInfo.securityOrigin.port),
                  let event = HbEvent.parse(message.body)
            else { return }
            onEvent(event)
        }

        public func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // The frame is an iframe, so only the main page is checked. A link that leaves your page opens in Safari.
            guard action.targetFrame?.isMainFrame ?? true, let origin, let url = action.request.url, url.absoluteString != "about:blank", !origin.matches(url) else {
                decisionHandler(.allow)
                return
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}
