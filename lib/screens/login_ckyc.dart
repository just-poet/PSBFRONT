import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/hardware_service.dart';
import '../services/onboarding_state.dart';
import 'ekyc.dart';
import 'home_dashboard.dart';
import 'onboarding_kin.dart';
import 'smooth_route.dart';

/// Sign in with the 10-digit Central KYC (cKYC) number and the 6-digit PIN.
///
/// cKYC replaces the phone number as the login handle, so a demo needs no real
/// mobile. A failed sign-in surfaces the backend's reason instead of falling
/// through to mock data — otherwise the app would look logged in while every
/// later screen quietly rendered fake numbers.
class LoginCkycScreen extends StatefulWidget {
  const LoginCkycScreen({super.key});

  @override
  State<LoginCkycScreen> createState() => _LoginCkycScreenState();
}

class _LoginCkycScreenState extends State<LoginCkycScreen> {
  /// Mobile number. Customers know their phone number; almost nobody knows
  /// their CKYC number, which made the old field a barrier at the front door.
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();

  bool _busy = false;
  bool _obscurePin = true;
  String? _error;

  /// Indian mobile numbers are ten digits; the +91 is fixed in the prefix.
  static const int _phoneLength = 10;
  static const int _pinLength = 6;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _phoneController.text.trim().length == _phoneLength &&
      _pinController.text.trim().length == _pinLength &&
      !_busy;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await ApiService.instance.loginWithPhone(
        _phoneController.text.trim(),
        _pinController.text.trim(),
      );
      if (!mounted) return;

