import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/contact_service.dart';
import '../services/locale_service.dart';
import 'ethical_charter_document.dart';

/// Fraud awareness and where to report it.
///
/// Reached from Settings › Ethical charter, which previously only showed an
/// "Ethical charter tapped" snackbar. Every number here opens the dialer and
/// the portal opens in the browser, so a customer mid-fraud does not have to
/// copy digits by hand while panicking.
class EthicalCharterScreen extends StatelessWidget {
  const EthicalCharterScreen({super.key});

  static const Color _ink = Color(0xFF0A1628);
  static const Color _slate = Color(0xFF475569);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _brand = Color(0xFF2E75B6);
  static const Color _navy = Color(0xFF0B2545);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _gold = Color(0xFFC8A951);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 24),

                    _sectionTitle(tr('IF YOU HAVE BEEN DEFRAUDED')),
                    const SizedBox(height: 10),
                    _buildEmergencyCard(context),
                    const SizedBox(height: 24),

                    _sectionTitle(tr('HOW FRAUD USUALLY STARTS')),
                    const SizedBox(height: 10),
                    _buildFraudTypes(),
                    const SizedBox(height: 24),

                    _sectionTitle(tr('WHAT FINIX WILL NEVER DO')),
                    const SizedBox(height: 10),
                    _buildNeverDoCard(),
                    const SizedBox(height: 24),

                    _sectionTitle(tr('OUR COMMITMENTS TO YOU')),
                    const SizedBox(height: 10),
                    _buildCommitments(),
                    const SizedBox(height: 16),
                    _buildFullCharterLink(context),
                    const SizedBox(height: 24),

                    _buildFooter(),
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _ink),
            onPressed: () => Navigator.maybePop(context),
          ),
          Text(
            tr('Ethical charter'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Navy hero, matching the dashboard net-worth card.
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF13315C)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.verified_user_outlined,
                    color: _gold, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                tr('FINIX ETHICAL CHARTER'),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _gold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tr('Your money, on your terms'),
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Most financial fraud succeeds by creating urgency. Nothing '
                'genuine from your bank ever needs to happen in the next two '
                'minutes. Slowing down is the single most effective thing you '
                'can do.'),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.6,
              color: Colors.white.withOpacity(0.86),
            ),
          ),
        ],
      ),
    );
  }

  /// The action card: helpline, portal, bank. Every row is tappable.
  Widget _buildEmergencyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _danger.withOpacity(0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _danger.withOpacity(0.06),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 15, color: _danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('Report within the first hour. Funds can often still be '
                        'held before they move on through other accounts.'),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _actionRow(
            context: context,
            icon: Icons.phone_in_talk_rounded,
            iconColor: _danger,
            title: tr('National Cyber Crime Helpline'),
            value: FinixContacts.cyberCrimeHelpline,
            subtitle: tr('Toll-free, round the clock'),
            trailing: Icons.call_rounded,
            onTap: () =>
                FinixLauncher.dial(context, FinixContacts.cyberCrimeHelpline),
          ),
          _divider(),
          _actionRow(
            context: context,
            icon: Icons.language_rounded,
            iconColor: _brand,
            title: tr('Report online'),
            value: 'cybercrime.gov.in',
            subtitle: tr('National Cyber Crime Reporting Portal'),
            trailing: Icons.open_in_new_rounded,
            onTap: () =>
                FinixLauncher.open(context, FinixContacts.cyberCrimePortal),
          ),
          _divider(),
          _actionRow(
            context: context,
            icon: Icons.account_balance_rounded,
            iconColor: _navy,
            title: tr('Punjab & Sind Bank'),
            value: FinixContacts.bankHelpline,
            subtitle: tr('Block cards and dispute a debit'),
            trailing: Icons.call_rounded,
            onTap: () => FinixLauncher.dial(context, FinixContacts.bankHelpline),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required IconData trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _slate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // The number itself is monospaced and dark: it is the thing
                  // the customer is looking for on this screen.
                  Text(
                    value,
                    style: GoogleFonts.robotoMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 10.5, color: _muted),
                  ),
                ],
              ),
            ),
            Icon(trailing, size: 18, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFraudTypes() {
    const types = [
      (
        Icons.sms_failed_outlined,
        'Phishing texts and calls',
        'A message about a blocked account or expiring KYC, with a link. Banks '
            'do not send links that ask you to log in.',
      ),
      (
        Icons.screen_share_outlined,
        'Screen-sharing scams',
        'A "support agent" asks you to install AnyDesk or TeamViewer so they '
            'can "fix" something. They are watching you type your PIN.',
      ),
      (
        Icons.qr_code_scanner_rounded,
        'QR codes to receive money',
        'You never scan a QR code to receive funds. Scanning one authorises a '
            'payment out of your account.',
      ),
      (
        Icons.work_outline_rounded,
        'Investment and task jobs',
        'Small early payouts to build trust, then a large deposit is requested '
            'and the account disappears.',
      ),
      (
        Icons.person_search_outlined,
        'Digital arrest calls',
        'Someone claiming to be police or CBI keeps you on video and demands a '
            'transfer. No agency in India works this way.',
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < types.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(types[i].$1, size: 18, color: _brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(types[i].$2),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(types[i].$3),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 1.5,
                          color: _slate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNeverDoCard() {
    const promises = [
      'Ask for your PIN, password, OTP or CVV — on a call, a chat or this app',
      'Send you a link to log in or "re-verify" your account',
      'Ask you to install a screen-sharing or remote-access app',
      'Move money out of your account on your behalf',
      'Threaten you with arrest, a penalty or an account closure',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < promises.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.block_flipped, size: 15, color: _danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(promises[i]),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.5,
                      color: _slate,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommitments() {
    const commitments = [
      (
        Icons.visibility_outlined,
        'We explain our decisions',
        'Every risk score and nudge comes with the reason behind it.',
      ),
      (
        Icons.lock_outline_rounded,
        'Your data stays yours',
        'Read-only access through the account aggregator framework, revocable '
            'at any time.',
      ),
      (
        Icons.fact_check_outlined,
        'Nothing is hidden',
        'Every action is written to a tamper-evident audit log you can read.',
      ),
      (
        Icons.pan_tool_outlined,
        'We never sell advice',
        'FINIX earns nothing from what you invest in, so no suggestion is paid '
            'for.',
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < commitments.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(commitments[i].$1, size: 17, color: _navy),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(commitments[i].$2),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tr(commitments[i].$3),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 1.45,
                          color: _slate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Opens the governing document itself.
  ///
  /// The sections above are the plain-language version a customer needs in the
  /// moment; this is the full FINIX Twin Ethical AI Charter, with its DPDP Act
  /// and RBI FREE-AI basis.
  Widget _buildFullCharterLink(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/ethical_charter_document'),
          builder: (_) => const EthicalCharterDocumentScreen(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _navy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.article_outlined, size: 18, color: _navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Read the full Ethical AI Charter'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr('Version 1.0 · DPDP Act 2023 and RBI FREE-AI'),
                    style: GoogleFonts.inter(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      tr('This charter describes how FINIX operates. It is not legal advice. '
          'If you believe you have been defrauded, report it above before '
          'contacting anyone else.'),
      style: GoogleFonts.inter(fontSize: 10.5, height: 1.5, color: _muted),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _slate,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: _line);
}
