import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecurityEventsScreen extends StatefulWidget {
  const SecurityEventsScreen({super.key});

  @override
  State<SecurityEventsScreen> createState() => _SecurityEventsScreenState();
}

class _SecurityEventsScreenState extends State<SecurityEventsScreen> {
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
                      'Recent activity',
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
            'Security Events',
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
                    'Ledger database is up to date.',
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
                children: const [
                  TextSpan(text: 'Each event is written to a tamper-evident log. '),
                  TextSpan(
                    text: 'Verified',
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

  Widget _buildTimeline() {
    return Column(
      children: [
        // Event 1: Risk warning shown
        _buildTimelineItem(
          showLine: true,
          icon: _buildIconIndicator(
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFDC2626).withOpacity(0.1),
          ),
          title: 'Risk warning shown',
          badge: _buildRiskBadge('High 78'),
          description: 'Paused a ₹85,000 transfer to a new payee at 1:47 AM. You cancelled it.',
          time: 'Today, 1:47 AM · Ref HDFC8472',
        ),

        // Event 2: SMS flagged as fraud
        _buildTimelineItem(
          showLine: true,
          icon: _buildIconIndicator(
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFF59E0B).withOpacity(0.1),
          ),
          title: 'SMS flagged as fraud',
          badge: _buildVerifiedBadge(),
          description: 'A message posing as your bank with a payment link was blocked.',
          time: 'Yesterday, 6:12 PM',
        ),

        // Event 3: New device sign-in
        _buildTimelineItem(
          showLine: true,
          icon: _buildIconIndicator(
            icon: Icons.phone_android_rounded,
            color: const Color(0xFF2E75B6),
            bgColor: const Color(0xFFEEF4FA),
          ),
          title: 'New device sign-in',
          badge: _buildVerifiedBadge(),
          description: 'Signed in from a Pixel 8 · Bengaluru. This was you.',
          time: '14/06/2026, 9:02 AM',
        ),

        // Event 4: Emergency Freeze armed
        _buildTimelineItem(
          showLine: false,
          icon: _buildIconIndicator(
            icon: Icons.lock_outline_rounded,
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFF16A34A).withOpacity(0.1),
          ),
          title: 'Emergency Freeze armed',
          badge: _buildVerifiedBadge(),
          description: 'Quick-halt protection turned on from Security.',
          time: '12/06/2026, 4:30 PM',
        ),
      ],
    );
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
            'VERIFIED',
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
