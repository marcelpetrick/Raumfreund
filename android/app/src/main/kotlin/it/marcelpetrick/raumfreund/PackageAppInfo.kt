// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

package it.marcelpetrick.raumfreund

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build

/**
 * versionName/versionCode of the installed package, read from the
 * PackageManager (no androidx PackageInfoCompat dependency needed).
 */
class PackageAppInfo(
    private val context: Context,
) : AppInfoSource {
    override fun read(): Map<String, Any> {
        val info = packageInfo()
        return mapOf(
            "versionName" to (info.versionName ?: ""),
            "versionCode" to versionCode(info),
        )
    }

    private fun packageInfo(): PackageInfo {
        val manager = context.packageManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            manager.getPackageInfo(context.packageName, PackageManager.PackageInfoFlags.of(0))
        } else {
            legacyPackageInfo(manager)
        }
    }

    // The flags-as-int overload is deprecated from API 33; only used below it.
    @Suppress("DEPRECATION")
    private fun legacyPackageInfo(manager: PackageManager): PackageInfo = manager.getPackageInfo(context.packageName, 0)

    private fun versionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            legacyVersionCode(info)
        }

    // PackageInfo.versionCode is deprecated from API 28; only used below it.
    @Suppress("DEPRECATION")
    private fun legacyVersionCode(info: PackageInfo): Long = info.versionCode.toLong()
}
