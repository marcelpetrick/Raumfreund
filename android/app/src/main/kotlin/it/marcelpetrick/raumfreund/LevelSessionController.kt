// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioRecord
import android.os.Build
import android.os.Handler
import android.util.Log

/**
 * Owns the single level session: starts and stops [LevelRecorder]s, tags
 * every event with its session id and delivers it on the main thread through
 * [events]. Only one recorder exists at a time; a new session id stops the
 * previous one first. All public methods run on the main thread.
 */
class LevelSessionController(
    private val context: Context,
    private val events: LevelEventSink,
    private val mainHandler: Handler,
) : LevelControl {
    private val audioManager = context.getSystemService(AudioManager::class.java)
    private val sessions = SessionTracker()
    private var recorder: LevelRecorder? = null
    private var stopSilenceWatch: (() -> Unit)? = null

    override fun start(sessionId: Long): LevelFailure? {
        if (sessions.isActive(sessionId)) return null
        stop()
        return when (val opened = openRecord()) {
            is Opened.Ready -> begin(sessionId, opened.record)
            is Opened.Failed -> opened.failure
        }
    }

    override fun stop() {
        stopSilenceWatch?.invoke()
        stopSilenceWatch = null
        recorder?.stop()
        recorder = null
        sessions.end()
    }

    private sealed interface Opened {
        data class Ready(
            val record: AudioRecord,
        ) : Opened

        data class Failed(
            val failure: LevelFailure,
        ) : Opened
    }

    private fun openRecord(): Opened {
        if (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return Opened.Failed(LevelFailure.PERMISSION_MISSING)
        }
        val record =
            try {
                AudioRecordFactory(audioManager).create()
            } catch (e: SecurityException) {
                Log.w(TAG, "Permission revoked while starting", e)
                null
            }
        return record?.let(Opened::Ready) ?: Opened.Failed(failureWithoutRecord())
    }

    /** A missing record means a revoked permission or an unusable microphone. */
    private fun failureWithoutRecord(): LevelFailure =
        if (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            LevelFailure.PERMISSION_MISSING
        } else {
            LevelFailure.UNAVAILABLE
        }

    /** Starts the recorder for a new session; on failure everything is released. */
    private fun begin(
        sessionId: Long,
        record: AudioRecord,
    ): LevelFailure? {
        val token = sessions.begin(sessionId)
        val newRecorder = LevelRecorder(record, ReaderListener(sessionId, token))
        recorder = newRecorder
        val failure =
            newRecorder.start()
                ?: LevelFailure.MICROPHONE_BUSY.takeIf { watchSilencing(sessionId, token, newRecorder) }
        if (failure != null) stop()
        return failure
    }

    /** Ends the session with [failure] if it is still the running one. */
    private fun fail(
        sessionId: Long,
        token: Long,
        failure: LevelFailure,
    ) {
        if (!sessions.isCurrent(sessionId, token)) return
        stop()
        events.failure(sessionId, failure)
    }

    /** Returns true if the new recording is silenced right away. */
    private fun watchSilencing(
        sessionId: Long,
        token: Long,
        newRecorder: LevelRecorder,
    ): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val monitor =
            MicrophoneSilenceMonitor(audioManager, mainHandler, newRecorder.audioSessionId) {
                fail(sessionId, token, LevelFailure.MICROPHONE_BUSY)
            }
        stopSilenceWatch = monitor::unregister
        return monitor.register()
    }

    /** Hands results of the reader thread over to the main thread. */
    private inner class ReaderListener(
        private val sessionId: Long,
        private val token: Long,
    ) : LevelRecorder.Listener {
        override fun onLevel(dbfs: Double) {
            mainHandler.post {
                if (sessions.isCurrent(sessionId, token)) events.reading(sessionId, dbfs)
            }
        }

        override fun onAborted() {
            mainHandler.post { fail(sessionId, token, LevelFailure.RECORDING_ABORTED) }
        }
    }

    private companion object {
        const val TAG = "Raumfreund.Levels"
    }
}
