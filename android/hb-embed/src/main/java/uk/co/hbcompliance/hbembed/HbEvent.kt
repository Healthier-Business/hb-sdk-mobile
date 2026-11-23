package uk.co.hbcompliance.hbembed

import org.json.JSONObject

/**
 * One event the page passes to the app. [data] is what the frame sent, as JSON.
 *
 * [name] is `ready`, `progress`, `completed`, `passed`, `failed`, `submitted`, `terms-accepted` or `error`. A page may send others.
 */
data class HbEvent(val name: String, val data: JSONObject) {
    /** The events that finish a session. Read the result from your server before you grant anything. */
    val isFinal: Boolean get() = name in FINAL_NAMES

    companion object {
        val FINAL_NAMES = setOf("completed", "passed", "failed", "submitted")

        /**
         * Reads the text the page sent. Returns null for anything that is not `{"name": "...", "data": {...}}`,
         * so a stray message never reaches your app.
         */
        fun parse(text: String?): HbEvent? {
            if (text == null || text.length > 20_000) {
                return null
            }
            return try {
                val json = JSONObject(text)
                val name = json.optString("name", "")
                if (name.isEmpty() || name.length > 64) {
                    null
                } else {
                    HbEvent(name, json.optJSONObject("data") ?: JSONObject())
                }
            } catch (_: Exception) {
                null
            }
        }
    }
}
