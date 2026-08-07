import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class ReportAcknowledgementScreen extends StatefulWidget {
  const ReportAcknowledgementScreen({super.key});

  @override
  State<ReportAcknowledgementScreen> createState() => _ReportAcknowledgementScreenState();
}

class _ReportAcknowledgementScreenState extends State<ReportAcknowledgementScreen> {
  bool _isDownloading = false;

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Case ID "$text" copied to clipboard!'),
        backgroundColor: const Color(0xFF0B2545),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _simulateDownload() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating secure evidence pack...'),
        backgroundColor: Color(0xFF0B2545),
        duration: Duration(milliseconds: 1000),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evidence pack downloaded successfully!'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            const _StatusBar(),

            // Custom AppBar
            _buildAppBar(),

            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success checkmark section
                    _buildSuccessMessageSection(),
                    const SizedBox(height: 24),

                    // Case Details Card
                    _buildCaseDetailsCard(),
                    const SizedBox(height: 24),

                    // Immediate actions taken section
                    _buildImmediateActionsSection(),
                    const SizedBox(height: 24),

                    // What happens next section
                    _buildWhatHappensNextSection(),
                    const SizedBox(height: 24),

                    // FINIX Insight Box
                    _buildFinixInsightBox(),
                    const SizedBox(height: 24),

                    // Download Evidence Pack Button
                    _buildDownloadButton(),
                    const SizedBox(height: 16),

                    // Footer note
                    _buildFooterNote(),
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

  // Custom AppBar
  Widget _buildAppBar() {
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
                tr('Report Acknowledged'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          // Spacer to center title
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  // Success message section
  Widget _buildSuccessMessageSection() {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          // Animated checkmark visual
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF16A34A).withOpacity(0.06),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.04),
                  blurRadius: 0,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.02),
                  blurRadius: 0,
                  spreadRadius: 22,
                ),
              ],
              border: Border.all(
                color: const Color(0xFF16A34A).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF16A34A),
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.75,
              ),
              children: [
                const TextSpan(text: 'We\'ve got '),
                TextSpan(
                  text: 'your report.',
                  style: GoogleFonts.fraunces(
                    color: const Color(0xFF10B981),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle paragraph
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Your case has been logged, protected with a tamper-evident audit record, and queued for review. We\'ll keep you updated at every step.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.5,
                letterSpacing: 0.24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Case Details Card
  Widget _buildCaseDetailsCard() {
    const caseId = 'FRD-2026-081247';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2545), Color(0xFF13315C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('CASE ID'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFCBD5E1),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _copyToClipboard(caseId),
                  child: Row(
                    children: [
                      Text(
                        caseId,
                        style: GoogleFonts.robotoMono(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                          letterSpacing: 0.45,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.copy_rounded,
                        color: Color(0xFFCBD5E1),
                        size: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    tr('Under Review'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 100,
            width: 1,
            color: const Color(0xFF475569).withOpacity(0.5),
          ),
          const SizedBox(width: 16),

          // Right Column
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reported On
                Text(
                  tr('REPORTED ON'),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFCBD5E1),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '07 Jun 2026',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '02:03 AM',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),

                // Reported Via
                Text(
                  tr('REPORTED VIA'),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFCBD5E1),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('FINIX App'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('Verified'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Immediate actions taken section
  Widget _buildImmediateActionsSection() {
    final actions = [
      {'label': 'Fraud\nreport\nrecorded', 'icon': Icons.assignment_turned_in_outlined},
      {'label': 'Evidence\nuploaded\nsecurely', 'icon': Icons.lock_outline_rounded},
      {'label': 'Audit\nlog\nentry\ncreated', 'icon': Icons.shield_outlined},
      {'label': 'Emergency\nFreeze\noffered', 'icon': Icons.ac_unit_rounded},
      {'label': 'Cybercrime\npackage\nprepared', 'icon': Icons.account_balance_outlined},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Immediate actions taken'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: actions.map((act) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Center(
                        child: Icon(
                          act['icon'] as IconData,
                          color: const Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      act['label'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // What happens next timeline
  Widget _buildWhatHappensNextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('What happens next'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildTimelineStep(
          indicatorActive: true,
          lineColor: const Color(0xFF689FF8),
          icon: Icons.access_time_rounded,
          iconBgColor: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF3B82F6),
          title: 'Within 15 minutes',
          subtitle: 'Our risk team reviews your report',
          badgeText: 'IN PROGRESS',
          badgeColor: const Color(0xFF3B82F6),
          badgeBgColor: const Color(0xFFEFF6FF),
        ),
        _buildTimelineStep(
          indicatorActive: true,
          lineColor: const Color(0xFF689FF8),
          icon: Icons.account_balance_outlined,
          iconBgColor: const Color(0xFFF1F5F9),
          iconColor: const Color(0xFF64748B),
          title: 'Within 1 hour',
          subtitle: 'Case routed to your bank & cybercrime cell',
          badgeText: 'PENDING',
          badgeColor: const Color(0xFF94A3B8),
          badgeBgColor: const Color(0xFFF1F5F9),
        ),
        _buildTimelineStep(
          indicatorActive: false, // gray border indicator
          lineColor: const Color(0xFFCBD5E1),
          icon: Icons.notifications_none_rounded,
          iconBgColor: const Color(0xFFF1F5F9),
          iconColor: const Color(0xFF64748B),
          title: 'Within 24 hours',
          subtitle: 'You\'ll receive a status update on your case',
          badgeText: 'PENDING',
          badgeColor: const Color(0xFF94A3B8),
          badgeBgColor: const Color(0xFFF1F5F9),
        ),
        _buildTimelineStep(
          indicatorActive: true,
          isLast: true,
          icon: Icons.show_chart_rounded,
          iconBgColor: const Color(0xFFF1F5F9),
          iconColor: const Color(0xFF64748B),
          title: 'Ongoing',
          subtitle: 'We\'ll track the case until it\'s resolved',
          badgeText: 'PENDING',
          badgeColor: const Color(0xFF94A3B8),
          badgeBgColor: const Color(0xFFF1F5F9),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required bool indicatorActive,
    Color lineColor = const Color(0xFFCBD5E1),
    bool isLast = false,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle and line indicator column
          Column(
            children: [
              const SizedBox(height: 6),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: indicatorActive ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: 12),

          // Body text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20), // spacing for next row
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FINIX Insight Box
  Widget _buildFinixInsightBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF2E75B6),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tr('FINIX INSIGHT'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E75B6),
                      letterSpacing: 0.72,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Text
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Reporting within the first hour typically improves the chance of '),
                      TextSpan(
                        text: 'stopping funds',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' before they move across multiple accounts.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Download Evidence Pack button
  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: _simulateDownload,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1E293B),
                    ),
                  )
                : const Icon(
                    Icons.download_rounded,
                    color: Color(0xFF1E293B),
                    size: 16,
                  ),
            const SizedBox(width: 8),
            Text(
              _isDownloading ? 'Downloading...' : 'Download Evidence Pack',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Footer Note
  Widget _buildFooterNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_rounded,
          color: Color(0xFF64748B),
          size: 11,
        ),
        const SizedBox(width: 8),
        Text(
          'This report is protected by bank-grade encryption and Merkle verification.',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
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
