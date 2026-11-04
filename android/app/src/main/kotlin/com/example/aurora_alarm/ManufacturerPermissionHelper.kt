package com.example.aurora_alarm

import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Commercial-grade helper for detecting Android OEM manufacturers (Xiaomi/HyperOS/MIUI,
 * Samsung, Oppo/Realme/OnePlus, Vivo/iQOO, Huawei/Honor, Motorola, Stock Android),
 * checking special lockscreen/background permissions (including Xiaomi AppOps 10020 & 10021),
 * and safely navigating users to the exact OEM permission configuration screens.
 */
class ManufacturerPermissionHelper(private val context: Context) {

    companion object {
        private const val TAG = "ManufacturerPermHelper"

        // Xiaomi MIUI / HyperOS custom AppOps codes
        const val OP_MIUI_AUTO_START = 10008
        const val OP_MIUI_SHOW_WHEN_LOCKED = 10020
        const val OP_MIUI_BACKGROUND_START_ACTIVITY = 10021
    }

    /**
     * Normalized manufacturer category:
     * "xiaomi", "samsung", "oppo", "vivo", "huawei", "motorola", or "other".
     */
    fun getManufacturerCategory(): String {
        val manufacturer = (Build.MANUFACTURER ?: "").lowercase().trim()
        val brand = (Build.BRAND ?: "").lowercase().trim()

        return when {
            manufacturer.contains("xiaomi") ||
            brand.contains("xiaomi") ||
            brand.contains("redmi") ||
            brand.contains("poco") ||
            brand.contains("blackshark") ||
            isMiuiOrHyperOs() -> "xiaomi"

            manufacturer.contains("samsung") || brand.contains("samsung") -> "samsung"

            manufacturer.contains("oppo") ||
            brand.contains("oppo") ||
            brand.contains("realme") ||
            brand.contains("oneplus") ||
            manufacturer.contains("realme") ||
            manufacturer.contains("oneplus") -> "oppo"

            manufacturer.contains("vivo") ||
            brand.contains("vivo") ||
            brand.contains("iqoo") -> "vivo"

            manufacturer.contains("huawei") ||
            brand.contains("huawei") ||
            manufacturer.contains("honor") ||
            brand.contains("honor") -> "huawei"

            manufacturer.contains("motorola") ||
            brand.contains("motorola") ||
            brand.contains("moto") -> "motorola"

            else -> "other"
        }
    }

    /**
     * Human-readable manufacturer & OS skin label for UI presentation.
     */
    fun getManufacturerDisplayName(): String {
        return when (getManufacturerCategory()) {
            "xiaomi" -> {
                val brand = (Build.BRAND ?: "Xiaomi").replaceFirstChar { it.uppercase() }
                "$brand (HyperOS / MIUI)"
            }
            "samsung" -> "Samsung (One UI)"
            "oppo" -> {
                val brand = (Build.BRAND ?: "Oppo").replaceFirstChar { it.uppercase() }
                "$brand (ColorOS / OxygenOS)"
            }
            "vivo" -> "Vivo (FuntouchOS / OriginOS)"
            "huawei" -> "Huawei / Honor (EMUI / MagicOS)"
            "motorola" -> "Motorola"
            else -> {
                val raw = (Build.MANUFACTURER ?: "Android").replaceFirstChar { it.uppercase() }
                raw
            }
        }
    }

    /**
     * Returns true if running on a Xiaomi, Redmi, POCO device or MIUI/HyperOS ROM.
     */
    fun isXiaomi(): Boolean {
        return getManufacturerCategory() == "xiaomi"
    }

    private fun isMiuiOrHyperOs(): Boolean {
        val miuiVer = getSystemProperty("ro.miui.ui.version.name")
        val hyperOsVer = getSystemProperty("ro.mi.os.version.name")
        return !miuiVer.isNullOrBlank() || !hyperOsVer.isNullOrBlank()
    }

    private fun getSystemProperty(propName: String): String? {
        return try {
            val process = Runtime.getRuntime().exec("getprop $propName")
            BufferedReader(InputStreamReader(process.inputStream), 1024).use { reader ->
                reader.readLine()?.trim()
            }
        } catch (e: Exception) {
            null
        }
    }

    // =========================================================================
    // Permission Checks
    // =========================================================================

