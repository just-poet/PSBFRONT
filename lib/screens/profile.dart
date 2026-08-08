import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'linked_accounts.dart';
import 'personal_details.dart';
import 'update_nominee.dart';
import 'security.dart';
import 'audit_logs.dart';
import 'report_fraud.dart';
import 'notifications.dart';
import 'chat.dart';
import 'ethical_charter.dart';
import 'privacy_policy.dart';
import 'bottom_nav_bar.dart';
import 'login_ckyc.dart';
import '../main.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Identity shown in the header. The email was the literal
  // "venkat.a@finix.in" and the footer read "Member since March 2025 · SBI
  // primary" for every account, so the settings page described one person no
  // matter who was signed in.
  Map<String, dynamic> _profile = const {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ApiService.instance.getProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "Member since March 2025", from the account's real creation date.
  String get _memberSince {
    final created = DateTime.tryParse((_profile['createdAt'] ?? '').toString());
    if (created == null) return 'Member since —';
    return 'Member since ${_monthNames[created.month - 1]} ${created.year}';
  }

  /// Signs the customer out and returns them to the sign-in screen.
  ///
  /// The button previously only showed a "Sign Out tapped" snackbar: the
  /// session token stayed in SharedPreferences, so the account remained
  /// signed in and anyone picking up the phone still had full access.
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr('Sign out?'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        ),
        content: Text(
          tr('You will need your cKYC number and PIN to sign back in.'),
          style:
              GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              tr('Cancel'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              tr('Sign out'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApiService.instance.clearSession();
    if (!mounted) return;

    // The nav bar hides itself on auth screens; without this it would keep
    // showing over the sign-in page.
    activeTabNotifier.value = 'ekyc';

    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (context) => const MobileDeviceFrame(child: LoginCkycScreen()),
      ),
      (route) => false,
    );
  }

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
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
                        title: tr('Personal details'),
                        subtitle: tr('Name, PAN, Aadhaar, address'),
                        onTap: () => _navigateToScreen(
                            const PersonalDetailsScreen(), '/personal_details'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.credit_card_outlined,
                        title: tr('Linked accounts'),
                        subtitle: '4 banks · via Account Aggregator',
                        onTap: () => _navigateToScreen(
                            const LinkedAccountsScreen(), '/linked_accounts'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.people_outline_rounded,
                        title: tr('Nominees & Trust Circle'),
                        subtitle: '2 nominees · 1 co-approver above ₹50,000',
                        onTap: () => _navigateToScreen(
                            const UpdateNomineeScreen(), '/update_nominee'),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // SECURITY SECTION
                    _buildSectionTitle('SECURITY'),
                    const SizedBox(height: 8),
                    _buildCard([
                      // The biometric toggle is gone. It was a local bool that
                      // changed nothing, and it let someone switch off the very
                      // check that guards a freeze or a risky payment. The app
                      // now uses a fingerprint when the device has one enrolled
                      // and falls back to the PIN when it does not — decided per
                      // prompt by BiometricOutcome.unavailable, which is more
                      // reliable than a setting the customer has to maintain.
                      _buildMenuItem(
                        icon: Icons.tune_rounded,
                        title: tr('Transaction limits'),
                        subtitle: 'Daily cap ₹1,00,000 · per-transfer ₹25,000',
                        onTap: () {
                          _showTransactionLimits();
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.shield_outlined,
                        title: tr('Security Corner'),
                        subtitle:
                            tr('Risk gate, SMS scanner, emergency freeze'),
                        onTap: () => _navigateToScreen(
                            const SecurityScreen(), '/security'),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // PRIVACY & CONSENT SECTION
                    _buildSectionTitle('PRIVACY & CONSENT'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildMenuItem(
                        icon: Icons.lock_open_rounded,
                        title: tr('Data sharing consents'),
                        subtitle: '3 active · 1 expires in 12 days',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Data sharing consents tapped')),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.history_rounded,
                        title: tr('Audit logs'),
                        subtitle: tr('Tamper-evident record of every action'),
                        onTap: () => _navigateToScreen(
                            const AuditLogsScreen(), '/audit_logs'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: tr('Privacy policy'),
                        subtitle: 'DPDP Act 2023 compliant',
                        onTap: () => _navigateToScreen(
                            const PrivacyPolicyScreen(), '/privacy_policy'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.gavel_rounded,
                        title: tr('Terms & conditions'),
                        subtitle: 'Version 1.3 · updated 12/06/2026',
                        onTap: () => _navigateToScreen(
                          const PrivacyPolicyScreen(
                            assetPath:
                                'assets/docs/Finix terms and conditions.pdf',
                            title: 'Terms & conditions',
                            cacheName: 'finix-terms.pdf',
                          ),
                          '/terms',
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.balance_rounded,
                        title: tr('Ethical charter'),
                        subtitle: tr('Fraud awareness and how to report it'),
                        onTap: () => _navigateToScreen(
                            const EthicalCharterScreen(), '/ethical_charter'),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // PREFERENCES SECTION
                    _buildSectionTitle('PREFERENCES'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildMenuItem(
                        icon: Icons.language_outlined,
                        title: tr('Language'),
                        // Was "हिंदी and 4 more available", which promised five
                        // languages the app did not have.
                        subtitle: tr('Choose your app language'),
                        trailingText:
                            LocaleService.instance.language.value.nativeName,
                        onTap: _showLanguagePicker,
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: tr('Notifications'),
                        subtitle: tr('Risk alerts, goals, market digest'),
                        // Opens the same feed as the dashboard bell, rather
                        // than showing a snackbar that did nothing.
                        onTap: () => _navigateToScreen(
                            const NotificationsScreen(), '/notifications'),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // SUPPORT SECTION
                    _buildSectionTitle('SUPPORT'),
                    const SizedBox(height: 8),
                    _buildCard([
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: tr('Help & FAQs'),
                        subtitle: tr('Guides, chat with support'),
                        // Opens the assistant rather than a snackbar; it is
                        // already the app's answer to "how do I…" questions.
                        onTap: () =>
                            _navigateToScreen(const ChatScreen(), '/chat'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.flag_outlined,
                        iconColor: const Color(0xFFDC2626),
                        iconBgColor: const Color(0xFFDC2626).withOpacity(0.1),
                        title: tr('Report fraud'),
                        subtitle: 'Files a case and dials 1930',
                        onTap: () => _navigateToScreen(
                            const ReportFraudScreen(), '/report_fraud'),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Emergency Freeze Info Banner (Figma node 1166:1923)
                    _buildEmergencyFreezeBanner(),
                    const SizedBox(height: 24),

                    // Sign Out Button (Figma node 1166:1924)
                    _buildSignOutButton(onTap: () {
                      _signOut();
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
  /// Language picker for the Preferences section.
  ///
  /// Changing language restarts the app: strings are read at build time
  /// through tr(), and a full relaunch is the only way to be certain every
  /// cached widget, controller and formatted label is rebuilt rather than a
  /// mix of both languages surviving on screens already in the stack.
  Future<void> _showLanguagePicker() async {
    final current = LocaleService.instance.language.value;

    final chosen = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr('Language'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('The app will restart to apply your choice.'),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            for (final language in AppLanguage.values) ...[
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(sheetContext, language),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.nativeName,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0A1628),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              language.englishName,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (language == current)
                        const Icon(Icons.check_circle_rounded,
                            size: 20, color: Color(0xFF16A34A)),
                    ],
                  ),
                ),
              ),
              if (language != AppLanguage.values.last) _buildDivider(),
            ],
          ],
        ),
      ),
    );

    if (chosen == null || chosen == current || !mounted) return;

    await LocaleService.instance.setLanguage(chosen);
    if (!mounted) return;

    // Brief confirmation before the screen goes away, so the restart does not
    // look like a crash.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Restarting to apply the new language…')),
        duration: const Duration(milliseconds: 900),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final restarted = await LocaleService.instance.restartApp();
    if (restarted || !mounted) return;

    // Desktop, web, or a build without the native handler: the app cannot
    // relaunch itself, so rebuild the tree in place instead. Every screen
    // reads its strings through tr() on build, so this still switches
    // language — it just does not clear the navigation stack.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Renders paise as rupees in Indian digit grouping (₹12,34,567).
  static String _money(num paise) {
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

  /// Shows the caps that apply to this account.
  ///
  /// These four figures were written into this file, and only one of them —
  /// the per-transfer step-up — was enforced anywhere. They now come from
  /// /v1/transaction-limits, which is the same policy the payment path
  /// applies, so the sheet cannot drift from what actually happens.
  Future<void> _showTransactionLimits() async {
    final data = await ApiService.instance.getTransactionLimits();
    if (!mounted) return;

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Could not load your limits. Try again.'))),
      );
      return;
    }

    int paise(String key) => ((data[key] as num?) ?? 0).round();
    final int newPayeeHours =
        ((data['newPayeeWindowHours'] as num?) ?? 24).round();
    final int nightFrom = ((data['nightStartHour'] as num?) ?? 23).round();
    final int nightTo = ((data['nightEndHour'] as num?) ?? 5).round();

    final limits = [
      (
        Icons.today_rounded,
        'Daily limit',
        _money(paise('dailyPaise')),
        '${_money(paise('dailyRemainingPaise'))} left today'
      ),
      (
        Icons.account_balance_wallet_rounded,
        'Available to send',
        _money(paise('availableToSpendPaise')),
        'Your PSB savings balance'
      ),
      (
        Icons.swap_horiz_rounded,
        'Per transfer',
        _money(paise('perTransferPaise')),
        'Anything above needs step-up authentication'
      ),
      (
        Icons.person_add_alt_1_rounded,
        'New payee, first $newPayeeHours hours',
        _money(paise('newPayeePaise')),
        'A cooling-off cap that blunts a rushed transfer'
      ),
      (
        Icons.nightlight_round,
        'Between $nightFrom:00 and $nightTo:00',
        _money(paise('nightPaise')),
        'Late-night payments carry more risk'
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr('Transaction limits'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Corrected: this used to say no cap refuses a payment outright,
              // which is only true of the per-transfer cap. The daily,
              // new-payee and late-night caps do refuse.
              tr('Caps applied by your bank. Above the per-transfer cap you '
                  'confirm with a fingerprint and a one-time code; the daily, '
                  'new-payee and late-night caps stop a payment until they '
                  'no longer apply.'),
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            for (final limit in limits) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FA),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(limit.$1,
                          size: 17, color: const Color(0xFF2E75B6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(limit.$2),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0A1628),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr(limit.$4),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amounts stay in Latin figures in every language.
                    Text(
                      limit.$3,
                      style: GoogleFonts.spaceMono(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                  ],
                ),
              ),
              if (limit != limits.last) _buildDivider(),
            ],
            const SizedBox(height: 14),
            Text(
              tr('To change a limit, contact your branch. Limits cannot be '
                  'raised from the app — that is deliberate: it is the first '
                  'thing an attacker would try.'),
              style: GoogleFonts.inter(
                fontSize: 10.5,
                height: 1.5,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      onTap: () =>
          _navigateToScreen(const PersonalDetailsScreen(), '/personal_details'),
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
                  ApiService.instance.userInitials,
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
                        ApiService.instance.userName.value ?? 'Signed out',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                              tr('KYC VERIFIED'),
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
                    (_profile['email'] ?? '').toString().isNotEmpty
                        ? _profile['email'].toString()
                        : '—',
                    style: GoogleFonts.robotoMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _memberSince,
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
                  color: iconBgColor ??
                      const Color(0xFFEEF4FA), // color/surface/sky
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor ??
                        const Color(0xFF0B2545), // color/brand/navy
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
              tr('Sign out'),
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
                tr('Settings'),
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
