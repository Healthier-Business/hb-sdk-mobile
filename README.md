# Healthier Business Hub SDK for mobile apps

One small package for each of four platforms. Each shows a Healthier Business course or test in your app, and gives your app the events (`ready`, `progress`, `completed`, `passed`, `failed`, `submitted`, `error`).

| Platform | Folder | Web view | Checked |
| --- | --- | --- | --- |
| React Native | [react-native](react-native) | `react-native-webview` | type-checked |
| Flutter | [flutter](flutter) | `webview_flutter` | `flutter analyze`, no issues |
| iOS (SwiftUI) | [ios](ios) | `WKWebView` | builds for the iOS simulator |
| Android (Kotlin) | [android](android) | `WebView` | **not built** (no Android SDK on the machine that wrote it) |

None of them has been run on a device yet.

## How it works

The frame is a page of the Hub. It only opens from a page of **your own website** on an origin you registered under Developer > Embed in Hub, with the browser SDK of the Hub. So these packages do not open the frame themselves. They do the app half:

```
your app (HbEmbed)  -->  your page /mobile  -->  your server route (API key)  -->  Hub
        ^                      |
        +--- events through the bridge of the platform ---+
```

1. The app opens the page of your website in a web view, signed in to your website.
2. The page uses the browser SDK to mount the frame and sends each event to the app (`hbEmbed.postMessage`, `window.ReactNativeWebView.postMessage` or the iOS message handler).
3. The package passes only well formed messages from your own origin to your code, keeps the web view on that origin and opens other links in the system browser.
4. When a final event arrives (`completed`, `passed`, `failed`, `submitted`), your app asks **your server** for the result before it grants anything. Events can be forged by anything that runs script in the page.

Read [Embedding in mobile apps](https://dev.hbcompliance.co.uk/sdk-embedding-mobile-apps) for the page, your server route and what to check on a device. A complete page and server are in [hb-sdk-examples](https://github.com/Healthier-Business/hb-sdk-examples) (`/mobile`).

## What the packages do not do

- They do not open the frame without your page, and they do not hold an API key. Nothing here changes how Hub checks access.
- They do not sign the person in. Your app signs the web view in to your website (a session cookie, or a short-lived single-use link from your server).

## License

MIT
