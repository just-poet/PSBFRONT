import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'simulation.dart';
import '../main.dart';

class GoalDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? goalData;
  const GoalDetailScreen({super.key, this.goalData});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  // Interactive deposit savings simulation
  late double _savedAmount;
  late double _targetAmount;
  late String _title;
  late String _subtitle;
  late String _monthly;
  late IconData _icon;
  late String _badgeText;
  late Color _badgeColor;
  late Color _badgeBgColor;

  @override
  void initState() {
    super.initState();
    // Opened without a goal this used to become a full "Europe Trip" with
    // Rs 7,30,000 saved of Rs 10,00,000 — a goal the customer never set. An
    // empty shell is the honest default; in practice goalData is always passed
    // from the goals list.
    final data = widget.goalData ??
        <String, dynamic>{
          'title': 'Goal',
          'subtitle': '',
          'badgeText': '',
          'badgeColor': const Color(0xFF64748B),
          'badgeBgColor': const Color(0x1A64748B),
          'saved': 0.0,
          'target': 0.0,
          'monthly': '',
          'icon': Icons.flag_outlined,
        };

    _title = data['title'] as String;
    _subtitle = data['subtitle'] as String;
    _savedAmount = (data['saved'] as num).toDouble();
    _targetAmount = (data['target'] as num).toDouble();
    _monthly = data['monthly'] as String;
    _icon = data['icon'] as IconData;
    _badgeText = data['badgeText'] as String;
    _badgeColor = data['badgeColor'] as Color;
    _badgeBgColor = data['badgeBgColor'] as Color;
  }

  /// Indian grouping, used by the milestone labels.
  static String _money(double rupees) {
    final n = rupees.round().abs().toString();
    if (n.length <= 3) return '\u20B9$n';
    final last3 = n.substring(n.length - 3);
    var rest = n.substring(0, n.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '\u20B9${groups.join(',')},$last3';
  }

  void _runWhatIfSimulation() {
    Navigator.push(
      context,
      SmoothPageRoute(
        settings: const RouteSettings(name: '/simulation'),
        builder: (context) => const MobileDeviceFrame(child: SimulationScreen()),
      ),
    );
  }

  Widget _buildSimulationRow(String label, String value, String highlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              highlight,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0A1628),
          ),
        ),
      ],
    );
  }

  void _addMoneyDialog() {
    double deposit = 10000.0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            tr('Add Money to Goal'),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0A1628),
            ),
          ),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Deposit Amount (₹)',
              border: OutlineInputBorder(),
              hintText: 'e.g., 10000',
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) => deposit = double.tryParse(val) ?? 10000.0,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('Cancel'),
                style: GoogleFonts.inter(color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B2545),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _savedAmount += deposit;
                  if (_savedAmount > _targetAmount) {
                    _savedAmount = _targetAmount;
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deposited ₹${deposit.toInt()} successfully!'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              },
              child: Text(
                tr('Deposit'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_savedAmount / _targetAmount).clamp(0.0, 1.0);
    final double remaining = _targetAmount - _savedAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar (Figma node 640:4555)
            _buildAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Hero Card (Figma node 640:4563)
                    _buildHeroCard(progress, remaining),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Stats summary card overlay (Figma node 640:4578)
                          _buildStatsCard(),
                          const SizedBox(height: 20),

                          // Buttons: Run What-If & Add money (Figma node 640:4594)
                          _buildActionButtons(),
                          const SizedBox(height: 24),

                          // Contributions chart (Figma node 640:4599)
                          _buildChartCard(),
                          const SizedBox(height: 24),

                          // Linked sources (Figma node 640:4663)
                          _buildLinkedSourcesSection(),
                          const SizedBox(height: 24),

                          // Milestones (Figma node 640:4636)
                          _buildMilestonesSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left back chevron
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF475569),
                  size: 16,
                ),
              ),
            ),
          ),
          // Title
          Text(
            tr('Goal'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          // Right Share button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sharing link copied to clipboard.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF0B2545),
                ),
              );
            },
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
                  Icons.share_outlined,
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

  Widget _buildHeroCard(double progress, double remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25.0, 16.0, 25.0, 24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0D284D),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and goal info row
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2E75B6),
                      Color(0xFF0B2545),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFFE2E8F0),
                        letterSpacing: -0.44,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target $_subtitle',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: -0.16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Total Savings Amount
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              children: [
                const TextSpan(text: '₹'),
                TextSpan(text: _formatCurrency(_savedAmount)),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Target description
          RichText(
            text: TextSpan(
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: Colors.white,
                letterSpacing: -0.16,
              ),
              children: [
                const TextSpan(text: 'of '),
                TextSpan(
                  text: '₹${_formatCurrency(_targetAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' · ₹${_formatCurrency(remaining)} to go'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Progress Track
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: const Color(0xFFE2E8F0),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2E75B6),
                        Color(0xFF0B2545),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Completion labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% complete',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeBgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _badgeColor,
                    letterSpacing: 0.22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    String projectedCompletion = 'Apr 2027';
    if (_subtitle.contains('·')) {
      projectedCompletion = _subtitle.split('·')[0].trim();
    } else {
      projectedCompletion = _subtitle;
    }

    return Container(
      padding: const EdgeInsets.all(17.0),
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
        ],
      ),
      child: Column(
        children: [
          _buildStatRow('Started on', '14 Mar 2025'),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
          _buildStatRow('Monthly contribution', _monthly.isNotEmpty ? _monthly : 'N/A'),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
          _buildStatRow('Next debit', _monthly.isNotEmpty ? '05 Jul · $_monthly' : 'N/A'),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
          _buildStatRow('Projected completion', projectedCompletion, isGreen: true),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
          _buildStatRow('Expected return p.a.', '8.5%'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String name, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isGreen ? const Color(0xFF16A34A) : const Color(0xFF0A1628),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _runWhatIfSimulation,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0B2545)),
              ),
              child: Center(
                child: Text(
                  tr('Run What-If'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B2545),
                    letterSpacing: -0.13,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _addMoneyDialog,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0B2545),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  tr('Add money'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(17.0),
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 6 months',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                ),
              ),
              Text(
                tr('Full history →'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // A six-bar JAN-JUN chart at a flat Rs 15,000 (with a Rs 20,000
          // "Bonus" in March) used to sit here. /v1/goals/{id}/history returns
          // lifecycle events, not per-month contribution amounts, so there is
          // nothing to plot; inventing the bars would misreport how much the
          // customer has been putting aside.
          Text(
            _monthly.isNotEmpty
                ? 'Contributing $_monthly a month. Per-month history is not '
                    'available yet.'
                : 'Per-month contribution history is not available yet.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLinkedSourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Linked sources'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            ),
            Text(
              tr('Manage →'),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E75B6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Two cards, "HDFC Bluechip SIP Rs 10,000" and "SGB Auto-buy
        // Rs 5,000", were hardcoded here. No endpoint exposes the mandates
        // funding a goal, so the only figure that can be shown is the monthly
        // contribution on the goal record itself.
        if (_monthly.isNotEmpty)
          _buildSourceCard(
            icon: Icons.autorenew_rounded,
            title: 'Monthly contribution',
            subtitle: 'From your goal plan',
            amount: _monthly,
          )
        else
          Text(
            tr('No contribution plan set for this goal.'),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
      ],
    );
  }

  Widget _buildSourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF2E75B6),
                size: 18,
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
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0A1628),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Milestones'),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        ),
        const SizedBox(height: 10),

        // Milestones are percentage marks against this goal's own target. They
        // were fixed at Rs 5,00,000 / Rs 7,00,000 / Rs 9,00,000 with invented
        // achievement dates, which only ever matched a Rs 10,00,000 goal.
        for (final fraction in const [0.25, 0.5, 0.75, 1.0]) ...[
          _buildMilestoneCard(
            isDone: _targetAmount > 0 && _savedAmount >= _targetAmount * fraction,
            title: fraction == 1.0
                ? 'Goal completion \u00B7 ${_money(_targetAmount)}'
                : '${(fraction * 100).round()}% \u00B7 ${_money(_targetAmount * fraction)}',
            subtitle: _targetAmount > 0 &&
                    _savedAmount >= _targetAmount * fraction
                ? 'Reached'
                : '${_money((_targetAmount * fraction) - _savedAmount)} to go',
            icon: _targetAmount > 0 && _savedAmount >= _targetAmount * fraction
                ? Icons.shield_rounded
                : Icons.circle_outlined,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildMilestoneCard({
    required bool isDone,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final cardDecoration = isDone
        ? BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC8A951), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2545).withOpacity(0.04),
                blurRadius: 1.5,
                offset: const Offset(0, 1),
              ),
            ],
          )
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2545).withOpacity(0.04),
                blurRadius: 1.5,
                offset: const Offset(0, 1),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: cardDecoration,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFC8A951).withOpacity(0.13) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isDone ? const Color(0xFFC8A951) : const Color(0xFF94A3B8),
                size: 16,
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
                    fontWeight: FontWeight.w600,
                    color: isDone ? const Color(0xFF0A1628) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(0)} Cr';
    }
    final int value = amount.toInt();
    if (value == 0) return '0';

    final String valStr = value.toString();
    if (valStr.length <= 3) return valStr;

    final String lastThree = valStr.substring(valStr.length - 3);
    String remaining = valStr.substring(0, valStr.length - 3);

    final List<String> chunks = [];
    while (remaining.length > 2) {
      chunks.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      chunks.insert(0, remaining);
    }
    return '${chunks.join(',')},$lastThree';
  }
}
