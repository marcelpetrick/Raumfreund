// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.app.Activity
import android.view.WindowManager

/**
 * Keeps the display on while measuring via FLAG_KEEP_SCREEN_ON. Window flags
 * must be changed on the main thread, which is where channel calls and
 * lifecycle callbacks arrive.
 */
class ScreenAwake(
    private val activity: Activity,
) : ScreenControl {
    override fun setKeepScreenOn(enabled: Boolean) {
        val window = activity.window ?: return
        if (enabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }
}
