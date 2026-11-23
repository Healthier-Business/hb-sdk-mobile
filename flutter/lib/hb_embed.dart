import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'hb_event.dart';

export 'hb_event.dart';

/// Lets your screen reload the page, which creates a new session. Use it after `session_expired`.
class HbEmbedController {
  WebViewController? _web;

  Future<void> reload() async => _web?.reload();
}

/// A web view that shows the course or test page of your website and passes its events to your app.
///
/// The page must be on an origin registered under Developer > Embed in Hub, and the person must be signed in to your website before it
/// opens. The web view stays on that origin: a link that leaves it is not opened. [onNavigationBlocked] tells you which address it was, so
/// your app can open it in the browser if it wants.
class HbEmbed extends StatefulWidget {
  /// For example `https://learn.example.com/mobile?kind=course`. It must be https (http is allowed only on localhost).
  final String pageUrl;

  /// Called for every event the page sends.
  final void Function(HbEvent event) onEvent;

  final HbEmbedController? controller;

  /// Called with the address of a link that leaves your origin.
  final void Function(Uri url)? onNavigationBlocked;

  /// Called when the page could not be loaded (no network, a server error).
  final void Function(String message)? onLoadError;

  HbEmbed({
    super.key,
    required this.pageUrl,
    required this.onEvent,
    this.controller,
    this.onNavigationBlocked,
    this.onLoadError,
  }) {
    _checkPage(Uri.parse(pageUrl));
  }

  /// The page has to be https, except http on localhost, 127.0.0.1 or [::1]. The same rule as the registered origins in Hub.
  static void _checkPage(Uri page) {
    final local = const ['localhost', '127.0.0.1', '::1'].contains(page.host);
    if (!(page.scheme == 'https' || (page.scheme == 'http' && local))) {
      throw ArgumentError('HbEmbed: the page must be https (http is allowed only on localhost).');
    }
  }

  @override
  State<HbEmbed> createState() => _HbEmbedState();
}

class _HbEmbedState extends State<HbEmbed> {
  late final WebViewController _web;
  late final Uri _page;

  @override
  void initState() {
    super.initState();
    _page = Uri.parse(widget.pageUrl);

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // The page calls hbEmbed.postMessage(json) for every event. This channel does not say which frame sent a message, so the web view
      // only ever shows your origin (see the navigation rule below) and the message is checked for its shape.
      ..addJavaScriptChannel('hbEmbed', onMessageReceived: (message) {
        final event = HbEvent.parse(message.message);
        if (event != null) {
          widget.onEvent(event);
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          // The frame is an iframe, so only the main page is checked.
          if (!request.isMainFrame) {
            return NavigationDecision.navigate;
          }
          final url = Uri.tryParse(request.url);
          if (url != null && (request.url == 'about:blank' || _sameOrigin(url))) {
            return NavigationDecision.navigate;
          }
          if (url != null) {
            widget.onNavigationBlocked?.call(url);
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) {
            widget.onLoadError?.call(error.description);
          }
        },
        onHttpError: (error) => widget.onLoadError?.call('HTTP ${error.response?.statusCode ?? ''}'.trim()),
      ))
      ..loadRequest(_page);

    widget.controller?._web = _web;
  }

  bool _sameOrigin(Uri url) =>
      url.scheme == _page.scheme && url.host == _page.host && url.port == _page.port;

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _web);
}
