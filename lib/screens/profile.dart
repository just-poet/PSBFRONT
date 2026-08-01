import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'linked_accounts.dart';
import 'personal_details.dart';
import 'update_nominee.dart';
import 'security.dart';
import 'audit_logs.dart';
import 'report_fraud.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricLoginEnabled = true;

  void _navigateToScreen(Widget screen, String routeName) {
    Navigator.push(
      context,
      SmoothPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (context) => MobileDeviceFrame(child: screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            const _StatusBar(),

            // App Bar
            const _AppBar(),

            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top user identity card (taps into Personal details/eKYC)
                    _buildIdentityCard(),
                    const SizedBox(height: 24),

                    // ACCOUNT SECTION
                    _buildSectionTitle('ACCOUNT'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal details',
                        subtitle: 'Name, PAN, Aadhaar, address',
                        onTap: () => _navigateToScreen(const PersonalDetailsScreen(), '/personal_details'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.credit_card_outlined,
                        title: 'Linked accounts',
                        subtitle: '4 banks · via Account Aggregator',
                        onTap: () => _navigateToScreen(const LinkedAccountsScreen(), '/linked_accounts'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.people_outline_rounded,
                        title: 'Nominees & Trust Circle',
                        subtitle: '2 nominees · 1 co-approver above ₹50,000',
                        onTap: () => _navigateToScreen(const UpdateNomineeScreen(), '/update_nominee'),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // SECURITY SECTION
                    _buildSectionTitle('SECURITY'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildSwitchItem(
                        icon: Icons.fingerprint_rounded,
                        title: 'Biometric login',
                        subtitle: 'Face ID enrolled on this device',
                        value: _biometricLoginEnabled,
                        onChanged: (val) {
                          setState(() {
                            _biometricLoginEnabled = val;
                          });
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.tune_rounded,
                        title: 'Transaction limits',
                        subtitle: 'Daily cap ₹1,00,000 · per-transfer ₹25,000',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction limits tapped')),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.shield_outlined,
                        title: 'Security Corner',
                        subtitle: 'Risk gate, SMS scanner, emergency freeze',
                        onTap: () => _navigateToScreen(const SecurityScreen(), '/security'),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // PRIVACY & CONSENT SECTION
                    _buildSectionTitle('PRIVACY & CONSENT'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildMenuItem(
                        icon: Icons.lock_open_rounded,
                        title: 'Data sharing consents',
                        subtitle: '3 active · 1 expires in 12 days',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data sharing consents tapped')),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.history_rounded,
                        title: 'Audit logs',
                        subtitle: 'Tamper-evident record of every action',
                        onTap: () => _navigateToScreen(const AuditLogsScreen(), '/audit_logs'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Privacy policy',
                        subtitle: 'DPDP Act 2023 compliant',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy Policy tapped')),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.gavel_rounded,
                        title: 'Terms & conditions',
                        subtitle: 'Version 1.3 · updated 12/06/2026',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terms & conditions tapped')),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.balance_rounded,
                        title: 'Ethical charter',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ethical charter tapped')),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // PREFERENCES SECTION
                    _buildSectionTitle('PREFERENCES'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildMenuItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'हिंदी and 4 more available',
                        trailingText: 'English',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Language selection tapped')),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Risk alerts, goals, market digest',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifications preferences tapped')),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // SUPPORT SECTION
                    _buildSectionTitle('SUPPORT'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & FAQs',
                        subtitle: 'Guides, chat with support',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help & FAQs tapped')),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.flag_outlined,
                        iconColor: const Color(0xFFDC2626),
                        iconBgColor: const Color(0xFFDC2626).withOpacity(0.1),
                        title: 'Report fraud',
                        subtitle: 'Files a case and dials 1930',
                        onTap: () => _navigateToScreen(const ReportFraudScreen(), '/report_fraud'),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Emergency Freeze Info Banner (Figma node 1166:1923)
                    _buildEmergencyFreezeBanner(),
                    const SizedBox(height: 24),

                    // Sign Out Button (Figma node 1166:1924)
                    _buildSignOutButton(onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign Out tapped')),
                      );
                    }),
                    const SizedBox(height: 32),

                    // Footer Version (Figma node 1166:1925)
                    const _FooterVersion(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Title Helper
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569), // color/text/slate
          letterSpacing: 0.99,
        ),
      ),
    );
  }

  // Card Container Wrapper Helper
  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  // Divider Helper
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFE2E8F0),
      indent: 16,
      endIndent: 16,
    );
  }

  // Top Identity Card
  Widget _buildIdentityCard() {
    return GestureDetector(
      onTap: () => _navigateToScreen(const PersonalDetailsScreen(), '/personal_details'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(21.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2545).withOpacity(0.04),
              blurRadius: 1.5,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: const Color(0xFF0B2545).withOpacity(0.06),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Avatar (Figma node 1166:1881)
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0B2545), Color(0xFF2E75B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  'VA',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.38,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Content Columns
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Venkat A',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                          letterSpacing: -0.36,
                        ),
                      ),
                      const SizedBox(width: 7),
                      // KYC Verified badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF16A34A),
                              size: 9,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'KYC VERIFIED',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                                letterSpacing: 0.36,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'venkat.a@finix.in',
                    style: GoogleFonts.robotoMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Member since March 2025 · SBI primary',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Standard Menu Item Row
  Widget _buildMenuItem({
    required IconData icon,
    Color? iconColor,
    Color? iconBgColor,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // Icon Background Container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor ?? const Color(0xFFEEF4FA), // color/surface/sky
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF0B2545), // color/brand/navy
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text Titles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628), // color/text/ink
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF475569), // color/text/slate
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              // Trailing Section
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8), // color/text/mist
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Switch Menu Item Row
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF0B2545),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          // Toggle Switch
          SizedBox(
            height: 26,
            width: 44,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF16A34A), // color/semantic/green
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCBD5E1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dashed Emergency Freeze Info Banner
  Widget _buildEmergencyFreezeBanner() {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(0xFFDC2626),
        strokeWidth: 1.0,
        gap: 4.0,
        dash: 6.0,
        borderRadius: 14.0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Emergency Freeze — long-press the shield in Security to halt all outgoing transactions. Kept out of this list so it can\'t be tapped by accident.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sign Out Button
  Widget _buildSignOutButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Color(0xFF475569),
              size: 17,
            ),
            const SizedBox(width: 8),
            Text(
              'Sign out',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Status Bar Widget
// ---------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------
// Custom App Bar Widget
// ---------------------------------------------------------------------
class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Back Button
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
                  size: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          // Spacer
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Footer Version Widget
// ---------------------------------------------------------------------
class _FooterVersion extends StatelessWidget {
  const _FooterVersion();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'FINIX v0.1.3 · Made for Bharat',
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF94A3B8), // color/text/mist
          letterSpacing: 0.21,
        ),
      ),
    );
  }
}

// Custom Dashed Border Painter
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0;
    bool draw = true;

    for (var measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        final length = draw ? dash : gap;
        dashPath.addPath(
          measurePath.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
