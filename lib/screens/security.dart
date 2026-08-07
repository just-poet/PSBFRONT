import 'dart:async';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottom_nav_bar.dart';
import 'audit_logs.dart';
import 'security_events.dart';
import 'emergency_freeze.dart';
import '../main.dart' show navigatorKey;
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/hardware_service.dart';
import '../services/sms_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> with SingleTickerProviderStateMixin {
  /// Messages actually read and scanned on this device. Both "SMS Detector"
  /// labels used to read a fixed "23 scanned today" no matter what was in the
  /// inbox — or whether permission had even been granted.
  int _smsScanned = 0;
  bool _smsScanKnown = false;

  /// Called by the scan sheet once it knows the real number.
  void _reportSmsScanned(int count) {
    if (!mounted) return;
    setState(() {
      _smsScanned = count;
      _smsScanKnown = true;
    });
  }

  String get _smsSubtitle => _smsScanKnown
      ? '${tr('Active')} · $_smsScanned ${tr('scanned')}'
      : tr('Active · tap to scan');

  // Toggle states for active protections
  bool _biometricLogin = true;           // worth 20 points
  bool _transactionRiskEngine = true;    // worth 25 points
  bool _coercedDetection = true;         // worth 20 points
  bool _slowMode = false;                // worth 6 points
  bool _twoPersonRule = true;            // worth 29 points

  // Screen level emergency freeze state
  bool _isFrozen = false;

  late AnimationController _pulseAnimController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );
    _fetchSecurityHealth();
  }

  Future<void> _fetchSecurityHealth() async {
    try {
      final health = await ApiService.instance.getSecurityHealth();
      if (mounted) {
        setState(() {
          _isFrozen = health['is_frozen'] ?? false;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    super.dispose();
  }

  // Calculate protection score dynamically based on states
  int get _protectionScore {
    int score = 0;
    if (_biometricLogin) score += 20;
    if (_transactionRiskEngine) score += 25;
    if (_coercedDetection) score += 20;
    if (_slowMode) score += 6;
    if (_twoPersonRule) score += 29;
    return score;
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      activeTabNotifier.value = 'home';
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  /// Confirms the customer's identity before a security action.
  ///
  /// Freezing halts every outgoing payment and unfreezing lifts that
  /// protection, so neither should be possible for someone who has merely
  /// picked up an unlocked phone. Returns false only when the device could ask
  /// and the person failed or cancelled — where no sensor exists (emulator,
  /// desktop, nothing enrolled) the action is allowed through, since blocking
  /// it would make the freeze unreachable on those devices.
  Future<bool> _confirmWithBiometric(String reason) async {
    final outcome = await FinixBiometric.verify(reason: reason);
    if (outcome == BiometricOutcome.failed) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Fingerprint not recognised — nothing was changed.')),
          backgroundColor: Color(0xFF475569),
        ),
      );
      return false;
    }
    return true;
  }

  void _triggerEmergencyFreeze() async {
    if (!await _confirmWithBiometric(
        'Confirm your fingerprint to freeze the account')) {
      return;
    }
    if (!mounted) return;

    setState(() {
      _isFrozen = true;
    });
    try {
      await ApiService.instance.emergencyFreeze("User requested freeze from security dashboard");
    } catch (_) {}

    // Raise the app-wide lock. Without this the account was frozen on the
    // server but the customer could carry on browsing, which is not a freeze.
    ApiService.instance.accountFrozen.value = true;
    FinixNotifications.instance.accountFrozen();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('EMERGENCY FREEZE ACTIVATED! All transactions halted.'),
        backgroundColor: Color(0xFFDC2626),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _unlockAccount() async {
    // Lifting the freeze is the more dangerous direction: it restores the
    // ability to move money.
    if (!await _confirmWithBiometric(
        'Confirm your fingerprint to unfreeze the account')) {
      return;
    }
    if (!mounted) return;

    setState(() {
      _isFrozen = false;
    });
    try {
      await ApiService.instance.unfreeze();
    } catch (_) {}
    ApiService.instance.accountFrozen.value = false;
    FinixNotifications.instance.accountUnfrozen();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Account unlocked successfully.')),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }


  // --- POPUP DETAILS SHEETS ---
  
  void _confirmEmergencyFreeze() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('Activate Emergency Freeze?'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B2545),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will instantly block all outgoing UPI transactions, bank transfers, and card swipes to safeguard your funds.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        tr('Cancel'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _triggerEmergencyFreeze();
                      },
                      child: Text(
                        tr('Freeze Account'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmergencyFreezeScreen() {
    Navigator.push(
      context,
      SmoothPageRoute(
        settings: const RouteSettings(name: '/emergency_freeze'),
        builder: (context) => EmergencyFreezeScreen(
          onFreezeConfirmed: () {
            _triggerEmergencyFreeze();
          },
        ),
      ),
    );
  }

  void _showSmsDetectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(24),
              // Capped and scrollable. The sheet previously laid its content
              // out in an unbounded Column, so with more than three or four
              // messages the list ran off the bottom with no way to reach it.
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('SMS Detector'),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0B2545),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _smsSubtitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B2545),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('Checking latest inbox messages locally...')),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: Text(
                          tr('Scan now'),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr('RECENT SCANS'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Real inbox messages, each scanned by the backend. This
                  // was three invented texts — a fake SBI phishing message, an
                  // Axis OTP and a Zomato delivery notice — shown identically
                  // on every device, which demonstrated nothing about what the
                  // customer had actually received.
                  _SmsScanList(
                    buildItem: _buildSmsScanItem,
                    onScanned: _reportSmsScanned,
                  ),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAuditLogsSheet() {
    Navigator.push(
      context,
      SmoothPageRoute(
        settings: const RouteSettings(name: '/audit_logs'),
        builder: (context) => const AuditLogsScreen(),
      ),
    );
  }

  void _showSecurityEventsScreen() {
    Navigator.push(
      context,
      SmoothPageRoute(
        settings: const RouteSettings(name: '/security_events'),
        builder: (context) => const SecurityEventsScreen(),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF0B2545)),
              const SizedBox(width: 10),
              Text(
                tr('FINIX Security Suite'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B2545),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your account is secured by our enterprise-grade cryptographic ledger and real-time transaction scoring system.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: tr('Emergency Freeze'),
                  description: 'Instantly halt all outgoing payments if you suspect fraud. Can be deactivated securely with biometrics.',
                ),
                _buildInfoSection(
                  title: tr('SMS Detector'),
                  description: 'Scans incoming text messages locally to automatically flag and block potential UPI/banking phishing links.',
                ),
                _buildInfoSection(
                  title: 'Transaction Risk Engine',
                  description: 'Scores transactions using 7 network signals to flag abnormal activity and prompt manual verification.',
                ),
                _buildInfoSection(
                  title: 'Two-Person Rule',
                  description: 'Adds a mandatory 24-hour verification delay on catastrophic actions, requiring approval from two trusted contacts.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('Close'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- SUB WIDGET BUILDERS ---

  Widget _buildSmsScanItem({
    required String sender,
    required String body,
    required String status,
    required bool isDanger,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDanger ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sender,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A1628),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDanger 
                      ? const Color(0xFFFEE2E2) 
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInfoSection({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0B2545),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left back button
          GestureDetector(
            onTap: () => _handleBack(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF475569),
                  size: 24,
                ),
              ),
            ),
          ),
          // Center title
          Text(
            tr('Security'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.16,
            ),
          ),
          // Right info button
          GestureDetector(
            onTap: _showInfoDialog,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.info_outline_rounded,
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

  Widget _buildHeroCard() {
    final int score = _protectionScore;
    final bool isHighlyProtected = score >= 80;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF0B2545),
            Color(0xFF13315C),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Shield Icon + Text Labels
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withOpacity(0.32),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF4ADE80),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('YOUR ACCOUNT'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isHighlyProtected ? 'Fully Protected' : 'Action Required',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: -0.48,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            tr('Protection score · '),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.88),
                            ),
                          ),
                          Text(
                            '$score / 100',
                            style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: score >= 80 ? const Color(0xFF4ADE80) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(
                color: Colors.white.withOpacity(0.15),
                height: 1,
                thickness: 1,
              ),
            ),

            // Bottom Row: Metadata info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        tr('Threats blocked · '),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '3 this week',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      tr('Last scan · '),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '2 min ago',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color borderColor,
    Gradient? backgroundGradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundGradient == null ? Colors.white : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                    letterSpacing: -0.16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCheckItem({
    required String title,
    required String subtitle,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isOn 
                    ? const Color(0xFF16A34A).withOpacity(0.1)
                    : const Color(0xFFF59E0B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isOn ? Icons.check : Icons.priority_high_rounded,
                  color: isOn ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                  size: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isOn ? 'ON' : 'OFF',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isOn ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.02),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              time,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [actionText] and [onAction] are optional: a section can stand without a
  /// trailing link.
  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
            letterSpacing: -0.16,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E75B6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFreezeOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.92),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            tr('ACCOUNT FROZEN'),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All outgoing transactions, card swipes, and online transfers have been halted instantly to safeguard your assets.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: _unlockAccount,
            icon: const Icon(Icons.fingerprint_rounded),
            label: Text(
              tr('Unlock with Biometrics'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Custom app bar matching Figma node topbar
                _buildAppBar(context),

                // Scrollable main content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Status Card
                        _buildHeroCard(),
                        const SizedBox(height: 20),

                        // Section Title: Protection tools
                        Text(
                          tr('Protection tools'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                            letterSpacing: -0.16,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Grid for tools: Emergency Freeze, SMS Detector, Audit Logs
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildToolCard(
                                title: tr('Emergency Freeze'),
                                subtitle: 'Halt all outgoing payments instantly',
                                icon: Icons.lock_outline_rounded,
                                iconColor: const Color(0xFFDC2626),
                                iconBgColor: const Color(0xFFDC2626).withOpacity(0.1),
                                borderColor: const Color(0xFFFECACA),
                                backgroundGradient: const LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                  colors: [
                                    Color(0xFFFEF2F2),
                                    Colors.white,
                                  ],
                                ),
                                onTap: _showEmergencyFreezeScreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildToolCard(
                                title: tr('SMS Detector'),
                                subtitle: _smsSubtitle,
                                icon: Icons.chat_bubble_outline_rounded,
                                iconColor: const Color(0xFF16A34A),
                                iconBgColor: const Color(0xFF16A34A).withOpacity(0.1),
                                borderColor: const Color(0xFFE2E8F0),
                                onTap: _showSmsDetectorSheet,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildToolCard(
                                title: tr('Audit Logs'),
                                subtitle: 'Merkle-verified · 28 events',
                                icon: Icons.description_outlined,
                                iconColor: const Color(0xFF2E75B6),
                                iconBgColor: const Color(0xFFEEF4FA),
                                borderColor: const Color(0xFFE2E8F0),
                                onTap: _showAuditLogsSheet,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section: Active protections
                        // "Manage →" removed: it turned every protection on at
                        // once, which is not what "manage" means, and the
                        // toggles below already do the job.
                        _buildSectionHeader(
                          title: 'Active protections',
                        ),
                        const SizedBox(height: 10),

                        // Active protections checklist container
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0B2545).withOpacity(0.02),
                                blurRadius: 1.5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildActiveCheckItem(
                                title: tr('Biometric login'),
                                subtitle: _biometricLogin 
                                    ? 'Face ID · enrolled 14 days ago' 
                                    : 'Face ID disabled',
                                isOn: _biometricLogin,
                                onTap: () => setState(() => _biometricLogin = !_biometricLogin),
                              ),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                              _buildActiveCheckItem(
                                title: 'Transaction risk engine',
                                subtitle: '7-signal real-time scoring',
                                isOn: _transactionRiskEngine,
                                onTap: () => setState(() => _transactionRiskEngine = !_transactionRiskEngine),
                              ),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                              _buildActiveCheckItem(
                                title: 'Coerced transaction detection',
                                subtitle: 'Watches for active call + new payee',
                                isOn: _coercedDetection,
                                onTap: () => setState(() => _coercedDetection = !_coercedDetection),
                              ),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                              _buildActiveCheckItem(
                                title: 'Slow Mode',
                                subtitle: 'Adds friction for txns > ₹10k',
                                isOn: _slowMode,
                                onTap: () => setState(() => _slowMode = !_slowMode),
                              ),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                              _buildActiveCheckItem(
                                title: 'Two-Person Rule',
                                subtitle: '24h delay on catastrophic actions',
                                isOn: _twoPersonRule,
                                onTap: () => setState(() => _twoPersonRule = !_twoPersonRule),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section: Recent security events
                        _buildSectionHeader(
                          title: 'Recent security events',
                          actionText: 'View logs →',
                          onAction: _showSecurityEventsScreen,
                        ),
                        const SizedBox(height: 10),

                        // List of recent events
                        _buildEventCard(
                          title: 'Transaction paused · ₹85,000',
                          subtitle: 'Risk 78 · You declined',
                          time: '2:14 AM',
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFDC2626),
                          iconBgColor: const Color(0xFFDC2626).withOpacity(0.1),
                        ),
                        _buildEventCard(
                          title: 'Phishing SMS blocked',
                          subtitle: 'Sender VK-SBI4UP · 6 / 6 signals',
                          time: '11:34 PM',
                          icon: Icons.chat_bubble_outline_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          iconBgColor: const Color(0xFFF59E0B).withOpacity(0.1),
                        ),
                        _buildEventCard(
                          title: tr('Biometric login'),
                          subtitle: 'Face ID · iPhone 14 Pro · Mumbai',
                          time: '09:41 AM',
                          icon: Icons.face_unlock_rounded,
                          iconColor: const Color(0xFF16A34A),
                          iconBgColor: const Color(0xFF16A34A).withOpacity(0.1),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Account Frozen full-screen overlay
            if (_isFrozen) _buildFreezeOverlay(),
          ],
        ),
      ),
    );
  }
}

/// Reads the device inbox and shows each message with the backend's verdict.
///
/// Takes the row builder from the security screen so the sheet keeps its
/// existing look rather than growing a second, slightly different card style.
class _SmsScanList extends StatefulWidget {
  const _SmsScanList({required this.buildItem, this.onScanned});

  /// Reports how many messages were actually scanned, so the screen behind can
  /// show a real number instead of a fixed one.
  final void Function(int count)? onScanned;

  final Widget Function({
    required String sender,
    required String body,
    required String status,
    required bool isDanger,
    required String time,
  }) buildItem;

  @override
  State<_SmsScanList> createState() => _SmsScanListState();
}

class _SmsScanListState extends State<_SmsScanList> {
  SmsAccess _access = SmsAccess.denied;
  List<DeviceSms> _messages = const [];
  int _skippedOtp = 0;
  final Map<String, Map<String, dynamic>> _verdicts = {};
  bool _loading = true;

  /// How many recent messages are scanned. Each scan is a round trip, so this
  /// is deliberately small — the point is a quick read on recent exposure, not
  /// an audit of the whole inbox.
  static const _scanLimit = 8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await FinixSms.readInbox(limit: _scanLimit);
    if (!mounted) return;
    setState(() {
      _access = result.access;
      _messages = result.messages;
      _skippedOtp = result.skippedOtp;
      _loading = false;
    });
    widget.onScanned?.call(result.messages.length);

    // Scanned one at a time: the endpoint takes a single message, and firing
    // eight concurrent requests through a tunnel is a good way to get rate
    // limited.
    for (final message in result.messages) {
      final verdict = await ApiService.instance.scanSms(
        sender: message.sender,
        message: message.body,
      );
      if (!mounted) return;
      setState(() => _verdicts[message.id] = verdict);
    }
  }

  static String _clock(DateTime? at) {
    if (at == null) return '';
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_access != SmsAccess.granted) {
      return _buildAccessNotice();
    }

    if (_messages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          tr('No messages in your inbox to scan.'),
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Says what was actually looked at. The header above used to read a
        // fixed "23 scanned today" regardless of the inbox.
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _skippedOtp > 0
                ? '${_messages.length} scanned · $_skippedOtp OTP skipped'
                : '${_messages.length} scanned',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        for (final message in _messages)
          Builder(builder: (context) {
            final verdict = _verdicts[message.id];
            // Absent verdict means the scan has not come back (or failed).
            // Reported as "scanning" rather than a premature all-clear.
            final badge = (verdict?['badge'] ?? '').toString();
            final danger = badge == 'red';
            final status = switch (badge) {
              'red' => 'PHISHING BLOCKED',
              'amber' => 'SUSPICIOUS',
              'green' => 'CLEAN',
              _ => verdict == null ? 'SCANNING…' : 'NOT SCANNED',
            };
            return widget.buildItem(
              sender: message.sender.isEmpty ? 'Unknown' : message.sender,
              body: message.body,
              status: status,
              isDanger: danger,
              time: _clock(message.receivedAt),
            );
          }),
      ],
    );
  }

  Widget _buildAccessNotice() {
    final permanent = _access == SmsAccess.permanentlyDenied;
    final unsupported = _access == SmsAccess.unsupported;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sms_outlined, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                unsupported ? 'Not available here' : 'Message access needed',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            unsupported
                ? 'Reading your inbox is only possible on Android.'
                : 'FINIX scans your recent messages for banking phishing. '
                    'Messages are read on your device and only the text being '
                    'checked is sent for scanning.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: const Color(0xFF475569),
            ),
          ),
          if (!unsupported) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (permanent) {
                    await FinixSms.openSettings();
                    return;
                  }
                  setState(() => _loading = true);
                  await _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  permanent ? 'Open app settings' : 'Allow message access',
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
