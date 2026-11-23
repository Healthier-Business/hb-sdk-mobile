# hb_embed for Flutter

Shows a Healthier Business course or test in a Flutter app.

The frame can only open from a page of **your own website** on an origin you registered under Developer > Embed in Hub, so this package does not open the frame itself. It opens that page in a web view, keeps the web view on your origin and gives your app the events the page sends. Read [Embedding in mobile apps](https://dev.hbcompliance.co.uk/sdk-embedding-mobile-apps) first: it explains the page and your server route.

```yaml
dependencies:
  hb_embed:
    git:
      url: <the address of this repository>
      path: flutter
```

```dart
import 'package:hb_embed/hb_embed.dart';

final embed = HbEmbedController();

HbEmbed(
  pageUrl: 'https://learn.example.com/mobile?kind=course',
  controller: embed,
  onEvent: (event) {
    if (event.name == 'completed') {
      // Ask your server for the result before you unlock anything.
    }
    if (event.name == 'error' && event.data['code'] == 'session_expired') {
      embed.reload(); // a new session
    }
  },
)
```

## What it does

- `pageUrl` must be `https` (or `http` on localhost for the sandbox), otherwise it throws.
- Only well formed messages (`{ "name": "...", "data": {...} }`) reach `onEvent`.
- The web view never leaves your origin. A link to another site is not opened and is reported to `onNavigationBlocked`.
- Events are hints. They can be forged by anything that runs script in the page, so read the result from your server before you grant anything.
- `webview_flutter` does not tell which frame sent a message. Because the web view only shows your origin, the only frame that can send one is your page or the Hub frame inside it. Keep the page from loading anything else.

## The page

Your page uses the browser SDK and calls `hbEmbed.postMessage` with the JSON text of each event. A complete page is `public/mobile.js` in [hb-sdk-examples](https://github.com/Healthier-Business/hb-sdk-examples).

## Try it in a simulator

Run the examples server and use `http://localhost:3000/mobile?kind=course`. On the Android emulator run `adb reverse tcp:3000 tcp:3000` first. Android also needs `<uses-permission android:name="android.permission.INTERNET" />`, and a plain `http` address needs a network security config that allows clear text for localhost (debug builds only). iOS needs an App Transport Security exception for localhost.
