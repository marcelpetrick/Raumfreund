// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import kotlin.math.max

/** Durations of the alarm output and when `playAlarm` may answer. */
object AlarmDurationPolicy {
    /** Length of the beep. */
    const val TONE_MS = 400

    /**
     * Vibration as off/on timings in ms: three pulses. A single 300 ms pulse
     * was easy to miss with the phone lying on a desk; three distinct pulses
     * are noticeable and still end quickly, because the microphone is ignored
     * while the motor runs.
     */
    val VIBRATION_PATTERN_MS =
        longArrayOf(0L, PULSE_MS, PAUSE_MS, PULSE_MS, PAUSE_MS, LAST_PULSE_MS)

    /** One short vibration pulse. */
    const val PULSE_MS = 250L

    /** Pause between pulses; long enough to feel them as separate. */
    const val PAUSE_MS = 120L

    /** The last pulse is longer, so the pattern ends clearly. */
    const val LAST_PULSE_MS = 400L

    /** Length of the whole vibration pattern. */
    val VIBRATION_MS = VIBRATION_PATTERN_MS.sum()

    /**
     * ToneGenerator.startTone returns before the audio reaches the speaker.
     * The margin covers typical output latency, so the answer really comes
     * after the tone has ended and the microphone is no longer influenced.
     */
    const val OUTPUT_LATENCY_MARGIN_MS = 100L

    /** Delay until the alarm output has ended; 0 when nothing is played. */
    fun completionDelayMs(
        sound: Boolean,
        vibrate: Boolean,
    ): Long {
        val toneEnd = if (sound) TONE_MS + OUTPUT_LATENCY_MARGIN_MS else 0L
        val vibrationEnd = if (vibrate) VIBRATION_MS else 0L
        return max(toneEnd, vibrationEnd)
    }
}
