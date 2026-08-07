import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helplines and portals the app points customers at.
///
/// Kept in one place so a number cannot drift between screens — a fraud screen
/// showing a stale helpline is worse than showing none.
class FinixContacts {
  const FinixContacts._();

  /// National Cyber Crime helpline. The number to call in the first hour of a
  /// financial fraud, when funds can still be held.
  static const String cyberCrimeHelpline = '1930';

  /// National Cyber Crime Reporting Portal, run by I4C under the MHA.
  static const String cyberCrimePortal = 'https://i4c.mha.gov.in/ncrp.aspx';

  /// Punjab & Sind Bank's toll-free customer helpline.
  static const String bankHelpline = '1800 419 8300';
}

/// Opens the dialer, the browser and other external handlers.
class FinixLauncher {
  const FinixLauncher._();

  /// Opens the phone dialer with [number] pre-filled.
  ///
  /// Uses `tel:` rather than placing the call: dialling straight from an app
  /// needs CALL_PHONE, and a customer reporting a fraud should see the number
  /// before it rings. Spaces and punctuation are stripped, since `tel:` only
  /// accepts digits and a leading +.
  static Future<void> dial(BuildContext context, String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: digits);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);

    if (!opened && context.mounted) {
      // A tablet with no dialer, or a blocked intent. Show the number so it can
      // still be dialled by hand rather than failing silently.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the dialer. Call $number')),
      );
    }
  }

  /// Opens [url] in the browser.
  static Future<void> open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}
