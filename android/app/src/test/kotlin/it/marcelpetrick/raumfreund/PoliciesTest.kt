// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.media.MediaRecorder
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PermissionPolicyTest {
    @Test
    fun `granted wins over everything`() {
        for (requested in listOf(false, true)) {
            for (rationale in listOf(false, true)) {
                assertEquals(PermissionStatus.GRANTED, PermissionPolicy.decide(true, requested, rationale))
            }
        }
    }

    @Test
    fun `never requested is denied`() {
        assertEquals(PermissionStatus.DENIED, PermissionPolicy.decide(false, false, false))
        assertEquals(PermissionStatus.DENIED, PermissionPolicy.decide(false, false, true))
    }

    @Test
    fun `requested with rationale is denied`() {
        assertEquals(PermissionStatus.DENIED, PermissionPolicy.decide(false, true, true))
    }

    @Test
    fun `requested without rationale is permanently denied`() {
        assertEquals(PermissionStatus.PERMANENTLY_DENIED, PermissionPolicy.decide(false, true, false))
    }

    @Test
    fun `wire values match the protocol`() {
        assertEquals(
            listOf("granted", "denied", "permanentlyDenied"),
            PermissionStatus.entries.map { it.wire },
        )
    }
}

class AlarmDurationPolicyTest {
    @Test
    fun `nothing to play completes immediately`() {
        assertEquals(0L, AlarmDurationPolicy.completionDelayMs(sound = false, vibrate = false))
    }

    @Test
    fun `tone waits for tone plus output latency`() {
        assertEquals(500L, AlarmDurationPolicy.completionDelayMs(sound = true, vibrate = false))
    }

    @Test
    fun `vibration only waits for the vibration`() {
        assertEquals(1140L, AlarmDurationPolicy.completionDelayMs(sound = false, vibrate = true))
    }

    @Test
    fun `vibration is three noticeable pulses that start at once`() {
        val pattern = AlarmDurationPolicy.VIBRATION_PATTERN_MS
        assertEquals(0L, pattern.first())
        val pulses = pattern.filterIndexed { index, _ -> index % 2 == 1 }
        assertEquals(3, pulses.size)
        assertEquals(true, pulses.all { it >= 250L })
        assertEquals(pattern.sum(), AlarmDurationPolicy.VIBRATION_MS)
    }

    @Test
    fun `both wait for the longer output`() {
        assertEquals(1140L, AlarmDurationPolicy.completionDelayMs(sound = true, vibrate = true))
    }
}

class AudioSourcePolicyTest {
    @Test
    fun `unprocessed first when supported`() {
        assertEquals(
            listOf(
                MediaRecorder.AudioSource.UNPROCESSED,
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                MediaRecorder.AudioSource.MIC,
            ),
            AudioSourcePolicy.candidates(unprocessedSupported = true),
        )
    }

    @Test
    fun `voice recognition then mic otherwise`() {
        assertEquals(
            listOf(MediaRecorder.AudioSource.VOICE_RECOGNITION, MediaRecorder.AudioSource.MIC),
            AudioSourcePolicy.candidates(unprocessedSupported = false),
        )
    }
}

class SilencePolicyTest {
    @Test
    fun `our silenced session is detected`() {
        val clients = listOf(RecordingClient(7, silenced = false), RecordingClient(42, silenced = true))
        assertTrue(SilencePolicy.isSilenced(clients, 42))
    }

    @Test
    fun `other silenced sessions or active ours are ignored`() {
        val clients = listOf(RecordingClient(7, silenced = true), RecordingClient(42, silenced = false))
        assertFalse(SilencePolicy.isSilenced(clients, 42))
        assertFalse(SilencePolicy.isSilenced(emptyList(), 42))
    }
}
