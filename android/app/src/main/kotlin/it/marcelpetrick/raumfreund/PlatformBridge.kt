// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.app.Activity
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Creates the native components, connects them to the platform channels and
 * applies the lifecycle safety net. Lives as long as the Flutter engine is
 * attached to the activity.
 */
class PlatformBridge(
    activity: Activity,
    messenger: BinaryMessenger,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val levelEvents = LevelEventSink()
    private val levels = LevelSessionController(activity.applicationContext, levelEvents, mainHandler)
    private val screen = ScreenAwake(activity)
    private val controlChannel = MethodChannel(messenger, ChannelNames.CONTROL)
    private val levelsChannel = EventChannel(messenger, ChannelNames.LEVELS)

    /** Permission handling; the activity forwards permission results here. */
    val permission = MicrophonePermission(activity)

    init {
        controlChannel.setMethodCallHandler(
            ControlChannelHandler(
                permission = permission,
                levels = levels,
                alarm = AlarmPlayer(activity.applicationContext, mainHandler),
                screen = screen,
                appInfo = PackageAppInfo(activity.applicationContext),
            ),
        )
        levelsChannel.setStreamHandler(levelEvents)
    }

    /**
     * The activity is no longer visible (real background change, not the
     * permission dialog, which only pauses it): stop measuring and let the
     * screen turn off.
     */
    fun onStop() {
        levels.stop()
        screen.setKeepScreenOn(false)
    }

    /** The activity is being destroyed: end everything and answer open calls. */
    fun onDestroy() {
        onStop()
        permission.completePending()
    }

    /** Detaches the channel handlers; called when the engine is cleaned up. */
    fun dispose() {
        levels.stop()
        controlChannel.setMethodCallHandler(null)
        levelsChannel.setStreamHandler(null)
    }
}
