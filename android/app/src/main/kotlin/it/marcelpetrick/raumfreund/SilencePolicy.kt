// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

/** One active recording as reported by AudioRecordingConfiguration. */
data class RecordingClient(
    val audioSessionId: Int,
    val silenced: Boolean,
)

/** Pure check whether our recording was silenced by the system. */
object SilencePolicy {
    /**
     * Since Android 10 an app with higher priority (a call, an assistant, …)
     * can take the microphone; our AudioRecord keeps running but delivers
     * silence. That must be reported as a busy microphone, not as a quiet room.
     */
    fun isSilenced(
        clients: List<RecordingClient>,
        ourAudioSessionId: Int,
    ): Boolean = clients.any { it.audioSessionId == ourAudioSessionId && it.silenced }
}
