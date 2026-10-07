// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.annotation.RequiresApi

/**
 * Short alarm: a beep of [AlarmDurationPolicy.TONE_MS] and, if the device has
 * a vibrator, the pulse pattern [AlarmDurationPolicy.VIBRATION_PATTERN_MS].
 *
 * The tone uses STREAM_ALARM: the user switched the alarm tone on explicitly
 * in the app, so it must stay audible when the ringer is muted or set to
 * vibrate (typical in classrooms), and the alarm volume is independent of
 * media/notification volume. STREAM_NOTIFICATION would silently drop the
 * alarm in exactly those situations. The in-app switch is the way to mute it.
 * The vibration carries the alarm usage for the same reason: without
 * attributes Android 13+ treats it as "unknown" usage, which the system may
 * scale down or suppress, for example in silent mode.
 *
 * Completion is reported on [handler]'s thread after the output has ended,
 * so the caller can ignore the microphone while its own tone is playing.
 */
class AlarmPlayer(
    private val context: Context,
    private val handler: Handler,
) : AlarmControl {
    override fun play(
        request: AlarmRequest,
        onDone: (success: Boolean) -> Unit,
    ) {
        val vibrator = if (request.vibrate) availableVibrator() else null
        val tone = if (request.sound) startTone() else null
        val toneFailed = request.sound && tone == null
        vibrator?.let(::vibrate)
        val delay = AlarmDurationPolicy.completionDelayMs(sound = tone != null, vibrate = vibrator != null)
        if (delay == 0L) {
            onDone(!toneFailed)
            return
        }
        handler.postDelayed({
            tone?.release()
            onDone(!toneFailed)
        }, delay)
    }

    /**
     * Starts the beep; null if the tone generator is unavailable. The
     * ToneGenerator constructor signals "audio system cannot create the tone
     * track" with a plain RuntimeException; nothing narrower can be caught.
     */
    @Suppress("TooGenericExceptionCaught")
    private fun startTone(): ToneGenerator? {
        val generator =
            try {
                ToneGenerator(AudioManager.STREAM_ALARM, TONE_VOLUME)
            } catch (e: RuntimeException) {
                Log.w(TAG, "ToneGenerator unavailable", e)
                null
            }
        val started = generator?.startTone(TONE, AlarmDurationPolicy.TONE_MS) == true
        if (generator != null && !started) {
            Log.w(TAG, "Tone did not start")
            generator.release()
        }
        return generator.takeIf { started }
    }

    private fun availableVibrator(): Vibrator? {
        val vibrator =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                legacyVibrator()
            }
        return vibrator?.takeIf { it.hasVibrator() }
    }

    // Before API 31 there is no VibratorManager; the Vibrator service is used directly.
    private fun legacyVibrator(): Vibrator? = context.getSystemService(Vibrator::class.java)

    private fun vibrate(vibrator: Vibrator) {
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> vibrateAsAlarm(vibrator)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> vibrateWithAudioUsage(vibrator)
            else -> legacyVibrate(vibrator)
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun pattern(): VibrationEffect = VibrationEffect.createWaveform(AlarmDurationPolicy.VIBRATION_PATTERN_MS, NO_REPEAT)

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun vibrateAsAlarm(vibrator: Vibrator) {
        vibrator.vibrate(pattern(), VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM))
    }

    // API 26-32 classify a vibration through AudioAttributes; that overload is
    // deprecated from API 33, which uses VibrationAttributes above instead.
    @RequiresApi(Build.VERSION_CODES.O)
    @Suppress("DEPRECATION")
    private fun vibrateWithAudioUsage(vibrator: Vibrator) {
        val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
        vibrator.vibrate(pattern(), attributes)
    }

    // VibrationEffect exists from API 26; API 24-25 only have vibrate(pattern, repeat).
    @Suppress("DEPRECATION")
    private fun legacyVibrate(vibrator: Vibrator) {
        vibrator.vibrate(AlarmDurationPolicy.VIBRATION_PATTERN_MS, NO_REPEAT)
    }

    private companion object {
        const val TAG = "Raumfreund.Alarm"
        const val NO_REPEAT = -1
        const val TONE_VOLUME = 80

        // A continuous tone (unlike the 100 ms TONE_PROP_BEEP sequence), so
        // the requested duration is honoured exactly.
        const val TONE = ToneGenerator.TONE_DTMF_A
    }
}
