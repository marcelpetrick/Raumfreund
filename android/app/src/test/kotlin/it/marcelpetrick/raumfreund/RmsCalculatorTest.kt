// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import kotlin.math.PI
import kotlin.math.roundToInt
import kotlin.math.sin

class RmsCalculatorTest {
    private val window = AudioRecordFactory.WINDOW_SAMPLES

    private fun sine(amplitude: Double): ShortArray =
        ShortArray(window) { index ->
            // 1 kHz at 44.1 kHz; 100 whole periods fit into one window.
            (amplitude * sin(2 * PI * 1000.0 * index / AudioRecordFactory.SAMPLE_RATE_HZ)).roundToInt().toShort()
        }

    @Test
    fun `silence is reported as the floor`() {
        assertEquals(RmsCalculator.FLOOR_DBFS, RmsCalculator.dbfs(ShortArray(window)), 0.0)
    }

    @Test
    fun `empty window is reported as the floor`() {
        assertEquals(RmsCalculator.FLOOR_DBFS, RmsCalculator.dbfs(ShortArray(0)), 0.0)
        assertEquals(RmsCalculator.FLOOR_DBFS, RmsCalculator.dbfs(ShortArray(10) { 1000 }, 0), 0.0)
    }

    @Test
    fun `full-scale square is 0 dBFS`() {
        // +32767/-32768 is the largest square PCM16 can represent.
        val square = ShortArray(window) { index -> if (index % 2 == 0) Short.MAX_VALUE else Short.MIN_VALUE }
        assertEquals(0.0, RmsCalculator.dbfs(square), 0.001)
        // Exactly the reference magnitude everywhere is exactly 0 dBFS, never above.
        assertEquals(0.0, RmsCalculator.dbfs(ShortArray(window) { Short.MIN_VALUE }), 0.0)
    }

    @Test
    fun `full-scale sine is about -3 dBFS`() {
        assertEquals(-3.01, RmsCalculator.dbfs(sine(32767.0)), 0.01)
    }

    @Test
    fun `half amplitude is 6 dB lower`() {
        assertEquals(-9.03, RmsCalculator.dbfs(sine(16384.0)), 0.01)
    }

    @Test
    fun `constant known amplitude`() {
        // 3277 / 32768 = 0.1 -> -20 dBFS
        assertEquals(-20.0, RmsCalculator.dbfs(ShortArray(window) { 3277 }), 0.01)
    }

    @Test
    fun `tiny level is clamped to the floor`() {
        val oneLsbInMillion = ShortArray(1_000_000).also { it[0] = 1 }
        assertEquals(RmsCalculator.FLOOR_DBFS, RmsCalculator.dbfs(oneLsbInMillion), 0.0)
    }

    @Test
    fun `only the first count samples are used`() {
        val samples = ShortArray(20) { if (it < 10) 3277 else 0 }
        assertEquals(-20.0, RmsCalculator.dbfs(samples, 10), 0.01)
    }

    @Test
    fun `count outside the buffer is rejected`() {
        assertThrows(IllegalArgumentException::class.java) { RmsCalculator.dbfs(ShortArray(4), 5) }
        assertThrows(IllegalArgumentException::class.java) { RmsCalculator.dbfs(ShortArray(4), -1) }
    }
}
