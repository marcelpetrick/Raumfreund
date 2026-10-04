// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

/** Arguments of `playAlarm`. */
data class AlarmRequest(
    val sound: Boolean,
    val vibrate: Boolean,
)

/**
 * Parses method channel arguments. Returns null for malformed input instead of
 * throwing, so the caller can answer with [ErrorCodes.INVALID_ARGUMENTS].
 */
object ChannelArguments {
    /** `{"sessionId": int}`; Dart ints arrive as Int or Long depending on size. */
    fun sessionId(arguments: Any?): Long? =
        when (val value = (arguments as? Map<*, *>)?.get("sessionId")) {
            is Int -> value.toLong()
            is Long -> value
            else -> null
        }

    /** `{"sound": bool, "vibrate": bool}`. */
    fun alarmRequest(arguments: Any?): AlarmRequest? {
        val map = arguments as? Map<*, *> ?: return null
        val sound = map["sound"] as? Boolean ?: return null
        val vibrate = map["vibrate"] as? Boolean ?: return null
        return AlarmRequest(sound = sound, vibrate = vibrate)
    }

    /** `{"enabled": bool}`. */
    fun keepScreenOn(arguments: Any?): Boolean? = (arguments as? Map<*, *>)?.get("enabled") as? Boolean
}
