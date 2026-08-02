import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/api_service.dart';
import 'ekyc.dart';
import 'home_dashboard.dart';
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
  final _ckycController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();

  bool _busy = false;
  bool _obscurePin = true;
  String? _error;

  static const int _ckycLength = 10;
  static const int _pinLength = 6;

  @override
  void dispose() {
    _ckycController.dispose();
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _ckycController.text.trim().length == _ckycLength &&
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
      final result = await ApiService.instance.loginWithCkyc(
        _ckycController.text.trim(),
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

      Navigator.pushAndRemoveUntil(
        context,
        SmoothPageRoute(
          builder: (_) => const MobileDeviceFrame(child: HomeDashboardScreen()),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              const SizedBox(height: 22),
              Text(
                'Sign in to FINIX',
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

              const _FieldLabel('CKYC NUMBER'),
              const SizedBox(height: 8),
              _InputBox(
                child: TextField(
                  controller: _ckycController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_ckycLength),
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
                    hintText: '2000000001',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFFCBD5E1),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                    counterText: '',
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Sign in',
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
                              builder: (_) =>
                                  const MobileDeviceFrame(child: EkycScreen()),
                            ),
                          ),
                  child: Text.rich(
                    TextSpan(
                      text: 'New to FINIX?  ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                      children: [
                        TextSpan(
                          text: 'Complete eKYC',
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
                        'Demo accounts: CKYC 2000000001 – 2000000010, PIN 123456. '
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
                                _ckycController.text = '2000000001';
                                _pinController.text = '123456';
                                _error = null;
                              }),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Fill',
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