    /**
     * Checks SYSTEM_ALERT_WINDOW (Display over other apps / Exibir sobre outros apps).
     */
    fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                Settings.canDrawOverlays(context)
            } catch (e: Exception) {
                Log.e(TAG, "Error checking canDrawOverlays: ${e.message}")
                false
            }
        } else {
            true
        }
    }

    /**
     * Checks USE_FULL_SCREEN_INTENT (Android 14+ / API 34+).
     * Always returns true on Android 13 and below.
     */
    fun canUseFullScreenIntent(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                nm?.canUseFullScreenIntent() ?: true
            } catch (e: Exception) {
                Log.e(TAG, "Error checking canUseFullScreenIntent: ${e.message}")
                true
            }
        } else {
            true
        }
    }

    /**
     * Checks SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM (Android 12+ / API 31+).
     */
    fun canScheduleExactAlarms(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                am?.canScheduleExactAlarms() ?: true
            } catch (e: Exception) {
                Log.e(TAG, "Error checking canScheduleExactAlarms: ${e.message}")
                true
            }
        } else {
            true
        }
    }

    /**
     * Checks whether the app is exempted from battery optimizations (Doze mode).
     */
    fun isBatteryOptimizationIgnored(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                pm?.isIgnoringBatteryOptimizations(context.packageName) ?: true
            } catch (e: Exception) {
                Log.e(TAG, "Error checking isBatteryOptimizationIgnored: ${e.message}")
                true
            }
        } else {
            true
        }
    }

    /**
     * Checks whether notifications are enabled for the app (POST_NOTIFICATIONS).
     */
    fun areNotificationsEnabled(): Boolean {
        return try {
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        } catch (e: Exception) {
            Log.e(TAG, "Error checking areNotificationsEnabled: ${e.message}")
            true
        }
    }

    /**
     * Xiaomi specific check: op 10020 ("Show on Lock screen" / Exibir na tela de bloqueio).
     * Uses safe reflection on AppOpsManager.
     */
    fun canXiaomiShowOnLockScreen(): Boolean {
        if (!isXiaomi()) return true
        return checkXiaomiAppOp(OP_MIUI_SHOW_WHEN_LOCKED)
    }

    /**
     * Xiaomi specific check: op 10021 ("Open new windows while running in the background" /
     * Abrir novas janelas enquanto estiver em segundo plano).
     * Uses safe reflection on AppOpsManager.
     */
    fun canXiaomiStartFromBackground(): Boolean {
        if (!isXiaomi()) return true
        return checkXiaomiAppOp(OP_MIUI_BACKGROUND_START_ACTIVITY)
    }

    private fun checkXiaomiAppOp(op: Int): Boolean {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
                ?: return false
            val method = AppOpsManager::class.java.getMethod(
                "checkOpNoThrow",
                Int::class.javaPrimitiveType,
                Int::class.javaPrimitiveType,
                String::class.java
            )
            val mode = method.invoke(appOps, op, Process.myUid(), context.packageName) as? Int
            Log.d(TAG, "Xiaomi AppOp($op) mode=$mode (MODE_ALLOWED=${AppOpsManager.MODE_ALLOWED})")
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            Log.w(TAG, "Xiaomi AppOp($op) reflection fallback: ${e.message}")
            // Fallback if hidden API blocks reflection
            canDrawOverlays()
        }
    }

    /**
     * Aggregates all permission statuses into a single map for Flutter consumption.
     */
    fun getPermissionsStatus(): Map<String, Any> {
        val category = getManufacturerCategory()
        val xiaomi = isXiaomi()
        val drawOverlays = canDrawOverlays()
        val fullScreenIntent = canUseFullScreenIntent()
        val exactAlarms = canScheduleExactAlarms()
        val batteryIgnored = isBatteryOptimizationIgnored()
        val notifications = areNotificationsEnabled()
        val xiaomiLockScreen = if (xiaomi) canXiaomiShowOnLockScreen() else true
        val xiaomiBgStart = if (xiaomi) canXiaomiStartFromBackground() else true

        val isOemWithSpecialLocks = category in listOf("xiaomi", "oppo", "vivo", "huawei")

        val allCriticalGranted = drawOverlays &&
                fullScreenIntent &&
                exactAlarms &&
                notifications &&
                xiaomiLockScreen &&
                xiaomiBgStart

        return mapOf(
            "manufacturer" to category,
            "manufacturerDisplayName" to getManufacturerDisplayName(),
            "brand" to (Build.BRAND ?: ""),
            "model" to (Build.MODEL ?: ""),
            "sdkInt" to Build.VERSION.SDK_INT,
            "isXiaomi" to xiaomi,
            "isOemWithSpecialLocks" to isOemWithSpecialLocks,
            "canDrawOverlays" to drawOverlays,
            "canUseFullScreenIntent" to fullScreenIntent,
            "canScheduleExactAlarms" to exactAlarms,
            "isBatteryOptimizationIgnored" to batteryIgnored,
            "areNotificationsEnabled" to notifications,
            "xiaomiShowOnLockScreen" to xiaomiLockScreen,
            "xiaomiBackgroundStartActivity" to xiaomiBgStart,
            "allCriticalGranted" to allCriticalGranted
        )
    }

    // =========================================================================
    // Safe Intent Starters for OEM & System Settings
    // =========================================================================

    /**
     * Opens the manufacturer-specific permissions editor (e.g. Xiaomi "Other permissions",
     * Oppo/Vivo/Huawei permission manager) with resilient fallback to App Details Settings.
     */
    fun openManufacturerPermissionSettings(): Boolean {
        val pkg = context.packageName
        val category = getManufacturerCategory()
        Log.d(TAG, "Opening manufacturer permission settings for category='$category'")

        val candidateIntents = mutableListOf<Intent>()

        when (category) {
            "xiaomi" -> {
                // 1. MIUI / HyperOS PermissionsEditorActivity (Direct to "Other permissions")
                candidateIntents.add(
                    Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                        setClassName(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.permissions.PermissionsEditorActivity"
                        )
                        putExtra("extra_pkgname", pkg)
                    }
                )
                // 2. MIUI AppPermissionsEditorActivity
                candidateIntents.add(
                    Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                        setClassName(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.permissions.AppPermissionsEditorActivity"
                        )
                        putExtra("extra_pkgname", pkg)
                    }
                )
                // 3. Generic MIUI APP_PERM_EDITOR action
                candidateIntents.add(
                    Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                        putExtra("extra_pkgname", pkg)
                        putExtra("package_name", pkg)
                    }
                )
            }

            "oppo" -> {
                // ColorOS / RealmeUI / OxygenOS
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.privacypermissionsentry.PermissionTopActivity"
                        )
                    }
                )
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.permission.floatwindow.FloatWindowListActivity"
                        )
                    }
                )
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.oppo.safe",
                            "com.oppo.safe.permission.PermissionAppListActivity"
                        )
                    }
                )
            }

            "vivo" -> {
                // FuntouchOS / OriginOS
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.vivo.permissionmanager",
                            "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity"
                        )
                        putExtra("packagename", pkg)
                    }
                )
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.iqoo.secure",
                            "com.iqoo.secure.ui.phoneoptimize.FloatWindowManager"
                        )
                    }
                )
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.vivo.permissionmanager",
                            "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                        )
                    }
                )
            }

            "huawei" -> {
                // EMUI / MagicOS
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.permissionmanager.ui.MainActivity"
                        )
                    }
                )
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.systemmanager.addviewmonitor.AddViewMonitorActivity"
                        )
                    }
                )
                candidateIntents.add(
                    Intent().apply {
                        component = ComponentName(
                            "com.hihonor.systemmanager",
                            "com.hihonor.permissionmanager.ui.MainActivity"
                        )
                    }
                )
            }

            else -> {
                // Samsung, Motorola, Pixel, Stock Android
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && !canUseFullScreenIntent()) {
                    return openFullScreenIntentSettings()
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !canDrawOverlays()) {
                    return openOverlaySettings()
                }
            }
        }

        // Try each manufacturer intent in order
        for (intent in candidateIntents) {
            if (tryStartActivity(intent)) {
                return true
            }
        }

        // Final guaranteed fallback: Standard Application Details Settings
        return openAppDetailsSettings()
    }

    /**
     * Opens Android 14+ Full-Screen Intent settings, falling back to App Details.
     */
    fun openFullScreenIntentSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val intent = Intent(
                Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                Uri.parse("package:${context.packageName}")
            )
            if (tryStartActivity(intent)) return true
        }
        return openAppDetailsSettings()
    }

    /**
     * Opens SYSTEM_ALERT_WINDOW ("Display over other apps" / Sobreposição) settings.
     */
    fun openOverlaySettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}")
            )
            if (tryStartActivity(intent)) return true
        }
        return openAppDetailsSettings()
    }

    /**
     * Opens Ignore Battery Optimization prompt or list.
     */
    fun openBatteryOptimizationSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val directIntent = Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:${context.packageName}")
            )
            if (tryStartActivity(directIntent)) return true

            val listIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            if (tryStartActivity(listIntent)) return true
        }
        return openAppDetailsSettings()
    }

    /**
     * Opens Android 12+ Exact Alarm permission settings.
     */
    fun openExactAlarmSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(
                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                Uri.parse("package:${context.packageName}")
            )
            if (tryStartActivity(intent)) return true
        }
        return openAppDetailsSettings()
    }

    /**
     * Opens App Notification settings.
     */
    fun openNotificationSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            }
            if (tryStartActivity(intent)) return true
        }
        return openAppDetailsSettings()
    }

    /**
     * Universal fallback: opens Android's App Info / Details screen for this package.
     */
    fun openAppDetailsSettings(): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${context.packageName}")
        )
        return tryStartActivity(intent)
    }

    private fun tryStartActivity(intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            Log.d(TAG, "Successfully launched intent: ${intent.action ?: intent.component}")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Could not launch intent (${intent.action ?: intent.component}): ${e.message}")
            false
        }
    }
}
