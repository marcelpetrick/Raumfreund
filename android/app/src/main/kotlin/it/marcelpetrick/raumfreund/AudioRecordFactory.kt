// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.Manifest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.util.Log
import androidx.annotation.RequiresPermission
import kotlin.math.max

/**
 * Creates the AudioRecord for level measurement: 44100 Hz mono PCM16, the
 * only format every Android device must support. Tries the sources of
 * [AudioSourcePolicy] in order.
 */
class AudioRecordFactory(
    private val audioManager: AudioManager,
) {
    /** Returns an initialized AudioRecord, or null if no source works. */
    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    fun create(): AudioRecord? {
        val minBufferBytes = AudioRecord.getMinBufferSize(SAMPLE_RATE_HZ, CHANNEL, ENCODING)
        if (minBufferBytes <= 0) {
            Log.w(TAG, "PCM16 mono 44.1 kHz not supported: $minBufferBytes")
            return null
        }
        // Two windows of headroom so a late reader thread does not lose samples.
        val bufferBytes = max(minBufferBytes, WINDOW_SAMPLES * BYTES_PER_SAMPLE * 2)
        return AudioSourcePolicy.candidates(unprocessedSupported()).firstNotNullOfOrNull { source ->
            tryCreate(source, bufferBytes)
        }
    }

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    private fun tryCreate(
        source: Int,
        bufferBytes: Int,
    ): AudioRecord? {
        val record =
            try {
                AudioRecord(source, SAMPLE_RATE_HZ, CHANNEL, ENCODING, bufferBytes)
            } catch (e: IllegalArgumentException) {
                Log.w(TAG, "Audio source $source rejected", e)
                null
            }
        val usable = record?.state == AudioRecord.STATE_INITIALIZED
        if (usable) {
            Log.i(TAG, "Recording with audio source $source")
        } else {
            Log.w(TAG, "Audio source $source did not initialize")
            record?.release()
        }
        return record.takeIf { usable }
    }

    private fun unprocessedSupported(): Boolean =
        "true".equals(
            audioManager.getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED),
            ignoreCase = true,
        )

    companion object {
        /** Sample rate guaranteed by the Android CDD. */
        const val SAMPLE_RATE_HZ = 44_100

        /** Samples per RMS window: 100 ms at [SAMPLE_RATE_HZ]. */
        const val WINDOW_SAMPLES = SAMPLE_RATE_HZ / 10

        private const val CHANNEL = AudioFormat.CHANNEL_IN_MONO
        private const val ENCODING = AudioFormat.ENCODING_PCM_16BIT
        private const val BYTES_PER_SAMPLE = 2
        private const val TAG = "Raumfreund.Audio"
    }
}
