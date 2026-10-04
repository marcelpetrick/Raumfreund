// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ControlChannelHandlerTest {
    /** Records the single answer of a call. */
    private class RecordingResult : MethodChannel.Result {
        val answers = mutableListOf<String>()

        override fun success(result: Any?) {
            answers += "success:$result"
        }

        override fun error(
            errorCode: String,
            errorMessage: String?,
            errorDetails: Any?,
        ) {
            answers += "error:$errorCode"
        }

        override fun notImplemented() {
            answers += "notImplemented"
        }
    }

    private class FakePermission : PermissionControl {
        var status = PermissionStatus.DENIED
        var pending: ((PermissionStatus) -> Unit)? = null
        var settingsAvailable = true

        override fun status() = status

        override fun request(onResult: (PermissionStatus) -> Unit): Boolean {
            if (pending != null) return false
            pending = onResult
            return true
        }

        override fun openAppSettings() = settingsAvailable
    }

    private class FakeLevels : LevelControl {
        var failure: LevelFailure? = null
        val calls = mutableListOf<String>()

        override fun start(sessionId: Long): LevelFailure? {
            calls += "start:$sessionId"
            return failure
        }

        override fun stop() {
            calls += "stop"
        }
    }

    private class FakeAlarm : AlarmControl {
        val requests = mutableListOf<AlarmRequest>()
        var done: ((Boolean) -> Unit)? = null

        override fun play(
            request: AlarmRequest,
            onDone: (success: Boolean) -> Unit,
        ) {
            requests += request
            done = onDone
        }
    }

    private val permission = FakePermission()
    private val levels = FakeLevels()
    private val alarm = FakeAlarm()
    private val screen = mutableListOf<Boolean>()
    private val handler =
        ControlChannelHandler(
            permission = permission,
            levels = levels,
            alarm = alarm,
            screen = { screen += it },
            appInfo = { mapOf("versionName" to "1.2.3", "versionCode" to 7L) },
        )

    private fun call(
        method: String,
        arguments: Any? = null,
    ): RecordingResult = RecordingResult().also { handler.onMethodCall(MethodCall(method, arguments), it) }

    @Test
    fun `permission status`() {
        permission.status = PermissionStatus.PERMANENTLY_DENIED
        assertEquals(listOf("success:permanentlyDenied"), call(Methods.PERMISSION_STATUS).answers)
    }

    @Test
    fun `permission request answers once with the result`() {
        val result = call(Methods.REQUEST_PERMISSION)
        assertEquals(emptyList<String>(), result.answers)
        permission.pending!!.invoke(PermissionStatus.GRANTED)
        assertEquals(listOf("success:granted"), result.answers)
    }

    @Test
    fun `second permission request is busy`() {
        call(Methods.REQUEST_PERMISSION)
        assertEquals(listOf("error:busy"), call(Methods.REQUEST_PERMISSION).answers)
    }

    @Test
    fun `open app settings`() {
        assertEquals(listOf("success:null"), call(Methods.OPEN_APP_SETTINGS).answers)
        permission.settingsAvailable = false
        assertEquals(listOf("error:unavailable"), call(Methods.OPEN_APP_SETTINGS).answers)
    }

    @Test
    fun `start levels succeeds or maps the failure`() {
        assertEquals(listOf("success:null"), call(Methods.START_LEVELS, mapOf("sessionId" to 4)).answers)
        for (failure in LevelFailure.entries) {
            levels.failure = failure
            assertEquals(listOf("error:${failure.code}"), call(Methods.START_LEVELS, mapOf("sessionId" to 5)).answers)
        }
        assertEquals("start:4", levels.calls.first())
    }

    @Test
    fun `start levels rejects malformed arguments without starting`() {
        assertEquals(listOf("error:invalidArguments"), call(Methods.START_LEVELS, mapOf("id" to 4)).answers)
        assertEquals(emptyList<String>(), levels.calls)
    }

    @Test
    fun `stop levels`() {
        assertEquals(listOf("success:null"), call(Methods.STOP_LEVELS).answers)
        assertEquals(listOf("stop"), levels.calls)
    }

    @Test
    fun `play alarm answers after the output ended`() {
        val result = call(Methods.PLAY_ALARM, mapOf("sound" to true, "vibrate" to true))
        assertEquals(listOf(AlarmRequest(sound = true, vibrate = true)), alarm.requests)
        assertEquals(emptyList<String>(), result.answers)
        alarm.done!!.invoke(true)
        assertEquals(listOf("success:null"), result.answers)
    }

    @Test
    fun `play alarm reports an unavailable tone`() {
        val result = call(Methods.PLAY_ALARM, mapOf("sound" to true, "vibrate" to false))
        alarm.done!!.invoke(false)
        assertEquals(listOf("error:unavailable"), result.answers)
    }

    @Test
    fun `play alarm rejects malformed arguments`() {
        assertEquals(listOf("error:invalidArguments"), call(Methods.PLAY_ALARM, mapOf("sound" to true)).answers)
        assertNull(alarm.done)
    }

    @Test
    fun `keep screen on`() {
        assertEquals(listOf("success:null"), call(Methods.SET_KEEP_SCREEN_ON, mapOf("enabled" to true)).answers)
        assertEquals(listOf("success:null"), call(Methods.SET_KEEP_SCREEN_ON, mapOf("enabled" to false)).answers)
        assertEquals(listOf("error:invalidArguments"), call(Methods.SET_KEEP_SCREEN_ON).answers)
        assertEquals(listOf(true, false), screen)
    }

    @Test
    fun `app info`() {
        assertEquals(listOf("success:{versionName=1.2.3, versionCode=7}"), call(Methods.APP_INFO).answers)
    }

    @Test
    fun `unknown method is not implemented`() {
        assertEquals(listOf("notImplemented"), call("doesNotExist").answers)
    }
}
