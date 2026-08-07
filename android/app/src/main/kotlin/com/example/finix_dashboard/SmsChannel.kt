package com.example.finix_dashboard

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads the device inbox so the security screen can scan real messages for
 * fraud instead of rendering a fixed list of invented examples.
 *
 * Only the inbox is read, only sender/body/timestamp are returned, and nothing
 * is cached natively — the Dart layer decides what, if anything, is sent to the
 * backend scanner. Sent messages, drafts and MMS are never touched.
 *
 * READ_SMS is a Play-restricted permission. This build is distributed by
 * sideload; listing on Play would require an approved use-case declaration.
 */
class SmsChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.finix.hardware/sms"

        /** Cap on how many messages are handed to Dart in one call. */
        private const val DEFAULT_LIMIT = 50
        private const val MAX_LIMIT = 200
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(hasReadSmsPermission())
            "readInbox" -> readInbox(call, result)
            else -> result.notImplemented()
        }
    }

    private fun hasReadSmsPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.READ_SMS) ==
            PackageManager.PERMISSION_GRANTED

    private fun readInbox(call: MethodCall, result: MethodChannel.Result) {
        // The permission is requested from Dart via permission_handler. Querying
        // without it throws SecurityException, so fail with a code the Dart side
        // can distinguish from a genuine read error.
        if (!hasReadSmsPermission()) {
            result.error("PERMISSION_DENIED", "READ_SMS has not been granted", null)
            return
        }

        val limit = (call.argument<Int>("limit") ?: DEFAULT_LIMIT).coerceIn(1, MAX_LIMIT)

        val projection = arrayOf(
            Telephony.Sms.Inbox._ID,
            Telephony.Sms.Inbox.ADDRESS,
            Telephony.Sms.Inbox.BODY,
            Telephony.Sms.Inbox.DATE,
        )

        val messages = mutableListOf<Map<String, Any?>>()

        try {
            context.contentResolver.query(
                Telephony.Sms.Inbox.CONTENT_URI,
                projection,
                null,
                null,
                "${Telephony.Sms.Inbox.DATE} DESC LIMIT $limit",
            )?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(Telephony.Sms.Inbox._ID)
                val addressCol = cursor.getColumnIndexOrThrow(Telephony.Sms.Inbox.ADDRESS)
                val bodyCol = cursor.getColumnIndexOrThrow(Telephony.Sms.Inbox.BODY)
                val dateCol = cursor.getColumnIndexOrThrow(Telephony.Sms.Inbox.DATE)

                while (cursor.moveToNext() && messages.size < limit) {
                    messages.add(
                        mapOf(
                            "id" to cursor.getString(idCol),
                            "sender" to (cursor.getString(addressCol) ?: ""),
                            "body" to (cursor.getString(bodyCol) ?: ""),
                            // Epoch millis; Dart converts to local time.
                            "timestamp" to cursor.getLong(dateCol),
                        )
                    )
                }
            }
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
            return
        } catch (e: Exception) {
            result.error("READ_FAILED", e.message, null)
            return
        }

        result.success(messages)
    }
}
