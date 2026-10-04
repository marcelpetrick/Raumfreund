// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Dispatches calls of the control method channel to the collaborators.
 * Every call is answered exactly once (docs/platform-channels.md).
 */
class ControlChannelHandler(
    private val permission: PermissionControl,
    private val levels: LevelControl,
    private val alarm: AlarmControl,
    private val screen: ScreenControl,
    private val appInfo: AppInfoSource,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            Methods.PERMISSION_STATUS -> result.success(permission.status().wire)
            Methods.REQUEST_PERMISSION -> requestPermission(result)
            Methods.OPEN_APP_SETTINGS -> openAppSettings(result)
            Methods.START_LEVELS -> startLevels(call.arguments, result)
            Methods.STOP_LEVELS -> stopLevels(result)
            Methods.PLAY_ALARM -> playAlarm(call.arguments, result)
            Methods.SET_KEEP_SCREEN_ON -> setKeepScreenOn(call.arguments, result)
            Methods.APP_INFO -> result.success(appInfo.read())
            else -> result.notImplemented()
        }
    }

    private fun stopLevels(result: MethodChannel.Result) {
        levels.stop()
        result.success(null)
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val started = permission.request { status -> result.success(status.wire) }
        if (!started) {
            result.error(ErrorCodes.BUSY, "A permission request is already running", null)
        }
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        if (permission.openAppSettings()) {
            result.success(null)
        } else {
            result.error(ErrorCodes.UNAVAILABLE, "App settings cannot be opened", null)
        }
    }

    private fun startLevels(
        arguments: Any?,
        result: MethodChannel.Result,
    ) {
        val sessionId = ChannelArguments.sessionId(arguments) ?: return invalid(result)
        val failure = levels.start(sessionId)
        if (failure == null) {
            result.success(null)
        } else {
            result.error(failure.code, "Level measurement cannot start", null)
        }
    }

    private fun playAlarm(
        arguments: Any?,
        result: MethodChannel.Result,
    ) {
        val request = ChannelArguments.alarmRequest(arguments) ?: return invalid(result)
        alarm.play(request) { success ->
            if (success) {
                result.success(null)
            } else {
                result.error(ErrorCodes.UNAVAILABLE, "Alarm tone is unavailable", null)
            }
        }
    }

    private fun setKeepScreenOn(
        arguments: Any?,
        result: MethodChannel.Result,
    ) {
        val enabled = ChannelArguments.keepScreenOn(arguments) ?: return invalid(result)
        screen.setKeepScreenOn(enabled)
        result.success(null)
    }

    private fun invalid(result: MethodChannel.Result) {
        result.error(ErrorCodes.INVALID_ARGUMENTS, "Malformed arguments", null)
    }
}
