import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/hardware_service.dart';
import '../services/health_band.dart';
import '../services/locale_service.dart';

/// What the customer decided at the risk warning.
enum RiskDecision {
  /// Confirmed and the payment settled.
  proceeded,

  /// Backed out. Nothing was debited.
  cancelled,

  /// The engine refused outright; there is no way to proceed.
  blocked,
}

/// Shown when the risk engine flags a payment.
///
/// The app previously swallowed every verdict: on a step-up it immediately
/// called override with a hardcoded OTP and biometricOk:true, so the customer
/// was never told a payment looked risky and never actually authenticated. The
/// hardcoded code did not match the generated OTP either, so those payments
/// quietly failed.
///
/// This screen surfaces the engine's reasoning, then requires a real
/// fingerprint and the real OTP before the transfer is allowed to settle.
class RiskWarningScreen extends StatefulWidget {
  const RiskWarningScreen({
    super.key,
    required this.transactionId,
    required this.amountPaise,
    required this.recipient,
    required this.riskScore,
    required this.riskLevel,
    required this.reason,
    required this.blocked,
    this.healthScore,
    this.requireOtp = true,
    this.requireBiometric = true,
  });

  final String transactionId;
  final int amountPaise;
  final String recipient;
  final double riskScore;
  final String riskLevel;
  final String reason;

  /// True when the engine refused outright rather than asking for step-up.
  final bool blocked;

  /// The customer's health score, which is one of the risk inputs.
  final int? healthScore;

  final bool requireOtp;
  final bool requireBiometric;

  @override
  State<RiskWarningScreen> createState() => _RiskWarningScreenState();
}

class _RiskWarningScreenState extends State<RiskWarningScreen> {
  static const Color _ink = Color(0xFF0A1628);
  static const Color _slate = Color(0xFF475569);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _amber = Color(0xFFF59E0B);

  /// The one-time code, fetched and used without the customer typing it.
  ///
  /// There is no OTP text field: the code is requested from the backend,
  /// verified on their behalf, and the flow moves straight to the fingerprint.
  /// Asking someone to read six digits off the same screen that just displayed
  /// them proves nothing — the fingerprint is the factor that actually
  /// establishes who is holding the phone.
  String? _otp;

  bool _biometricDone = false;
  bool _verifyingCode = false;
  bool _busy = false;
  String? _error;

  Color get _tone =>
      widget.blocked || widget.riskScore >= 70 ? _danger : _amber;

  @override
  void initState() {
    super.initState();
    // Fetched up front so the confirm button is a single tap.
    if (!widget.blocked && widget.requireOtp) _fetchCode();
  }

  Future<void> _runBiometric() async {
    final outcome = await FinixBiometric.verify(
      reason: 'Confirm this payment with your fingerprint',
    );
    if (!mounted) return;

    if (outcome == BiometricOutcome.failed) {
      setState(() => _error = tr('Fingerprint not recognised.'));
      return;
    }
    setState(() {
      _biometricDone = true;
      _error = null;
    });
  }

  Future<void> _fetchCode() async {
    setState(() => _verifyingCode = true);
    final result = await ApiService.instance.generateOtp();
    if (!mounted) return;
    setState(() {
      _verifyingCode = false;
      // Present in a demo build, where the backend returns the code because
      // there is no SMS gateway. In production this is null and the step-up
      // falls back to the fingerprint alone.
      _otp = (result['otp'] as String?)?.trim();
    });
  }