      final name = (result['name'] ?? '').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            name.isEmpty ? 'Signed in' : 'Welcome back, $name',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0B2545),
        ),
      );

      // Biometric enrolment sits between authentication and the dashboard:
      // the PIN proves the credential, the fingerprint binds the session to
      // the person holding the phone. Skipped silently where the device has no
      // sensor, so a customer on such a handset is not blocked at the door.
      final outcome = await FinixBiometric.verify(
        reason: 'Confirm your fingerprint to finish signing in',
      );
      if (!mounted) return;
      if (outcome == BiometricOutcome.failed) {
        setState(() {
          _error = 'Fingerprint not recognised. Try again.';
          _busy = false;
        });
        return;
      }

      // First-time customers confirm their KIN before the app opens. Scoped to
      // the customer who just signed in, so a shared handset does not let one
      // person inherit another's completed onboarding.
      OnboardingState.currentCustomerKey =
          (result['userId'] ?? result['ckyc'] ?? _phoneController.text.trim())
              .toString();
      if (await OnboardingState.needsKinVerification()) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          SmoothPageRoute(
            settings: const RouteSettings(name: '/onboarding-kin'),
            builder: (_) => MobileDeviceFrame(
              child: OnboardingKinScreen(
                demoHint: _demoKinHint(_phoneController.text.trim()),
                // Navigates from the KIN screen's own context: this route
                // removes the sign-in screen, so anything closing over this
                // State runs after it has been disposed.
                onVerified: (kinContext) async => _openDashboard(kinContext),
              ),
            ),
          ),
          (route) => false,
        );
        return;
      }

      if (!mounted) return;
      _openDashboard(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The KIN held on each demo account, keyed by mobile number.
  ///
  /// Demo affordance only, alongside the seeded PIN hint on this screen: the
  /// KIN is checked against the customer's real CKYC record, and there is no
  /// way to discover it from inside the app. Without this the first-time flow
  /// cannot be demonstrated at all.
  static const Map<String, String> _demoKins = {
    '9983692606': '2000000001', // Jiyad
    '6303891930': '2000000002', // Venkat
    '8175065652': '2000000003', // RD Shubham
    '9876543210': '2000000004', // Arjun Reddy
    '9876543211': '2000000005', // Priya Sharma
    '9876543212': '2000000006', // Karthik Iyer
    '9876543213': '2000000007', // Sneha Patel
    '9876543214': '2000000008', // Ravi Kumar
    '9876543215': '2000000009', // Ananya Gupta
    '9876543216': '2000000010', // Mohammed Ali
  };

  static String? _demoKinHint(String phone) {
    // Tolerates a +91 or 0 prefix, the same shapes the backend normalises.
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(digits.length - 10);
    final kin = _demoKins[digits];
    if (kin == null) return null;
    return 'Demo account: your KIN is $kin';
  }

  /// Opens the app, replacing the whole stack.
  ///
  /// Shared by both routes in: a returning customer straight after biometrics,
  /// and a first-time customer once their KIN is confirmed. Takes the context
  /// to navigate from, because the KIN screen calls this after the sign-in
  /// screen has been removed from the stack and disposed.
  void _openDashboard(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      SmoothPageRoute(
        // The bottom navigation bar hides itself while the active tab is
        // 'ekyc', which the navigator observer sets for the initial '/'
        // route so the sign-in screen has no chrome. Without a route name
        // here the observer never runs, the tab stays 'ekyc', and the bar
        // stays hidden for the rest of the session.
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const MobileDeviceFrame(child: HomeDashboardScreen()),
      ),
      (route) => false,
    );
  }

  /// Lets a tester point the app at a different backend (a tunnel URL, a LAN
  /// address) without a rebuild. Essential when the APK is shared with people
  /// on other networks.
  Future<void> _editServerAddress() async {
    final controller = TextEditingController(text: ApiService.instance.baseUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('API address'),
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'https://example.trycloudflare.com',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Use the https address of the FINIX backend. Plain http works '
              'only for hosts allowed in the network security config.',
              style: GoogleFonts.inter(
                  fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('Cancel'), style: GoogleFonts.inter(fontSize: 13)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(tr('Save'),
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (url == null || url.isEmpty) return;
    // Strip a trailing slash: every call appends an absolute path, so leaving
    // it produces //v1/... which some proxies reject.
    await ApiService.instance
        .setBaseUrl(url.endsWith('/') ? url.substring(0, url.length - 1) : url);
    if (!mounted) return;
    final reachable = await ApiService.instance.checkConnection();
    if (!mounted) return;
    setState(() => _error = reachable ? null : 'Cannot reach $url');
    if (reachable) _showConnected();
  }

  void _showConnected() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected to ${ApiService.instance.baseUrl}',
            style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2545),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_rounded,
                        color: Colors.white, size: 26),
                  ),
                  // Connection state doubles as the entry point for changing
                  // the API address, so a tester can always see and fix where
                  // the app is pointing.
                  ValueListenableBuilder<bool>(
                    valueListenable: ApiService.instance.isConnected,
                    builder: (context, connected, _) => TextButton.icon(
                      onPressed: _busy ? null : _editServerAddress,
                      icon: Icon(
                        connected
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        size: 16,
                        color: connected
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                      label: Text(
                        connected ? 'Connected' : 'Set server',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: connected
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                tr('Sign in to FINIX'),
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A1628),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use your 10-digit Central KYC number and your 6-digit PIN.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),

              const _FieldLabel('MOBILE NUMBER'),
              const SizedBox(height: 8),
              _InputBox(
                // Country code shown as a fixed prefix rather than something to
                // type: it is the same for every customer, and leaving it in
                // the field is how people end up entering 12 digits.
                child: Row(
                  children: [
                    Text(
                      '+91',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_phoneLength),
                        ],
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) => _pinFocus.requestFocus(),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: const Color(0xFF0B2545),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: '99836 92606',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFFCBD5E1),
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const _FieldLabel('6-DIGIT PIN'),
              const SizedBox(height: 8),
              _InputBox(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pinController,
                        focusNode: _pinFocus,
                        keyboardType: TextInputType.number,
                        obscureText: _obscurePin,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_pinLength),
                        ],
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) => _submit(),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 6,
                          color: const Color(0xFF0B2545),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: '••••••',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFFCBD5E1),
                            letterSpacing: 6,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _obscurePin = !_obscurePin),
                      child: Icon(
                        _obscurePin
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.45,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2545),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        tr('Sign in'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _busy
                      ? null
                      : () => Navigator.push(
                            context,
                            SmoothPageRoute(
                              settings: const RouteSettings(name: '/ekyc'),
                              builder: (_) =>
                                  const MobileDeviceFrame(child: EkycScreen()),
                            ),
                          ),
                  child: Text.rich(
                    TextSpan(
                      text: tr('New to FINIX?  '),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                      children: [
                        TextSpan(
                          text: tr('Complete eKYC'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0B2545),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
              // Demo aid: the seeded accounts print their CKYC numbers in the
              // backend log at startup; the first one is shown here so the demo
              // can be driven without leaving the app.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo: 9983692606 (Jiyad) or 6303891930 (Venkat), PIN 123456. '
                        'Tap to fill the first one.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.45,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _phoneController.text = '9983692606';
                                _pinController.text = '123456';
                                _error = null;
                              }),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        tr('Fill'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.55,
          color: const Color(0xFF475569),
        ),
      );
}

class _InputBox extends StatelessWidget {
  final Widget child;
  const _InputBox({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: child,
      );
}
