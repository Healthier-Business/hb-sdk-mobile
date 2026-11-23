package uk.co.hbcompliance.hbembed

import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.AttributeSet
import android.view.View
import android.view.ViewGroup
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import androidx.webkit.WebMessageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature

/**
 * A view that shows the course or test page of your website and passes its events to your app.
 *
 * The page must be on an origin registered under Developer > Embed in Hub, and the person must be signed in to your website before it opens.
 * Only messages from the main page on that origin reach [onEvent]. The web view stays on that origin, and links that leave it open in the
 * browser (or go to [onNavigationBlocked]).
 *
 * ```kotlin
 * val embed = HbEmbedView(this)
 * container.addView(embed)
 * embed.load("https://learn.example.com/mobile?kind=course", onEvent = { event ->
 *     if (event.name == "completed") { /* ask your server for the result */ }
 * })
 * ```
 */
@SuppressLint("SetJavaScriptEnabled")
class HbEmbedView @JvmOverloads constructor(context: Context, attrs: AttributeSet? = null) : FrameLayout(context, attrs) {

    private val web = WebView(context)
    private var fullScreen: View? = null
    private var fullScreenCallback: WebChromeClient.CustomViewCallback? = null

    /**
     * Called when the page could not be loaded, and when this device's web view is too old to receive events safely.
     * Returns the text of the problem.
     */
    var onLoadError: ((String) -> Unit)? = null

    /** Called with the address of a link that leaves your origin. When it is null the link opens in the browser. */
    var onNavigationBlocked: ((Uri) -> Unit)? = null

    init {
        addView(web, LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    }

    /**
     * Opens the page.
     *
     * @param pageUrl for example `https://learn.example.com/mobile?kind=course`. It must be https (http is allowed only on localhost).
     * @param onEvent called on the main thread for every event the page sends.
     * @throws IllegalArgumentException when the page is not https
     */
    fun load(pageUrl: String, onEvent: (HbEvent) -> Unit) {
        val origin = PageOrigin.of(pageUrl)

        web.settings.javaScriptEnabled = true
        web.settings.domStorageEnabled = true
        // Course videos play without a second tap.
        web.settings.mediaPlaybackRequiresUserGesture = false
        web.settings.setSupportMultipleWindows(false)
        web.settings.allowFileAccess = false
        web.settings.allowContentAccess = false

        // The page calls hbEmbed.postMessage(json). The listener is added only for your origin, and it also says which frame sent the message,
        // so the Hub frame inside the page cannot send one. (addJavascriptInterface would reach every frame, so it is not used.)
        if (WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)) {
            WebViewCompat.addWebMessageListener(web, "hbEmbed", setOf(origin.rule)) { _, message: WebMessageCompat, sourceOrigin: Uri, isMainFrame: Boolean, _ ->
                if (isMainFrame && origin.matches(sourceOrigin)) {
                    HbEvent.parse(message.data)?.let(onEvent)
                }
            }
        } else {
            onLoadError?.invoke("This device's web view is too old to receive events. Update Android System WebView.")
        }

        web.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                // The frame is an iframe, so only the main page is checked.
                if (!request.isForMainFrame || origin.matches(request.url)) {
                    return false
                }
                val blocked = onNavigationBlocked
                if (blocked != null) {
                    blocked(request.url)
                } else {
                    try {
                        context.startActivity(Intent(Intent.ACTION_VIEW, request.url).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    } catch (_: ActivityNotFoundException) {
                        // No app can open it.
                    }
                }
                return true
            }

            override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
                if (request.isForMainFrame) {
                    onLoadError?.invoke(error.description.toString())
                }
            }

            override fun onReceivedHttpError(view: WebView, request: WebResourceRequest, errorResponse: WebResourceResponse) {
                if (request.isForMainFrame) {
                    onLoadError?.invoke("HTTP ${errorResponse.statusCode}")
                }
            }
        }

        // Full screen video: the player asks for a view to show over the whole screen.
        web.webChromeClient = object : WebChromeClient() {
            override fun onShowCustomView(view: View, callback: CustomViewCallback) {
                fullScreen = view
                fullScreenCallback = callback
                web.visibility = View.GONE
                addView(view, LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
            }

            override fun onHideCustomView() {
                fullScreen?.let { removeView(it) }
                fullScreen = null
                fullScreenCallback?.onCustomViewHidden()
                fullScreenCallback = null
                web.visibility = View.VISIBLE
            }
        }

        // Certificates and other downloads open in the browser, which can handle them.
        web.setDownloadListener { url, _, _, _, _ ->
            try {
                context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            } catch (_: ActivityNotFoundException) {
                // No app can open it.
            }
        }

        web.loadUrl(pageUrl)
    }

    /** Loads the page again, which creates a new session. Use it after `session_expired`. */
    fun reload() {
        web.reload()
    }

    /** Lets the back button leave full screen video first. Returns true when it did. */
    fun handleBack(): Boolean {
        if (fullScreen != null) {
            web.webChromeClient?.onHideCustomView()
            return true
        }
        return false
    }

    /** Call from the activity's `onDestroy` (or when the view is removed for good). */
    fun destroy() {
        removeAllViews()
        web.destroy()
    }
}
