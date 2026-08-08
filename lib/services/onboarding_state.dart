import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the customer has completed first-time onboarding.
///
/// The KIN step is asked once, not at every sign-in: it confirms identity when
/// an account is first opened on a device, and repeating it on every login
/// would be a checkpoint with nothing left to establish.
///
/// Keyed per customer rather than a single flag, so a shared or demo handset
/// that signs in as somebody else still onboards that person properly instead
/// of inheriting the previous customer's completed state.
class OnboardingState {
  const OnboardingState._();

  static const String _prefix = 'finix.onboarding.kin.';

  /// Set by the sign-in screen once the customer is authenticated, so the
  /// flag can be scoped without threading an id through every call.
  static String? currentCustomerKey;

  static String? _key() {
    final id = currentCustomerKey?.trim();
    if (id == null || id.isEmpty) return null;
    return '$_prefix$id';
  }

  /// Whether this customer still needs to confirm their KIN on this device.
  ///
  /// Defaults to needing it: if the stored flag cannot be read, asking again
  /// is a repeated step, whereas skipping it would let the check be bypassed
  /// by clearing app storage.
  static Future<bool> needsKinVerification() async {
    final key = _key();
    if (key == null) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(key) ?? false);
    } catch (_) {
      return true;
    }
  }

  static Future<void> markKinVerified() async {
    final key = _key();
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {
      // Not fatal: the customer completes onboarding either way and is asked
      // again next time, which is the safe direction to fail in.
    }
  }

  /// Clears the flag for a customer. Used when signing out of an account for
  /// good, and by tests.
  static Future<void> reset() async {
    final key = _key();
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
