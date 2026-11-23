# HbEmbed for iOS

Shows a Healthier Business course or test in a native iOS app (SwiftUI, iOS 15 or newer).

The frame can only open from a page of **your own website** on an origin you registered under Developer > Embed in Hub, so this package does not open the frame itself. It opens that page in a `WKWebView`, keeps the web view on your origin and gives your app the events the page sends. Read [Embedding in mobile apps](https://dev.hbcompliance.co.uk/sdk-embedding-mobile-apps) first: it explains the page and your server route.

Add the package in Xcode (File > Add Package Dependencies) with the address of this repository and the folder `ios`, or put the folder in your project as a local package.

```swift
import HbEmbed
import SwiftUI

struct CourseScreen: View {
    @StateObject private var embed = HbEmbedController()

    var body: some View {
        HbEmbedView(pageURL: URL(string: "https://learn.example.com/mobile?kind=course")!, controller: embed) { event in
            if event.name == "completed" {
                // Ask your server for the result before you unlock anything.
            }
            if event.name == "error", event.data["code"] as? String == "session_expired" {
                embed.reload() // a new session
            }
        }
    }
}
```

## What it does

- `pageURL` must be `https` (or `http` on localhost for the sandbox).
- Only messages from the main page on your origin reach `onEvent`, and only well formed ones (`{ "name": "...", "data": {...} }`). The Hub frame inside the page cannot send one.
- Links that leave your origin open in Safari, so the web view never shows another site.
- Video plays inline and can go full screen.
- Events are hints. They can be forged by anything that runs script in the page, so read the result from your server before you grant anything.

## The page

Your page uses the browser SDK and calls `window.webkit.messageHandlers.hbEmbed.postMessage` with the JSON text of each event. A complete page is `public/mobile.js` in [hb-sdk-examples](https://github.com/Healthier-Business/hb-sdk-examples).

## Try it in the simulator

Run the examples server and use `http://localhost:3000/mobile?kind=course`. A plain `http` address needs an App Transport Security exception for `localhost` in a debug build.
