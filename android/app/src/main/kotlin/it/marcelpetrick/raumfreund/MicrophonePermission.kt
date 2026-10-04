// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.util.Log
import androidx.core.content.edit

/**
 * RECORD_AUDIO permission status and request.
 *
 * At most one request runs at a time. Its result arrives through
 * [onRequestPermissionsResult]. The activity pause caused by the system
 * dialog does not touch the pending request; only [completePending] (called
 * when the activity is destroyed) answers it early with the current status.
 */
class MicrophonePermission(
    private val activity: Activity,
) : PermissionControl {
    private val preferences =
        activity.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    private var pending: ((PermissionStatus) -> Unit)? = null

    override fun status(): PermissionStatus =
        PermissionPolicy.decide(
            granted = isGranted(),
            requestedBefore = preferences.getBoolean(KEY_REQUESTED, false),
            showRationale = activity.shouldShowRequestPermissionRationale(PERMISSION),
        )

    override fun request(onResult: (PermissionStatus) -> Unit): Boolean {
        if (pending != null) return false
        if (isGranted()) {
            onResult(PermissionStatus.GRANTED)
            return true
        }
        pending = onResult
        // Stored before the dialog: if the process dies meanwhile, the
        // request still counts for the permanentlyDenied inference.
        preferences.edit { putBoolean(KEY_REQUESTED, true) }
        activity.requestPermissions(arrayOf(PERMISSION), REQUEST_CODE)
        return true
    }

    /** Forwarded from the activity; returns true if the result was ours. */
    fun onRequestPermissionsResult(requestCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false
        // The status is re-read instead of trusting grantResults, which are
        // empty when the request was interrupted.
        completePending()
        return true
    }

    /** Answers a pending request with the current status (idempotent). */
    fun completePending() {
        val callback = pending ?: return
        pending = null
        callback(status())
    }

    override fun openAppSettings(): Boolean {
        val intent =
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", activity.packageName, null))
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            Log.w(TAG, "No app details settings activity", e)
            false
        }
    }

    private fun isGranted(): Boolean = activity.checkSelfPermission(PERMISSION) == PackageManager.PERMISSION_GRANTED

    private companion object {
        const val PERMISSION = Manifest.permission.RECORD_AUDIO
        const val REQUEST_CODE = 0x5246
        const val PREFERENCES_NAME = "raumfreund_native_permission"
        const val KEY_REQUESTED = "microphoneRequested"
        const val TAG = "Raumfreund.Permission"
    }
}
