// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ChannelArgumentsTest {
    @Test
    fun `session id accepts Int and Long`() {
        assertEquals(3L, ChannelArguments.sessionId(mapOf("sessionId" to 3)))
        assertEquals(1L shl 40, ChannelArguments.sessionId(mapOf("sessionId" to (1L shl 40))))
    }

    @Test
    fun `malformed session id is null`() {
        assertNull(ChannelArguments.sessionId(null))
        assertNull(ChannelArguments.sessionId("3"))
        assertNull(ChannelArguments.sessionId(emptyMap<String, Any>()))
        assertNull(ChannelArguments.sessionId(mapOf("sessionId" to "3")))
        assertNull(ChannelArguments.sessionId(mapOf("sessionId" to 3.0)))
    }

    @Test
    fun `alarm request is parsed`() {
        assertEquals(
            AlarmRequest(sound = true, vibrate = false),
            ChannelArguments.alarmRequest(mapOf("sound" to true, "vibrate" to false)),
        )
    }

    @Test
    fun `malformed alarm request is null`() {
        assertNull(ChannelArguments.alarmRequest(null))
        assertNull(ChannelArguments.alarmRequest(listOf(true, false)))
        assertNull(ChannelArguments.alarmRequest(mapOf("sound" to true)))
        assertNull(ChannelArguments.alarmRequest(mapOf("vibrate" to true)))
        assertNull(ChannelArguments.alarmRequest(mapOf("sound" to "yes", "vibrate" to true)))
    }

    @Test
    fun `keep screen on is parsed`() {
        assertEquals(true, ChannelArguments.keepScreenOn(mapOf("enabled" to true)))
        assertEquals(false, ChannelArguments.keepScreenOn(mapOf("enabled" to false)))
        assertNull(ChannelArguments.keepScreenOn(mapOf("enabled" to 1)))
        assertNull(ChannelArguments.keepScreenOn(null))
    }
}
