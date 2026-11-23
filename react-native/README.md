# @healthier-business/hub-sdk-react-native

Shows a Healthier Business course or test in a React Native app.

The frame can only open from a page of **your own website** on an origin you registered under Developer > Embed in Hub, so this package does not open the frame itself. It opens that page in a web view, keeps the web view on your origin and gives your app the events the page sends. Read [Embedding in mobile apps](https://dev.hbcompliance.co.uk/sdk-embedding-mobile-apps) first: it explains the page and your server route.

```bash
npm install @healthier-business/hub-sdk-react-native react-native-webview
```

```tsx
import { HbEmbed, type HbEmbedHandle } from '@healthier-business/hub-sdk-react-native';

export function CourseScreen() {
  const embed = useRef<HbEmbedHandle>(null);

  return (
    <HbEmbed
      ref={embed}
      pageUrl="https://learn.example.com/mobile?kind=course"
      onEvent={({ name, data }) => {
        if (name === 'completed') {
          // Ask your server for the result before you unlock anything.
        }
        if (name === 'error' && data.code === 'session_expired') {
          embed.current?.reload(); // a new session
        }
      }}
    />
  );
}
```

## What it does

- `pageUrl` must be `https` (or `http` on localhost for the sandbox), otherwise it throws.
- Only messages from the page's own origin reach `onEvent`, and only well formed ones (`{ "name": "...", "data": {...} }`).
- Links that leave your origin open in the system browser, so the web view never shows another site.
- Video plays inline and can go full screen, and the web view keeps cookies and storage.
- Events are hints. They can be forged by anything that runs script in the page, so read the result from your server before you grant anything.

## The page

Your page uses the browser SDK and calls `window.ReactNativeWebView.postMessage` with the JSON text of each event. A complete page is `public/mobile.js` in [hb-sdk-examples](https://github.com/Healthier-Business/hb-sdk-examples).

## Try it in a simulator

Run the examples server and use `http://localhost:3000/mobile?kind=course`. On the Android emulator run `adb reverse tcp:3000 tcp:3000` first. A real phone needs your page on a registered `https` address.
