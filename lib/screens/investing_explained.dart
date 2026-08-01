import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'new_goal.dart';

class InvestingExplainedScreen extends StatelessWidget {
  final Function(Map<String, dynamic> newGoal) onGoalCreated;

  const InvestingExplainedScreen({
    super.key,
    required this.onGoalCreated,
  });

  void _navigateToNewGoal(BuildContext context) {
    Navigator.pushReplacement(
      context,
      SmoothPageRoute(
        settings: const RouteSettings(name: '/new_goal'),
        builder: (context) => NewGoalScreen(
          onGoalCreated: onGoalCreated,
        ),
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
            // Custom App Bar (Figma node 778:1700)
            _buildAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // Category Subtitle (Figma node 778:1709)
                    Text(
                      "NEW TO INVESTING",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Main Title (Figma node 778:1711)
                    Text(
                      "Three calm steps\nto your first\ninvestment",
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0B2545),
                        height: 1.2,
                        letterSpacing: -0.52,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Intro Paragraph (Figma node 778:1713)
                    Text(
                      "No jargon. We'll walk you through what to do, where to put your money, and how much may suit you.",
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Steps Card Container (Figma node 778:1714)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B2545).withOpacity(0.04),
                            blurRadius: 1.5,
                            offset: const Offset(0, 1),
                          ),
                          BoxShadow(
                            color: const Color(0xFF0B2545).withOpacity(0.06),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Step 1 (Figma node 778:1715)
                          _buildStepItem(
                            number: "1",
                            title: "How to create an investment",
                            description:
                                "Pick a goal, choose a fund or scheme, and set up a one-time amount or a monthly SIP. FINIX handles the paperwork and KYC checks.",
                          ),
                          // Divider
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Divider(color: Color(0xFFE2E8F0), height: 1),
                          ),
                          // Step 2 (Figma node 778:1723)
                          _buildStepItem(
                            number: "2",
                            title: "Where to invest",
                            description:
                                "Start with index or large-cap funds for stability, add a small-cap for growth, and keep some in gold or fixed deposits as a cushion.",
                          ),
                          // Divider
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Divider(color: Color(0xFFE2E8F0), height: 1),
                          ),
                          // Step 3 (Figma node 778:1731)
                          _buildStepItem(
                            number: "3",
                            title: "How much money",
                            descriptionRich: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                                height: 1.45,
                              ),
                              children: const [
                                TextSpan(
                                    text:
                                        "A common starting point is 15–20% of monthly income. Based on your profile, "),
                                TextSpan(
                                  text: "₹8,000–₹12,000/mo",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0A1628),
                                  ),
                                ),
                                TextSpan(
                                    text:
                                        " may be comfortable. These are estimates, not promises."),
                              ],
                            ),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Insight Card (Figma node 778:1739)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FA), // color/surface/sky
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Icon Container (Figma node 778:1740)
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF2E75B6),
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge (Figma node 778:1743)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "FINIX INSIGHT",
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E75B6),
                                      letterSpacing: 0.51,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Description (Figma node 778:1745)
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF0A1628),
                                      height: 1.45,
                                    ),
                                    children: const [
                                      TextSpan(text: "A "),
                                      TextSpan(
                                        text: "₹10,000/mo",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0B2545),
                                        ),
                                      ),
                                      TextSpan(text: " SIP at an estimated "),
                                      TextSpan(
                                        text: "11%",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0B2545),
                                        ),
                                      ),
                                      TextSpan(text: " may grow toward "),
                                      TextSpan(
                                        text: "₹23 L",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0B2545),
                                        ),
                                      ),
                                      TextSpan(
                                          text:
                                              " in 10 years. Projected, not assured."),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons (Figma node 778:1746)
                    GestureDetector(
                      onTap: () => _navigateToNewGoal(context),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2545),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Start a SIP →",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _navigateToNewGoal(context),
                      child: Container(
                        height: 40,
                        color: Colors.transparent,
                        child: Center(
                          child: Text(
                            "Explore funds",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E75B6),
                            ),
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Left back arrow inside white rounded border box
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
          // Title
          Expanded(
            child: Center(
              child: Text(
                "Getting Started",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          // Right ghost spacer to center the title
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    String? description,
    TextSpan? descriptionRich,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navy circle with number (Figma node 778:1716)
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF0B2545),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.fraunces(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Title (Figma node 778:1720)
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 4),
                // Step Description (Figma node 778:1722)
                if (descriptionRich != null)
                  RichText(text: descriptionRich)
                else if (description != null)
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
