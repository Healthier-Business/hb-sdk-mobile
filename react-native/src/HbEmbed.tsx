import React, { forwardRef, useCallback, useImperativeHandle, useMemo, useRef } from 'react';
import { ActivityIndicator, Linking, View, type StyleProp, type ViewStyle } from 'react-native';
import { WebView, type WebViewMessageEvent } from 'react-native-webview';
import type { ShouldStartLoadRequest } from 'react-native-webview/lib/WebViewTypes';
import { parseHbEvent, type HbEvent } from './events';
import { pageOrigin, sameOrigin } from './url';

export type HbEmbedProps = {
  /**
   * The address of the page on your website that mounts the frame, for example `https://learn.example.com/mobile?kind=course`.
   * It must be on an origin registered under Developer > Embed in Hub. Sign the person in to your website before it opens.
   */
  pageUrl: string;
  /** Called for every event the page sends. */
  onEvent: (event: HbEvent) => void;
  /** Called when the page could not be loaded (no network, a server error). */
  onLoadError?: (message: string) => void;
  style?: StyleProp<ViewStyle>;
};

export type HbEmbedHandle = {
  /** Loads the page again, which creates a new session. Use it after `session_expired`. */
  reload: () => void;
};

/**
 * A web view that shows the course or test page of your website and passes its events to your app.
 * It only trusts messages from the page's own origin, keeps the web view on that origin and opens other links in the system browser.
 */
export const HbEmbed = forwardRef<HbEmbedHandle, HbEmbedProps>(function HbEmbed({ pageUrl, onEvent, onLoadError, style }, ref) {
  const origin = useMemo(() => pageOrigin(pageUrl), [pageUrl]);
  const web = useRef<WebView>(null);

  useImperativeHandle(ref, () => ({ reload: () => web.current?.reload() }), []);

  const onMessage = useCallback(
    (message: WebViewMessageEvent) => {
      // `url` is the address of the page that sent the message.
      if (!sameOrigin(message.nativeEvent.url, origin)) {
        return;
      }
      const event = parseHbEvent(message.nativeEvent.data);
      if (event !== null) {
        onEvent(event);
      }
    },
    [origin, onEvent],
  );

  const onShouldStartLoad = useCallback(
    (request: ShouldStartLoadRequest) => {
      // The frame is an iframe, so only the main page is checked. A link that leaves your page opens in the system browser.
      if (request.isTopFrame === false || sameOrigin(request.url, origin) || request.url === 'about:blank') {
        return true;
      }
      void Linking.openURL(request.url);
      return false;
    },
    [origin],
  );

  return (
    <View style={[{ flex: 1 }, style]}>
      <WebView
        ref={web}
        source={{ uri: pageUrl }}
        onMessage={onMessage}
        onShouldStartLoadWithRequest={onShouldStartLoad}
        onError={(e) => onLoadError?.(e.nativeEvent.description)}
        onHttpError={(e) => onLoadError?.(`HTTP ${e.nativeEvent.statusCode}`)}
        javaScriptEnabled
        domStorageEnabled
        thirdPartyCookiesEnabled
        sharedCookiesEnabled
        allowsInlineMediaPlayback
        allowsFullscreenVideo
        mediaPlaybackRequiresUserAction={false}
        setSupportMultipleWindows={false}
        startInLoadingState
        renderLoading={() => <ActivityIndicator style={{ flex: 1 }} />}
      />
    </View>
  );
});
