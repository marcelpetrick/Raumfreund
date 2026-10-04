// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.media.AudioManager
import android.media.AudioRecordingConfiguration
import android.os.Build
import android.os.Handler
import androidx.annotation.RequiresApi

/**
 * Detects (API 29+) that the system silenced our recording because another
 * app took the microphone. [onSilenced] runs on the thread of [handler].
 */
@RequiresApi(Build.VERSION_CODES.Q)
class MicrophoneSilenceMonitor(
    private val audioManager: AudioManager,
    private val handler: Handler,
    private val audioSessionId: Int,
    private val onSilenced: () -> Unit,
) {
    private val callback =
        object : AudioManager.AudioRecordingCallback() {
            override fun onRecordingConfigChanged(configs: List<AudioRecordingConfiguration>) {
                if (isSilenced(configs)) onSilenced()
            }
        }

    /** Starts listening; returns true if the recording is silenced already. */
    fun register(): Boolean {
        audioManager.registerAudioRecordingCallback(callback, handler)
        return isSilenced(audioManager.activeRecordingConfigurations)
    }

    /** Stops listening. Safe to call more than once. */
    fun unregister() {
        audioManager.unregisterAudioRecordingCallback(callback)
    }

    private fun isSilenced(configs: List<AudioRecordingConfiguration>): Boolean =
        SilencePolicy.isSilenced(
            configs.map { RecordingClient(it.clientAudioSessionId, it.isClientSilenced) },
            audioSessionId,
        )
}
