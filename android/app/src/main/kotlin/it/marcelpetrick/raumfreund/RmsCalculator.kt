// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import kotlin.math.log10
import kotlin.math.sqrt

/**
 * Root mean square level of PCM16 samples in dBFS.
 *
 * Reference is 32768 (the magnitude of [Short.MIN_VALUE]), so a full-scale
 * square wave is 0 dBFS and a full-scale sine is about -3.01 dBFS. Silence and
 * levels below [FLOOR_DBFS] are reported as [FLOOR_DBFS], so the result is
 * always finite and within [FLOOR_DBFS]..0.
 */
object RmsCalculator {
    /** Lowest reported level; also the value for digital silence. */
    const val FLOOR_DBFS = -100.0

    private const val FULL_SCALE = 32768.0
    private const val DECIBEL_FACTOR = 20.0

    /** Level of the first [count] samples of [samples]. */
    fun dbfs(
        samples: ShortArray,
        count: Int = samples.size,
    ): Double {
        require(count in 0..samples.size) { "count $count outside 0..${samples.size}" }
        if (count == 0) return FLOOR_DBFS
        var sumOfSquares = 0.0
        for (index in 0 until count) {
            val sample = samples[index].toDouble()
            sumOfSquares += sample * sample
        }
        val rms = sqrt(sumOfSquares / count) / FULL_SCALE
        return if (rms > 0.0) (DECIBEL_FACTOR * log10(rms)).coerceIn(FLOOR_DBFS, 0.0) else FLOOR_DBFS
    }
}
