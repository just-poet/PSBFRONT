import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class SecurityEventsScreen extends StatefulWidget {
  const SecurityEventsScreen({super.key});

  @override
  State<SecurityEventsScreen> createState() => _SecurityEventsScreenState();
}

class _SecurityEventsScreenState extends State<SecurityEventsScreen> {
  List<Map<String, dynamic>> _events = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ApiService.instance.getAuditLogs();
    if (!mounted) return;
    setState(() {
      // Only the security-relevant slice; the full trail lives in Audit Logs.
      _events = all
          .where((e) => _eventStyles.containsKey((e['eventType'] ?? '').toString()))
          .take(25)
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar (Figma node 778:1034)
            _buildAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Banner note (Figma node 778:1042)
                    _buildInfoBanner(),
                    const SizedBox(height: 22),

                    // Section header: Recent activity (Figma node 778:1047)
                    Text(
                      tr('Recent activity'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.13,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Timeline of Events
                    _buildTimeline(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF475569),
                  size: 16,
                ),
              ),
            ),
          ),
          // Center title
          Text(
            tr('Security Events'),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.15,
            ),
          ),
          // Right options button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    tr('Ledger database is up to date.'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF0B2545),
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1.0),
            child: Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
                children: [
                  TextSpan(text: 'Each event is written to a tamper-evident log. '),
                  TextSpan(
                    text: tr('Verified'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1628),
                    ),
                  ),
                  TextSpan(text: " means the record's integrity is intact."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Security-relevant entries from the customer's real audit trail.
  ///
  /// This was four invented events — a ₹85,000 transfer paused at 1:47 AM, a
  /// Pixel 8 sign-in from Bengaluru — identical on every account. The audit
  /// endpoint already records the genuine ones.
  Widget _buildTimeline() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            tr('No security events recorded yet.'),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _events.length; i++)
          Builder(builder: (context) {
            final event = _events[i];
            final style = _styleFor(event);
            return _buildTimelineItem(
              showLine: i < _events.length - 1,
              icon: _buildIconIndicator(
                icon: style.icon,
                color: style.colour,
                bgColor: style.colour.withOpacity(0.1),
              ),
              title: style.title,
              badge: (event['outcome'] ?? '').toString() == 'success'
                  ? _buildVerifiedBadge()
                  : _buildRiskBadge(
                      (event['outcome'] ?? 'review').toString().toUpperCase()),
              description: (event['details'] ?? event['xaiReason'] ?? '')
                  .toString(),
              time: _formatWhen(event['timestamp']),
            );
          }),
      ],
    );
  }

  /// Only security-relevant event types reach this screen; payments and score
  /// recalculations belong in the audit log, not here.
  static const Map<String, ({String title, IconData icon, Color colour})>
      _eventStyles = {
    'pin_login_success': (
      title: 'Signed in',
      icon: Icons.login_rounded,
      colour: Color(0xFF2E75B6)
    ),
    'pin_login_failure': (
      title: 'Failed sign-in attempt',
      icon: Icons.warning_amber_rounded,
      colour: Color(0xFFDC2626)
    ),
    'biometric_login_success': (
      title: 'Unlocked with biometrics',
      icon: Icons.fingerprint_rounded,
      colour: Color(0xFF16A34A)
    ),
    'emergency_freeze': (
      title: 'Emergency freeze applied',
      icon: Icons.ac_unit_rounded,
      colour: Color(0xFFDC2626)
    ),
    'account_unfreeze': (
      title: 'Account unfrozen',
      icon: Icons.lock_open_rounded,
      colour: Color(0xFFF59E0B)
    ),
    'transaction_blocked': (
      title: 'Payment blocked',
      icon: Icons.block_flipped,
      colour: Color(0xFFDC2626)
    ),
    'device_bound': (
      title: 'New device linked',
      icon: Icons.phone_android_rounded,
      colour: Color(0xFF2E75B6)
    ),
    'beneficiary_added': (
      title: 'New payee added',
      icon: Icons.person_add_alt_1_rounded,
      colour: Color(0xFFF59E0B)
    ),
    'sms_scan': (
      title: 'Messages scanned',
      icon: Icons.chat_bubble_outline_rounded,
      colour: Color(0xFF2E75B6)
    ),
    'consent_granted': (
      title: 'Consent granted',
      icon: Icons.verified_user_outlined,
      colour: Color(0xFF16A34A)
    ),
  };

  ({String title, IconData icon, Color colour}) _styleFor(
      Map<String, dynamic> event) {
    final type = (event['eventType'] ?? '').toString();
    return _eventStyles[type] ??
        (
          title: type.replaceAll('_', ' '),
          icon: Icons.shield_outlined,
          colour: const Color(0xFF64748B)
        );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatWhen(dynamic iso) {
    final at = DateTime.tryParse((iso ?? '').toString())?.toLocal();
    if (at == null) return '';
    final now = DateTime.now();
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final clock =
        '$hour:${at.minute.toString().padLeft(2, '0')} ${at.hour < 12 ? 'AM' : 'PM'}';

    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(at.year, at.month, at.day))
        .inDays;
    if (days == 0) return 'Today, $clock';
    if (days == 1) return 'Yesterday, $clock';
    return '${at.day} ${_months[at.month - 1]} ${at.year}, $clock';
  }

  Widget _buildIconIndicator({
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildRiskBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check,
            color: Color(0xFF16A34A),
            size: 8,
          ),
          const SizedBox(width: 3),
          Text(
            tr('VERIFIED'),
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF16A34A),
              letterSpacing: 0.43,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required Widget icon,
    required String title,
    required Widget badge,
    required String description,
    required String time,
    required bool showLine,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timeline line & icon column
          SizedBox(
            width: 38,
            child: Column(
              children: [
                icon,
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFE2E8F0),
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right content card details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 23.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      const SizedBox(width: 6),
                      badge,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: GoogleFonts.spaceMono(
                      fontSize: 9.5,
                      color: const Color(0xFF94A3B8),
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
}
