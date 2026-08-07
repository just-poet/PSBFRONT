import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Raises real system notifications on the phone's status bar.
///
/// Local, not push: the app raises these itself when something happens while it
/// is running — a payment settles, money arrives, a freeze is applied, a
/// phishing SMS is caught. That needs no Firebase project, no device-token
/// storage and no server push, and it works with no network.
///
/// The trade-off is honest: nothing arrives while the app is closed. The
/// in-app feed at /v1/notifications remains the complete record.
class FinixNotifications {
  FinixNotifications._();
  static final FinixNotifications instance = FinixNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Separate channels so the customer can silence marketing-ish notices
  /// without losing security alerts, from Android's own settings.
  static const AndroidNotificationDetails _securityChannel =
      AndroidNotificationDetails(
    'finix_security',
    'Security alerts',
    channelDescription:
        'Frozen accounts, blocked payments and flagged messages.',
    importance: Importance.max,
    priority: Priority.high,
  );

  static const AndroidNotificationDetails _moneyChannel =
      AndroidNotificationDetails(
    'finix_money',
    'Payments',
    channelDescription: 'Money sent and received.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (_) {
      // No native implementation (desktop/web tests): stay silent rather than
      // failing a screen that only wanted to post a notice.
      _ready = false;
    }
  }

  /// Asks for POST_NOTIFICATIONS.
  ///
  /// Required from Android 13. Requested from an explicit user action rather
  /// than at launch, so the prompt arrives with context.
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Posts a notification. Silently does nothing when permission was refused,
  /// so callers never have to guard.
  Future<void> show({
    required String title,
    required String body,
    bool security = false,
  }) async {
    await init();
    if (!_ready) return;
    if (!await hasPermission()) return;

    try {
      await _plugin.show(
        // Unique per notification so several can stack rather than replacing
        // one another.
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: security ? _securityChannel : _moneyChannel,
        ),
      );
    } catch (e) {
      debugPrint('notification failed: $e');
    }
  }

  // ─── The events worth interrupting someone for ────────────────────────

  Future<void> moneyReceived(String amount, String from) => show(
        title: 'Money received',
        body: '$from sent you $amount',
      );

  Future<void> moneySent(String amount, String to) => show(
        title: 'Payment sent',
        body: '$amount to $to',
      );

  Future<void> paymentBlocked(String amount, String reason) => show(
        title: 'Payment blocked',
        body: '$amount held. $reason',
        security: true,
      );

  Future<void> accountFrozen() => show(
        title: 'Account frozen',
        body: 'All outgoing payments are halted.',
        security: true,
      );

  Future<void> accountUnfrozen() => show(
        title: 'Account unfrozen',
        body: 'Payments are working again.',
        security: true,
      );

  Future<void> phishingCaught(String sender) => show(
        title: 'Phishing message blocked',
        body: 'A message from $sender looks fraudulent.',
        security: true,
      );
}
