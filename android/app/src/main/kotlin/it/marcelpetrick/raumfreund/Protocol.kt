// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

/**
 * Names and wire values of the platform channel protocol.
 * Source of truth: docs/platform-channels.md (mirrored in lib/core/platform_channels.dart).
 */
object ChannelNames {
    /** Method channel for all commands. */
    const val CONTROL = "it.marcelpetrick.raumfreund/control"

    /** Event channel delivering level readings and session failures. */
    const val LEVELS = "it.marcelpetrick.raumfreund/levels"
}

/** Method names of the control channel. */
object Methods {
    const val PERMISSION_STATUS = "permissionStatus"
    const val REQUEST_PERMISSION = "requestPermission"
    const val OPEN_APP_SETTINGS = "openAppSettings"
    const val START_LEVELS = "startLevels"
    const val STOP_LEVELS = "stopLevels"
    const val PLAY_ALARM = "playAlarm"
    const val SET_KEEP_SCREEN_ON = "setKeepScreenOn"
    const val APP_INFO = "appInfo"
}

/** Error codes that are not level failures. */
object ErrorCodes {
    /** A permission request is already running. */
    const val BUSY = "busy"

    /** The requested system function is not available. */
    const val UNAVAILABLE = "unavailable"

    /**
     * Defensive code for malformed arguments. A conforming Dart side never
     * triggers it; it exists so a protocol bug fails loudly instead of crashing.
     */
    const val INVALID_ARGUMENTS = "invalidArguments"
}

/** Why a level session could not start or ended; [code] is the wire value. */
enum class LevelFailure(
    val code: String,
) {
    PERMISSION_MISSING("permissionMissing"),
    MICROPHONE_BUSY("microphoneBusy"),
    RECORDING_ABORTED("recordingAborted"),
    UNAVAILABLE("unavailable"),
}

/** Microphone permission status; [wire] is the value sent to Dart. */
enum class PermissionStatus(
    val wire: String,
) {
    GRANTED("granted"),
    DENIED("denied"),
    PERMANENTLY_DENIED("permanentlyDenied"),
}
