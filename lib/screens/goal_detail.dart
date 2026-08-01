import 'package:flutter/material.dart';
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
    final data = widget.goalData ?? {
      'title': 'Europe Trip',
      'subtitle': 'Jun 2027 · 8 weeks ahead',
      'badgeText': 'ON TRACK',
      'badgeColor': const Color(0xFF16A34A),
      'badgeBgColor': const Color(0xFF16A34A).withOpacity(0.1),
      'saved': 730000.0,
      'target': 1000000.0,
      'progress': 0.73,
      'progressColor': const Color(0xFF16A34A),
      'monthly': '₹15,000',
      'rightLabel': 'Next: ',
      'rightValue': '05 Jul',
      'icon': Icons.airplanemode_active_rounded,
      'iconBgColor': const Color(0xFFEEF4FA),
      'iconColor': const Color(0xFF2E75B6),
      'isCompleted': false,
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
            'Add Money to Goal',
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
                'Cancel',
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
                'Deposit',
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
            'Goal',
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
                  'Run What-If',
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
                  'Add money',
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
                'Full history →',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Bar Chart
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('JAN', 52, isGold: false, amount: '₹15,000'),
                _buildBar('FEB', 48, isGold: false, amount: '₹15,000'),
                _buildBar('MAR', 65, isGold: true, amount: '₹20,000 (Bonus)'),
                _buildBar('APR', 50, isGold: false, amount: '₹15,000'),
                _buildBar('MAY', 56, isGold: false, amount: '₹15,000'),
                _buildBar('JUN', 60, isGold: false, amount: '₹15,000'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String month, double height, {required bool isGold, required String amount}) {
    final barGradient = isGold
        ? const LinearGradient(
            colors: [Color(0xFFC8A951), Color(0xFFD8BE73)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFF2E75B6), Color(0xFF5A96CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Tooltip(
      message: '$month contribution:\n$amount',
      triggerMode: TooltipTriggerMode.tap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 42.6,
            height: height,
            decoration: BoxDecoration(
              gradient: barGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            month,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.54,
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
              'Linked sources',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            ),
            Text(
              'Manage →',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E75B6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // HDFC Bluechip SIP Card (Figma node 640:4622)
        _buildSourceCard(
          icon: Icons.trending_up_rounded,
          title: 'HDFC Bluechip SIP',
          subtitle: 'Every 5th · Auto · Active',
          amount: '₹10,000',
        ),
        const SizedBox(height: 8),

        // SGB Auto-buy Card (Figma node 640:4629)
        _buildSourceCard(
          icon: Icons.card_membership_rounded,
          title: 'SGB Auto-buy',
          subtitle: 'Quarterly · Manual · Active',
          amount: '₹5,000',
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
          'Milestones',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        ),
        const SizedBox(height: 10),

        // Milestone 1 (Done)
        _buildMilestoneCard(
          isDone: true,
          title: 'Crossed ₹5,00,000 · Halfway there',
          subtitle: 'Achieved 18 Feb 2026',
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: 8),

        // Milestone 2 (Done)
        _buildMilestoneCard(
          isDone: true,
          title: 'Reached 70% · ₹7,00,000',
          subtitle: 'Achieved 04 Jun 2026',
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: 8),

        // Milestone 3 (Upcoming)
        _buildMilestoneCard(
          isDone: false,
          title: 'Cross ₹9,00,000',
          subtitle: 'Est. Feb 2027',
          icon: Icons.circle_outlined,
        ),
        const SizedBox(height: 8),

        // Milestone 4 (Upcoming)
        _buildMilestoneCard(
          isDone: false,
          title: 'Goal completion',
          subtitle: 'Est. Apr 2027 · 2 months early',
          icon: Icons.calendar_today_rounded,
        ),
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
