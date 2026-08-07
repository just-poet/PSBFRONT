import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

class PinScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final double amount;
  final VoidCallback onSuccess;

  /// Runs after the PIN is accepted but *before* the success animation.
  ///
  /// Return false to abandon without celebrating — a payment the risk engine
  /// flagged, or one the customer then cancelled. Without this the screen
  /// played "Authorising…" and a success tick for 2.2s and only then handed
  /// control back, so the customer watched a payment succeed and was told
  /// afterwards that it looked risky.
  ///
  /// Optional: call sites that have nothing to check leave it null and keep the
  /// original behaviour.
  final Future<bool> Function()? onAuthorise;

  const PinScreen({
    super.key,
    this.title = 'Enter your 6-digit PIN',
    required this.subtitle,
    required this.amount,
    required this.onSuccess,
    this.onAuthorise,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  bool _isAuthorising = false;
  bool _showSuccess = false;
  bool _checkingPin = false;
  String? _pinError;

  /// Wrong attempts in a row. The screen gives up after this many rather than
  /// letting someone sit and guess.
  int _attempts = 0;
  static const int _maxAttempts = 3;

  void _onKeyPress(String val) {
    if (_checkingPin) return;
    if (_pin.length < 6) {
      setState(() {
        _pin += val;
        _pinError = null;
      });
      if (_pin.length == 6) {
        _verifyThenAuthorise();
      }
    }
  }

  /// Checks the PIN against the backend before anything else happens.
  ///
  /// This screen used to accept any six digits — `_onKeyPress` called
  /// `_startAuthorisation()` the moment the sixth digit landed, without ever
  /// checking them. Every PIN gate in the app (payments, unfreeze) was
  /// therefore decorative.
  Future<void> _verifyThenAuthorise() async {
    setState(() => _checkingPin = true);

    final ok = await ApiService.instance.verifyPin(_pin);
    if (!mounted) return;

    if (!ok) {
      _attempts++;
      setState(() {
        _checkingPin = false;
        _pin = '';
        _pinError = _attempts >= _maxAttempts
            ? tr('Too many incorrect attempts.')
            : tr('Incorrect PIN. Try again.');
      });
      if (_attempts >= _maxAttempts && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      _checkingPin = false;
      _attempts = 0;
    });
    _startAuthorisation();
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onFaceId() {
    // Simulate biometric authorization immediately
    setState(() {
      _pin = '••••••';
    });
    _startAuthorisation();
  }

  Future<void> _startAuthorisation() async {
    setState(() {
      _isAuthorising = true;
    });

    // Hold the "Authorising…" state while the real work happens, rather than
    // running a fixed timer and celebrating regardless of the outcome.
    final authorise = widget.onAuthorise;
    if (authorise != null) {
      final proceed = await authorise();
      if (!mounted) return;
      if (!proceed) {
        // Flagged, cancelled or failed. The caller has already explained why
        // and handled navigation; just stop showing the spinner.
        setState(() => _isAuthorising = false);
        return;
      }
    } else {
      // No work to do: keep the original beat so the screen does not flash.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
    }

    setState(() {
      _isAuthorising = false;
      _showSuccess = true;
    });

    // Show success for a moment, then hand back to the caller.
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      widget.onSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorising) {
      return _buildAuthorisingUI();
    }
    if (_showSuccess) {
      return _buildSuccessUI();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Navbar / Header
            _buildNavbar(),

            // 3. Pin Entry Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Dot Indicators
                    _buildDotIndicators(),

                    const SizedBox(height: 16),

                    // Forgot PIN Link
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'PIN reset link sent to your registered mobile number.',
                              style: GoogleFonts.inter(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        tr('Forgot PIN?'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E75B6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Wrong-PIN feedback, and a spinner while the code is checked.
            _buildPinError(),

            // 4. Custom Numeric Keypad
            _buildKeypad(),
            
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF475569),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final bool isFilled = index < _pin.length;
        final bool isActive = index == _pin.length;

        if (isActive) {
          // Active dot with blue glow
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF2E75B6),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x262E75B6),
                  blurRadius: 4,
                  spreadRadius: 4,
                )
              ],
            ),
          );
        } else if (isFilled) {
          // Filled dot (navy)
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12.0),
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFF0B2545),
              shape: BoxShape.circle,
            ),
          );
        } else {
          // Empty dot (grey border)
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12.0),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            ),
          );
        }
      }),
    );
  }

  /// Inline error under the PIN dots.
  Widget _buildPinError() {
    if (_checkingPin) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_pinError == null) return const SizedBox(height: 18);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        _pinError!,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIconKeypadButton(
                Icons.face_unlock_rounded,
                onTap: _onFaceId,
              ),
              _buildKeypadButton('0'),
              _buildIconKeypadButton(
                Icons.backspace_outlined,
                onTap: _onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyPress(label),
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0B2545), // 4% opacity
                blurRadius: 1.5,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x0F0B2545), // 6% opacity
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF0B2545),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconKeypadButton(IconData icon, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF0B2545),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorisingUI() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E75B6)),
                  backgroundColor: Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                tr('Authorising Transaction...'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B2545),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Secure encryption active'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessUI() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0x1A16A34A),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                tr('Transaction Successful'),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0B2545),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
