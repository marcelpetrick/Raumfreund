// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.media.AudioRecord
import android.util.Log

/**
 * One recording session: owns an initialized [AudioRecord] and its reader
 * thread. Not reusable; create a new instance per session.
 *
 * The reader thread fills one reused buffer of ~100 ms, computes its RMS
 * level and immediately overwrites it with the next window. Samples never
 * leave RAM and are cleared when the thread ends.
 *
 * [start] and [stop] are called on the main thread; [Listener] callbacks run
 * on the reader thread and must hand over to the main thread themselves.
 */
class LevelRecorder(
    private val audioRecord: AudioRecord,
    private val listener: Listener,
) {
    /** Receives results of the reader thread. */
    interface Listener {
        /** Level of one complete window. */
        fun onLevel(dbfs: Double)

        /** Reading failed while the session was not being stopped. */
        fun onAborted()
    }

    @Volatile
    private var stopping = false
    private var released = false
    private var thread: Thread? = null

    /**
     * Starts recording. Returns null when the AudioRecord is recording, else
     * [LevelFailure.MICROPHONE_BUSY] (the recorder is then released).
     */
    fun start(): LevelFailure? {
        val recording =
            try {
                audioRecord.startRecording()
                audioRecord.recordingState == AudioRecord.RECORDSTATE_RECORDING
            } catch (e: IllegalStateException) {
                Log.w(TAG, "startRecording failed", e)
                false
            }
        if (!recording) {
            stop()
            return LevelFailure.MICROPHONE_BUSY
        }
        thread = Thread(::readLoop, THREAD_NAME).apply { start() }
        return null
    }

    /** Audio session id, used to recognize our recording in system callbacks. */
    val audioSessionId: Int get() = audioRecord.audioSessionId

    /**
     * Stops reading and releases the recorder. Idempotent. Reads are
     * non-blocking, so setting [stopping] proves the worker will leave its
     * bounded loop before this method returns and a new session may start.
     */
    fun stop() {
        if (released) return
        released = true
        stopping = true
        try {
            audioRecord.stop()
        } catch (e: IllegalStateException) {
            Log.w(TAG, "stop on a recorder that was not recording", e)
        }
        thread?.join()
        thread = null
        audioRecord.release()
    }

    private fun readLoop() {
        val buffer = ShortArray(AudioRecordFactory.WINDOW_SAMPLES)
        try {
            var complete = true
            while (complete && !stopping) {
                complete = fillWindow(buffer) == buffer.size
                if (complete && !stopping) listener.onLevel(RmsCalculator.dbfs(buffer))
            }
            if (!complete && !stopping) listener.onAborted()
        } catch (e: IllegalStateException) {
            Log.w(TAG, "Reading failed", e)
            if (!stopping) listener.onAborted()
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
            if (!stopping) listener.onAborted()
        } finally {
            buffer.fill(0)
        }
    }

    /** Blocks until [buffer] is full; returns fewer samples on error or stop. */
    private fun fillWindow(buffer: ShortArray): Int {
        var filled = 0
        while (filled < buffer.size && !stopping) {
            val read =
                audioRecord.read(
                    buffer,
                    filled,
                    buffer.size - filled,
                    AudioRecord.READ_NON_BLOCKING,
                )
            if (read < 0) {
                if (!stopping) Log.w(TAG, "AudioRecord.read returned $read")
                return filled
            }
            if (read == 0) {
                Thread.sleep(READ_RETRY_DELAY_MS)
            } else {
                filled += read
            }
        }
        return filled
    }

    private companion object {
        const val TAG = "Raumfreund.Recorder"
        const val THREAD_NAME = "raumfreund-levels"
        const val READ_RETRY_DELAY_MS = 2L
    }
}
