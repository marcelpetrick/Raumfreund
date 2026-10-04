// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import io.flutter.plugin.common.EventChannel

/**
 * Stream handler of the levels event channel. Must only be used on the main
 * thread. Without a Dart listener events are dropped; the session keeps
 * running until Dart calls stopLevels or the activity stops.
 */
class LevelEventSink : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink,
    ) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    /** Sends one RMS reading of [sessionId]. */
    fun reading(
        sessionId: Long,
        dbfs: Double,
    ) {
        sink?.success(mapOf("sessionId" to sessionId, "dbfs" to dbfs))
    }

    /** Sends the failure that ended [sessionId]. */
    fun failure(
        sessionId: Long,
        failure: LevelFailure,
    ) {
        sink?.success(mapOf("sessionId" to sessionId, "error" to failure.code))
    }
}
