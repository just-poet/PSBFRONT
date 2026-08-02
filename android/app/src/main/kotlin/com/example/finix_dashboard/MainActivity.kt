package com.example.finix_dashboard

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Host activity plus the native side of the device-attestation channel.
 *
 * `services/hardware_service.dart` calls `com.finix.hardware/device` to build the
 * device fingerprint that binds a FINIX session to one handset. With no native
 * handler the Dart layer caught MissingPluginException and fell back to a
 * hard-coded constant, so every install produced the SAME fingerprint and
 * device binding was decorative. The handler below returns real device values.
 *
 * Deliberately permission-free: ANDROID_ID is per-app-per-device (and resets on
 * factory reset), which is the identifier Google recommends for this purpose.
 * No IMEI / MAC / serial is read, so nothing here needs a runtime permission or
 * trips Play policy restrictions.
 *
 * The biometric channel (`com.finix.hardware/biometric`) is handled by
 * [BiometricChannel], which issues real Keystore/StrongBox P-256 keys gated by
 * BiometricPrompt.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val DEVICE_CHANNEL = "com.finix.hardware/device"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceFingerprint" -> result.success(deviceFingerprint())
                    else -> result.notImplemented()
                }
            }

        // Hardware-backed biometric signing (see BiometricChannel).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BiometricChannel.CHANNEL)
            .setMethodCallHandler(BiometricChannel(this))
    }

    /**
     * Stable, permission-free device characteristics.
     *
     * Every value must survive an app restart: the Dart layer hashes the whole
     * map into the fingerprint, so anything volatile (uptime, free space) would
     * change the hash on each launch and break device binding. `systemUptime`
     * is therefore reported as a constant, kept only for shape compatibility
     * with the web fallback.
     */
    private fun deviceFingerprint(): Map<String, Any> {
        val androidId = try {
            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: ""
        } catch (_: Exception) {
            ""
        }

        val metrics = resources.displayMetrics

        return mapOf(
            "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "osVersion" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "systemUptime" to 0,
            "identifierForVendor" to androidId,
            "hardwareUUID" to androidId,
            "secureEnclaveAvailable" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P),
            "biometricType" to "fingerprint",
            "screenResolution" to "${metrics.widthPixels}x${metrics.heightPixels}",
            "totalDiskSpace" to totalDiskSpace(),
            "buildTags" to Build.TAGS.orEmpty(),
            // Surfaced so the backend risk model can weigh an emulator or a
            // test-keys build instead of trusting it blindly.
            "isEmulator" to isProbablyEmulator(),
        )
    }

    /** Total (not free) space: capacity is a device trait, free space is not. */
    private fun totalDiskSpace(): Long = try {
        filesDir.totalSpace
    } catch (_: Exception) {
        0L
    }

    private fun isProbablyEmulator(): Boolean {
        val fp = Build.FINGERPRINT.lowercase()
        return fp.startsWith("generic") ||
            fp.contains("vbox") ||
            fp.contains("emulator") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for") ||
            Build.MANUFACTURER.contains("Genymotion") ||
            Build.PRODUCT == "google_sdk"
    }
}
