// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import kotlin.math.max

/** Durations of the alarm output and when `playAlarm` may answer. */
object AlarmDurationPolicy {
    /** Length of the beep. */
    const val TONE_MS = 400

    /** Length of the vibration. */
    const val VIBRATION_MS = 300L

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
