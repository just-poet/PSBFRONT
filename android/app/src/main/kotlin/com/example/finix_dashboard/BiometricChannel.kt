package com.example.finix_dashboard

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.interfaces.ECPublicKey

/**
 * Native side of `com.finix.hardware/biometric`.
 *
 * Replaces the Dart mock signer with real hardware-backed keys:
 *
 *  - the P-256 key pair lives in the Android Keystore, in StrongBox when the
 *    device has it, and is marked `setUserAuthenticationRequired(true)` so the
 *    private key is unusable until a biometric unlocks it. The key material
 *    never enters app memory;
 *  - signing goes through BiometricPrompt with a CryptoObject, so the prompt
 *    and the signature are cryptographically bound — an attacker cannot skip
 *    the prompt and sign anyway;
 *  - `setInvalidatedByBiometricEnrollment(true)` destroys the key if a new
 *    fingerprint/face is enrolled, so an attacker who adds their own biometric
 *    cannot inherit the victim's key.
 *
 * Wire format matches the backend exactly (internal/domain/security/webauthn.go):
 *  - public key: uncompressed SEC1 point `0x04 || X(32) || Y(32)`, base64
 *  - signature:  ASN.1 DER ECDSA, base64, over SHA-256 of the challenge
 */
class BiometricChannel(private val activity: FragmentActivity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.finix.hardware/biometric"
        private const val KEYSTORE = "AndroidKeyStore"
        private const val KEY_PREFIX = "finix_biometric_"
        private const val SIGN_ALGO = "SHA256withECDSA"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "registerKeyPair" -> registerKeyPair(result)
            "signChallenge" -> signChallenge(call, result)
            "authenticate" -> authenticate(call, result)
            "getBiometricType" -> result.success(biometricType())
            else -> result.notImplemented()
        }
    }

    // ── Key registration ────────────────────────────────────────────────

    private fun registerKeyPair(result: MethodChannel.Result) {
        if (!canAuthenticate()) {
            result.error("NO_BIOMETRIC", "No biometric is enrolled on this device", null)
            return
        }

        val keyId = KEY_PREFIX + System.currentTimeMillis()
        try {
            val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, KEYSTORE)
            val builder = KeyGenParameterSpec.Builder(keyId, KeyProperties.PURPOSE_SIGN)
                .setAlgorithmParameterSpec(java.security.spec.ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setUserAuthenticationRequired(true)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Drop the key if biometrics are re-enrolled: a newly added
                // fingerprint must not gain access to the existing key.
                builder.setInvalidatedByBiometricEnrollment(true)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                // Prefer the dedicated secure element; fall back below if the
                // device advertises StrongBox but cannot honour this spec.
                builder.setIsStrongBoxBacked(true)
            }

            val keyPair = try {
                generator.initialize(builder.build())
                generator.generateKeyPair()
            } catch (_: Exception) {
                // StrongBox unavailable in practice — retry in the TEE.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    builder.setIsStrongBoxBacked(false)
                }
                generator.initialize(builder.build())
                generator.generateKeyPair()
            }

            val publicKey = keyPair.public as ECPublicKey
            result.success(
                mapOf(
                    "publicKey" to Base64.encodeToString(sec1Uncompressed(publicKey), Base64.NO_WRAP),
                    "keyId" to keyId,
                )
            )
        } catch (e: Exception) {
            result.error("KEYGEN_FAILED", e.message ?: "Could not create a hardware key", null)
        }
    }

    /**
     * Encodes a P-256 public key as the uncompressed SEC1 point the backend
     * parses. X and Y are left-padded to exactly 32 bytes each: BigInteger
     * drops leading zeros and adds a sign byte, so a raw toByteArray() would
     * produce a 31- or 33-byte coordinate and fail verification intermittently.
     */
    private fun sec1Uncompressed(key: ECPublicKey): ByteArray {
        val out = ByteArray(65)
        out[0] = 0x04
        writeFixed(key.w.affineX.toByteArray(), out, 1)
        writeFixed(key.w.affineY.toByteArray(), out, 33)
        return out
    }

    private fun writeFixed(value: ByteArray, dest: ByteArray, offset: Int) {
        // Strip a leading sign byte, then right-align into the 32-byte slot.
        val start = if (value.size > 32) value.size - 32 else 0
        val length = minOf(value.size, 32)
        System.arraycopy(value, start, dest, offset + (32 - length), length)
    }

    // ── Signing ─────────────────────────────────────────────────────────

    private fun signChallenge(call: MethodCall, result: MethodChannel.Result) {
        val challenge = call.argument<String>("challenge").orEmpty()
        val keyId = call.argument<String>("keyId").orEmpty()
        if (challenge.isEmpty() || keyId.isEmpty()) {
            result.error("BAD_ARGS", "challenge and keyId are required", null)
            return
        }

        val signature = try {
            val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
            val privateKey = keyStore.getKey(keyId, null) as? java.security.PrivateKey
                ?: run {
                    result.error("KEY_NOT_FOUND", "No hardware key for $keyId", null)
                    return
                }
            Signature.getInstance(SIGN_ALGO).apply { initSign(privateKey) }
        } catch (e: Exception) {
            // Thrown when the key was invalidated by a biometric re-enrollment.
            result.error("KEY_UNUSABLE", e.message ?: "Key unusable; re-register biometrics", null)
            return
        }

        prompt(
            title = "Confirm it's you",
            subtitle = "Authorise this request with your biometric",
            crypto = BiometricPrompt.CryptoObject(signature),
            onError = { code, msg -> result.error(code, msg, null) },
            onSuccess = { crypto ->
                try {
                    val signer = crypto?.signature ?: signature
                    signer.update(challengeBytes(challenge))
                    // Signature.sign() already emits ASN.1 DER, which is what
                    // ecdsa.VerifyASN1 on the server expects.
                    result.success(Base64.encodeToString(signer.sign(), Base64.NO_WRAP))
                } catch (e: Exception) {
                    result.error("SIGN_FAILED", e.message ?: "Signing failed", null)
                }
            },
        )
    }

    /**
     * The server signs over the raw challenge bytes. The Dart layer carries the
     * challenge as a string, so accept base64 (how the API delivers it) and
     * fall back to UTF-8 for a plain-text challenge.
     */
    private fun challengeBytes(challenge: String): ByteArray = try {
        Base64.decode(challenge, Base64.DEFAULT)
    } catch (_: IllegalArgumentException) {
        challenge.toByteArray(Charsets.UTF_8)
    }

    // ── Plain authentication ────────────────────────────────────────────

    private fun authenticate(call: MethodCall, result: MethodChannel.Result) {
        if (!canAuthenticate()) {
            result.error("NO_BIOMETRIC", "No biometric is enrolled on this device", null)
            return
        }
        prompt(
            title = "Verify your identity",
            subtitle = call.argument<String>("reason") ?: "Authenticate to continue",
            crypto = null,
            onError = { code, msg -> result.error(code, msg, null) },
            onSuccess = { result.success(true) },
        )
    }

    // ── BiometricPrompt plumbing ────────────────────────────────────────

    private fun prompt(
        title: String,
        subtitle: String,
        crypto: BiometricPrompt.CryptoObject?,
        onError: (String, String) -> Unit,
        onSuccess: (BiometricPrompt.CryptoObject?) -> Unit,
    ) {
        // BiometricPrompt must be built and shown on the main thread.
        activity.runOnUiThread {
            val callback = object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(res: BiometricPrompt.AuthenticationResult) =
                    onSuccess(res.cryptoObject)

                override fun onAuthenticationError(code: Int, message: CharSequence) {
                    val key = when (code) {
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                        -> "USER_CANCELED"
                        BiometricPrompt.ERROR_LOCKOUT,
                        BiometricPrompt.ERROR_LOCKOUT_PERMANENT,
                        -> "LOCKED_OUT"
                        else -> "AUTH_ERROR"
                    }
                    onError(key, message.toString())
                }
                // onAuthenticationFailed (a rejected finger) is deliberately not
                // terminal: the prompt stays up so the user can retry.
            }

            val prompt = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback)
            val info = BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setSubtitle(subtitle)
                .setNegativeButtonText("Cancel")
                .setConfirmationRequired(true)
                .build()

            try {
                if (crypto != null) prompt.authenticate(info, crypto) else prompt.authenticate(info)
            } catch (e: Exception) {
                onError("PROMPT_FAILED", e.message ?: "Could not show the biometric prompt")
            }
        }
    }

    private fun canAuthenticate(): Boolean =
        BiometricManager.from(activity)
            .canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) ==
            BiometricManager.BIOMETRIC_SUCCESS

    private fun biometricType(): String {
        val manager = BiometricManager.from(activity)
        if (manager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) !=
            BiometricManager.BIOMETRIC_SUCCESS
        ) {
            return "none"
        }
        val pm = activity.packageManager
        return when {
            pm.hasSystemFeature(android.content.pm.PackageManager.FEATURE_FACE) -> "face"
            pm.hasSystemFeature(android.content.pm.PackageManager.FEATURE_IRIS) -> "iris"
            else -> "fingerprint"
        }
    }
}
