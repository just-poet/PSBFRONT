import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// One message read from the device inbox.
class DeviceSms {
  final String id;
  final String sender;
  final String body;
  final DateTime? receivedAt;

  const DeviceSms({
    required this.id,
    required this.sender,
    required this.body,
    this.receivedAt,
  });

  factory DeviceSms.fromMap(Map<dynamic, dynamic> map) {
    final millis = map['timestamp'];
    return DeviceSms(
      id: (map['id'] ?? '').toString(),
      sender: (map['sender'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      receivedAt: millis is int
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : null,
    );
  }
}

/// Why an inbox read produced nothing, so the UI can say something useful
/// instead of showing an empty list that looks like a bug.
enum SmsAccess {
  granted,

  /// The user said no, but can be asked again.
  denied,

  /// The user selected "don't ask again", or policy blocks it. Only the app
  /// settings screen can change this now.
  permanentlyDenied,

  /// No native implementation — desktop, web, or iOS, where reading the SMS
  /// inbox is not possible at all.
  unsupported,
}

class SmsReadResult {
  final SmsAccess access;
  final List<DeviceSms> messages;

  /// How many OTP messages were read and deliberately skipped.
  final int skippedOtp;

  const SmsReadResult(this.access, this.messages, {this.skippedOtp = 0});
}

/// Reads the device SMS inbox via the native channel in [SmsChannel.kt].
///
/// The security screen used to display three invented messages — a fake SBI
/// phishing text, an Axis OTP and a Zomato delivery notice — identical on every
/// device, which demonstrated nothing about the customer's actual exposure.
class FinixSms {
  static const MethodChannel _channel = MethodChannel('com.finix.hardware/sms');

  /// Requests READ_SMS if it is not already held.
  ///
  /// READ_SMS is a Play-restricted permission; this build is sideloaded. The
  /// prompt is only ever raised from an explicit user action on the security
  /// screen, never on launch.
  static Future<SmsAccess> requestAccess() async {
    try {
      var status = await Permission.sms.status;
      if (status.isGranted) return SmsAccess.granted;

      if (status.isPermanentlyDenied) return SmsAccess.permanentlyDenied;

      status = await Permission.sms.request();
      if (status.isGranted) return SmsAccess.granted;
      if (status.isPermanentlyDenied || status.isRestricted) {
        return SmsAccess.permanentlyDenied;
      }
      return SmsAccess.denied;
    } on MissingPluginException {
      return SmsAccess.unsupported;
    } catch (_) {
      // permission_handler has no implementation on desktop/web.
      return SmsAccess.unsupported;
    }
  }

  /// Matches one-time-password messages.
  ///
  /// OTPs are excluded from the scanner deliberately. They are the single most
  /// sensitive class of message on the device, they are worthless to scan (a
  /// genuine OTP and a phished one read identically), and sending their
  /// contents to a backend for analysis would put live authentication codes on
  /// the wire. Phishing messages that merely *mention* an OTP are still
  /// scanned — this only skips messages that are an OTP delivery.
  static final RegExp _otpPattern = RegExp(
    r'\b(otp|one[\s-]?time\s?(password|passcode|pin)|verification code|'
    r'security code|auth(entication)? code)\b',
    caseSensitive: false,
  );

  /// True when [body] looks like an OTP delivery rather than a normal message.
  static bool isOtpMessage(String body) {
    if (!_otpPattern.hasMatch(body)) return false;
    // An OTP message always carries the code itself: 4-8 digits standing alone.
    return RegExp(r'(^|[^0-9])[0-9]{4,8}([^0-9]|$)').hasMatch(body);
  }

  /// Reads the most recent inbox messages, newest first.
  ///
  /// OTP deliveries are filtered out; [SmsReadResult.skippedOtp] reports how
  /// many were skipped so the UI can say so rather than appearing to have
  /// missed them.
  ///
  /// Returns the access state alongside the messages so a caller can tell an
  /// empty inbox apart from a refused permission.
  static Future<SmsReadResult> readInbox({int limit = 30}) async {
    final access = await requestAccess();
    if (access != SmsAccess.granted) {
      return SmsReadResult(access, const []);
    }

    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'readInbox',
        {'limit': limit},
      );
      final all = (raw ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map(DeviceSms.fromMap)
          .where((m) => m.body.trim().isNotEmpty)
          .toList();

      final messages = all.where((m) => !isOtpMessage(m.body)).toList();
      return SmsReadResult(
        SmsAccess.granted,
        messages,
        skippedOtp: all.length - messages.length,
      );
    } on MissingPluginException {
      return const SmsReadResult(SmsAccess.unsupported, []);
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        return const SmsReadResult(SmsAccess.denied, []);
      }
      return const SmsReadResult(SmsAccess.unsupported, []);
    }
  }

  /// Opens the OS app-settings page, the only route back from a permanent
  /// denial.
  static Future<void> openSettings() => openAppSettings();
}
