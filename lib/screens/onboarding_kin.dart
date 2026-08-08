import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/locale_service.dart';
import '../services/onboarding_state.dart';
import 'bottom_nav_bar.dart' show activeTabNotifier;
import 'login_ckyc.dart';

/// First-time onboarding: confirm the customer's CKYC Identifier Number.
///
/// Sits between the mobile-number sign-in and the app. A customer signs in with
/// the number they know, then proves who they are once against the Central KYC
/// Registry record. Shown only the first time an account is opened on this
/// device — see [OnboardingState].
class OnboardingKinScreen extends StatefulWidget {
  const OnboardingKinScreen({
    super.key,
    required this.onVerified,
    this.demoHint,
  });

  /// Runs once the KIN matches. The caller decides where onboarding goes next,
  /// which keeps this screen out of the navigation decisions.
  ///
  /// Handed this screen's context, not the caller's. The screen that pushes
  /// this one is removed from the stack on the way here, so its State is
  /// disposed and any `mounted` guard in the callback is false by the time it
  /// runs — which silently did nothing and left the customer stuck here with a
  /// correct KIN and no way forward.
  final Future<void> Function(BuildContext context) onVerified;

  /// Optional hint shown under the field, for demo builds.
  final String? demoHint;

  @override
  State<OnboardingKinScreen> createState() => _OnboardingKinScreenState();
}

class _OnboardingKinScreenState extends State<OnboardingKinScreen> {
  final _kinController = TextEditingController();
  bool _busy = false;
  String? _error;

  /// The registry issues a 10-digit KIN for these accounts.
  static const int _kinLength = 10;

  @override
  void dispose() {
    _kinController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy && _kinController.text.trim().length == _kinLength;

  Future<void> _verify() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final failure =
        await ApiService.instance.verifyKin(_kinController.text.trim());
    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _error = failure;
        _busy = false;
      });
      return;
    }

    await OnboardingState.markKinVerified();
    if (!mounted) return;
    await widget.onVerified(context);
  }

  /// Leaves onboarding and returns to sign-in.
  ///
  /// This screen replaces the whole stack, so without this there is no back
  /// button, no tab bar and no way out: a customer who cannot complete the
  /// check — wrong KIN, server unreachable — was trapped with the app unusable
  /// until they cleared its data.
  Future<void> _backToSignIn() async {
    await ApiService.instance.clearSession();
    if (!mounted) return;
    activeTabNotifier.value = 'ekyc';
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const MobileDeviceFrame(child: LoginCkycScreen()),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: Color(0xFF2E75B6), size: 26),
              ),
              const SizedBox(height: 20),
              Text(
                tr('Confirm your identity'),
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF0B2545),
                  letterSpacing: -0.52,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Enter your CKYC Identifier Number (KIN) to finish setting '
                    'up. We check it against your record in the Central KYC '
                    'Registry. You will only be asked once.'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.55,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                tr('KIN'),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _error != null
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _kinController,
                  keyboardType: TextInputType.number,
                  // Digits only: the registry issues a digit string, and the
                  // backend strips grouping anyway.
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_kinLength),
                  ],
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _verify(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••••',
                    hintStyle: GoogleFonts.spaceMono(
                      fontSize: 16,
                      color: const Color(0xFFCBD5E1),
                      letterSpacing: 1.5,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 15, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.45,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2545),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          tr('Confirm and continue'),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('Your KIN is on your CKYC record. If you do not have it to '
                    'hand, your branch can confirm it.'),
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  height: 1.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              if (widget.demoHint != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.demoHint!,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.5,
                      color: const Color(0xFF2E75B6),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Always reachable: this screen owns the whole stack, so without
              // a way back a failed check leaves the app unusable.
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _backToSignIn,
                  child: Text(
                    tr('Use a different number'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
