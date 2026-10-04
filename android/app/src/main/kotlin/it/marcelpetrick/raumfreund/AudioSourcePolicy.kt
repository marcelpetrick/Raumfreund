// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.media.MediaRecorder

/**
 * Order in which audio sources are tried for level measurement.
 *
 * 1. UNPROCESSED – raw signal without AGC or noise suppression; only if the
 *    device declares PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED.
 * 2. VOICE_RECOGNITION – the Android CDD requires AGC and noise reduction to
 *    be disabled for this source (if implemented), so it is the most linear
 *    source on most devices.
 * 3. MIC – always present, but often with AGC, which compresses levels.
 *
 * The first source whose AudioRecord initializes is used.
 */
object AudioSourcePolicy {
    /** Candidate sources in order of preference. */
    fun candidates(unprocessedSupported: Boolean): List<Int> {
        val fallbacks = listOf(MediaRecorder.AudioSource.VOICE_RECOGNITION, MediaRecorder.AudioSource.MIC)
        return if (unprocessedSupported) listOf(MediaRecorder.AudioSource.UNPROCESSED) + fallbacks else fallbacks
    }
}
