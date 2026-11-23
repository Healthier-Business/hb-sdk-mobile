package uk.co.hbcompliance.hbembed

import android.net.Uri

/**
 * The origin of the page. It has to be https, except http on localhost, 127.0.0.1 or [::1] (the sandbox accepts those on any port).
 * The same rule as the registered origins in Hub.
 */
internal class PageOrigin private constructor(val scheme: String, val host: String, val port: Int) {

    /** The origin as `scheme://host[:port]`, the form `addWebMessageListener` takes. */
    val rule: String
        get() {
            val defaultPort = if (scheme == "https") 443 else 80
            return if (port == defaultPort) "$scheme://$host" else "$scheme://$host:$port"
        }

    fun matches(uri: Uri?): Boolean {
        val scheme = uri?.scheme?.lowercase() ?: return false
        val host = uri.host?.lowercase() ?: return false
        return scheme == this.scheme && host == this.host && portOf(scheme, uri.port) == port
    }

    companion object {
        private val LOCAL = setOf("localhost", "127.0.0.1", "[::1]", "::1")

        fun of(pageUrl: String): PageOrigin {
            val uri = Uri.parse(pageUrl)
            val scheme = uri.scheme?.lowercase()
            val host = uri.host?.lowercase()
            require(scheme != null && host != null) { "HbEmbed: \"$pageUrl\" is not a web address." }
            require(scheme == "https" || (scheme == "http" && host in LOCAL)) {
                "HbEmbed: the page must be https (http is allowed only on localhost)."
            }
            return PageOrigin(scheme, host, portOf(scheme, uri.port))
        }

        private fun portOf(scheme: String, port: Int): Int = if (port != -1) port else if (scheme == "https") 443 else 80
    }
}
