// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

/*
 * Narrow interfaces used by ControlChannelHandler. They keep the dispatch
 * logic testable on the JVM without Android framework classes. All methods
 * are called on the main thread.
 */

/** Microphone permission handling. */
interface PermissionControl {
    /** Current status without showing UI. */
    fun status(): PermissionStatus

    /**
     * Shows the system dialog (if not granted) and calls [onResult] exactly
     * once. Returns false without calling [onResult] while another request runs.
     */
    fun request(onResult: (PermissionStatus) -> Unit): Boolean

    /** Opens the app details settings page; false if no activity handles it. */
    fun openAppSettings(): Boolean
}

/** Level measurement sessions. */
interface LevelControl {
    /** Starts [sessionId]; returns null once recording runs, else the failure. */
    fun start(sessionId: Long): LevelFailure?

    /** Stops the running session (idempotent, no event). */
    fun stop()
}

/** Alarm output. */
interface AlarmControl {
    /** Plays [request]; [onDone] runs on the main thread after the output ended. */
    fun play(
        request: AlarmRequest,
        onDone: (success: Boolean) -> Unit,
    )
}

/** Keep-screen-on flag of the activity window. */
fun interface ScreenControl {
    /** Adds or clears the flag. */
    fun setKeepScreenOn(enabled: Boolean)
}

/** Version information of the installed package. */
fun interface AppInfoSource {
    /** `{"versionName": String, "versionCode": Long}`. */
    fun read(): Map<String, Any>
}
