import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/hardware_service.dart';
import '../services/locale_service.dart';
import 'pin_screen.dart';

/// Full-screen lock shown while the account is frozen.
///
/// A freeze that leaves the customer free to keep browsing is not a freeze —
/// the point is that the phone in a fraudster's hands stops being useful. The
/// app locks onto this page: back is disabled, the navigation bar is gone, and
/// the only way out is a fingerprint or the real PIN.
class FrozenLockScreen extends StatefulWidget {
  const FrozenLockScreen({super.key});

  @override
  State<FrozenLockScreen> createState() => _FrozenLockScreenState();
}

class _FrozenLockScreenState extends State<FrozenLockScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _unlockWithBiometric() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final outcome = await FinixBiometric.verify(
      reason: 'Unlock your frozen account',
    );
    if (!mounted) return;

    if (outcome == BiometricOutcome.failed) {
      setState(() {
        _busy = false;
        _error = tr('Fingerprint not recognised.');
      });
      return;
    }

    // Where no sensor exists the PIN remains the way in, so an unavailable
    // prompt must not silently unlock the account.
    if (outcome == BiometricOutcome.unavailable) {
      setState(() {
        _busy = false;
        _error = tr('No fingerprint on this device. Use your PIN.');
      });
      return;
    }

    await _completeUnfreeze();
  }

  Future<void> _unlockWithPin() async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/unfreeze_pin'),
        builder: (_) => PinScreen(
          title: tr('Enter your 6-digit PIN'),
          subtitle: tr('Unlock your frozen account'),
          amount: 0,
          onSuccess: () => Navigator.pop(context, true),
        ),
      ),
    );

    if (verified == true && mounted) {
      await _completeUnfreeze();
    }
  }

  Future<void> _completeUnfreeze() async {
    setState(() => _busy = true);
    await ApiService.instance.unfreeze();
    if (!mounted) return;

    // Clearing the flag is what releases every other screen. There is no pop
    // here: this screen is laid over the app in a Stack rather than pushed, so
    // popping would dismiss whatever route is underneath it.
    ApiService.instance.accountFrozen.value = false;
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The whole point: the customer cannot navigate away from a frozen
      // account by swiping back.
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B2545),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.4),
                    ),
                  ),
                  child: const Icon(Icons.ac_unit_rounded,
                      color: Color(0xFFF87171), size: 34),
                ),
                const SizedBox(height: 22),
                Text(
                  tr('Account frozen'),
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr('Every outgoing payment is halted across your linked '
                      'accounts. Incoming credits still arrive.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.white.withOpacity(0.78),
                  ),
                ),
                const SizedBox(height: 30),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF87171),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _unlockWithBiometric,
                    icon: const Icon(Icons.fingerprint_rounded, size: 20),
                    label: Text(
                      tr('Unlock with fingerprint'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0B2545),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _unlockWithPin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      tr('Use PIN instead'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  tr('Lost your phone? Call 1800 419 8300.'),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
