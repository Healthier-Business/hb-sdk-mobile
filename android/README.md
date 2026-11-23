# HbEmbed for Android

Shows a Healthier Business course or test in a native Android app (minSdk 24).

The frame can only open from a page of **your own website** on an origin you registered under Developer > Embed in Hub, so this library does not open the frame itself. It opens that page in a `WebView`, keeps the web view on your origin and gives your app the events the page sends. Read [Embedding in mobile apps](https://dev.hbcompliance.co.uk/sdk-embedding-mobile-apps) first: it explains the page and your server route.

Add the module to your project: copy the `hb-embed` folder, add `include(":hb-embed")` to `settings.gradle.kts` and `implementation(project(":hb-embed"))` to your app.

```kotlin
val embed = HbEmbedView(this)
container.addView(embed)
embed.onLoadError = { message -> /* show a retry button that calls embed.reload() */ }
embed.load("https://learn.example.com/mobile?kind=course") { event ->
    if (event.name == "completed") {
        // Ask your server for the result before you unlock anything.
    }
    if (event.name == "error" && event.data.optString("code") == "session_expired") {
        embed.reload() // a new session
    }
}
```

Call `embed.destroy()` in `onDestroy`, and `embed.handleBack()` from your back handler so the back button leaves full screen video first.

## What it does

- The page must be `https` (or `http` on localhost for the sandbox), otherwise `load` throws.
- Events arrive through `WebViewCompat.addWebMessageListener`, limited to your origin. It also says which frame sent the message, so only the main page counts and the Hub frame inside it cannot send one. This is why the library needs the `androidx.webkit` message listener. On a device whose web view is too old for it, no events are delivered and `onLoadError` says so; it does not fall back to `addJavascriptInterface`, which reaches every frame.
- Links that leave your origin open in the browser (or go to `onNavigationBlocked`).
- Video plays without a second tap and can go full screen. Downloads open in the browser.
- Events are hints. They can be forged by anything that runs script in the page, so read the result from your server before you grant anything.

## The page

Your page uses the browser SDK and calls `hbEmbed.postMessage` with the JSON text of each event. A complete page is `public/mobile.js` in [hb-sdk-examples](https://github.com/Healthier-Business/hb-sdk-examples).

## Try it in the emulator

Run the examples server, run `adb reverse tcp:3000 tcp:3000` and use `http://localhost:3000/mobile?kind=course`. A plain `http` address needs a network security config that allows clear text for `localhost` (debug builds only).
