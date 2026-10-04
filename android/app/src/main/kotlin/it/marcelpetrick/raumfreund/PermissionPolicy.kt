// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

/** Pure decision of the reported microphone permission status. */
object PermissionPolicy {
    /**
     * Android has no API for "permanently denied". It is inferred: the
     * permission was requested before, is not granted and the system would no
     * longer show a rationale. Before the first request the status is
     * [PermissionStatus.DENIED], because shouldShowRequestPermissionRationale
     * is false then, too.
     *
     * Known ambiguity: on Android 11+ a dialog dismissed without an answer, or
     * a permission revoked in the system settings, can look the same. The
     * request therefore always asks the system again.
     */
    fun decide(
        granted: Boolean,
        requestedBefore: Boolean,
        showRationale: Boolean,
    ): PermissionStatus =
        when {
            granted -> PermissionStatus.GRANTED
            !requestedBefore || showRationale -> PermissionStatus.DENIED
            else -> PermissionStatus.PERMANENTLY_DENIED
        }
}