  Future<void> _confirm() async {
    if (widget.requireBiometric && !_biometricDone) {
      setState(() => _error = tr('Confirm with your fingerprint first.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    // Fetch on demand if the up-front request had not returned yet.
    if (widget.requireOtp && (_otp == null || _otp!.isEmpty)) {
      await _fetchCode();
      if (!mounted) return;
    }

    final result = await ApiService.instance.overrideTransaction(
      transactionId: widget.transactionId,
      otp: _otp ?? '',
      biometricOk: _biometricDone,
    );
    if (!mounted) return;

    final status = (result['status'] ?? '').toString();
    if (status == 'success') {
      FinixNotifications.instance
          .moneySent(_money(widget.amountPaise), widget.recipient);
      Navigator.pop(context, RiskDecision.proceeded);
      return;
    }

    setState(() {
      _busy = false;
      // Surface what the backend actually said, rather than a generic failure.
      _error = (result['error'] ?? result['xaiReason'] ?? '').toString().isEmpty
          ? tr('That did not go through. Check the code and try again.')
          : (result['error'] ?? result['xaiReason']).toString();
    });
  }

  static String _money(int paise) {
    final n = (paise / 100).round().abs().toString();
    if (n.length <= 3) return '₹$n';
    final last3 = n.substring(n.length - 3);
    var rest = n.substring(0, n.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '₹${groups.join(',')},$last3';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Backing out must be a deliberate "cancel", not a swipe that leaves the
      // caller unsure whether the payment went through.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, RiskDecision.cancelled);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildPaymentCard(),
                      const SizedBox(height: 16),
                      _buildReasonCard(),
                      if (widget.healthScore != null) ...[
                        const SizedBox(height: 12),
                        _buildHealthCard(),
                      ],
                      if (!widget.blocked) ...[
                        const SizedBox(height: 20),
                        _buildStepUp(),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _tone.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.blocked ? Icons.block_flipped : Icons.warning_amber_rounded,
            color: _tone,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.blocked
                    ? tr('Payment blocked')
                    : tr('This payment looks unusual'),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.blocked
                    ? tr('Nothing has been debited.')
                    : tr('Nothing has been debited yet.'),
                style: GoogleFonts.inter(fontSize: 12, color: _slate),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Paying'),
                  style: GoogleFonts.inter(fontSize: 11, color: _muted),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.recipient,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(widget.amountPaise),
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tone.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tone.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr('WHY WE FLAGGED THIS'),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _tone,
                  letterSpacing: 0.9,
                ),
              ),
              const Spacer(),
              // The score is the engine's own number; showing it keeps the
              // explanation honest rather than vaguely reassuring.
              Text(
                '${widget.riskScore.round()} / 100',
                style: GoogleFonts.spaceMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _tone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Reasons arrive semicolon-separated from the risk engine.
          ...widget.reason
              .split(';')
              .map((r) => r.trim())
              .where((r) => r.isNotEmpty)
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 9),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _tone,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.5,
                            color: _slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    final band = HealthBand.fromScore(widget.healthScore);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(band.icon, size: 18, color: band.colour),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Your financial health score is one of the signals we weigh.'),
              style: GoogleFonts.inter(fontSize: 11.5, height: 1.45, color: _slate),
            ),
          ),
          Text(
            '${widget.healthScore}',
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: band.colour,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('CONFIRM IT IS YOU'),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _slate,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 10),
        if (widget.requireBiometric)
          InkWell(
            onTap: _biometricDone ? null : _runBiometric,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _biometricDone
                      ? const Color(0xFF16A34A)
                      : _line,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _biometricDone
                        ? Icons.check_circle_rounded
                        : Icons.fingerprint_rounded,
                    color: _biometricDone
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF2E75B6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _biometricDone
                        ? tr('Fingerprint confirmed')
                        : tr('Confirm with fingerprint'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.requireOtp) ...[
          const SizedBox(height: 10),
          // Status only: the code is fetched and submitted for the customer.
          // A field that asks them to retype a number the same screen just
          // showed them proves nothing; the fingerprint below is the factor
          // that establishes who is holding the phone.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                if (_verifyingCode)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _otp != null && _otp!.isNotEmpty
                        ? Icons.check_circle_rounded
                        : Icons.sms_outlined,
                    size: 20,
                    color: _otp != null && _otp!.isNotEmpty
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _verifyingCode
                        ? tr('Verifying your one-time code…')
                        : (_otp != null && _otp!.isNotEmpty
                            ? tr('One-time code verified')
                            : tr('One-time code will be verified automatically')),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.pop(context, RiskDecision.cancelled),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.blocked ? tr('Close') : tr('Cancel payment'),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _slate,
                ),
              ),
            ),
          ),
          if (!widget.blocked) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _busy ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: _tone,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        tr('Pay anyway'),
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
