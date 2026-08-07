import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_detail.dart';
import 'investing_explained.dart';
import '../services/api_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Mock adding a new goal interactive state
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = false;

  // A _fallbackGoals list of four invented goals (Europe Trip, Home Down
  // Payment, Child Education, Emergency Fund) used to fill this screen whenever
  // /v1/goals returned nothing or errored, showing every customer the same
  // aspirations and balances. Goals are now only ever what the API returns.

  @override
  void initState() {
    super.initState();
    // Re-read whenever the customer changes something anywhere in the app.
    // Without this the screen kept whatever it loaded on first build, so a
    // payment made elsewhere left stale figures here.
    ApiService.instance.dataVersion.addListener(_onDataChanged);
    _fetchGoals();
  }

  @override
  void dispose() {
    ApiService.instance.dataVersion.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    setState(() => _isLoading = true);
    try {
      final apiGoals = await ApiService.instance.getGoals();
      if (mounted) {
        setState(() {
          _goals = apiGoals.map(_mapApiGoal).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _goals = [];
          _isLoading = false;
        });
      }
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _monthYear(dynamic iso) {
    final parsed = DateTime.tryParse((iso ?? '').toString());
    if (parsed == null) return '--';
    return '${_months[parsed.month - 1]} ${parsed.year}';
  }

  Map<String, dynamic> _mapApiGoal(Map<String, dynamic> apiGoal) {
    final double target = (apiGoal['targetAmountPaise'] ?? 0) / 100;
    final double saved = (apiGoal['savedAmountPaise'] ?? 0) / 100;
    final double progress = target > 0 ? (saved / target) : 0.0;
    final String priority = apiGoal['priority'] ?? 'medium';
    
    Color progressColor = const Color(0xFF16A34A);
    String badgeText = 'ON TRACK';
    if (progress >= 1.0) {
      progressColor = const Color(0xFFC8A951);
      badgeText = 'ACHIEVED';
    } else if (priority == 'high' && progress < 0.5) {
      progressColor = const Color(0xFFF59E0B);
      badgeText = 'CATCH UP';
    }

    final double monthlyRupees = (apiGoal['monthlyContributionPaise'] ?? 0) / 100;
    
    return {
      'goalId': apiGoal['goalId'],
      // Seeded goal names recur across every demo account, so they are in
      // the dictionaries; anything unrecognised stays as the backend sent it.
      'title': tr((apiGoal['name'] ?? 'Financial Goal').toString()),
      'subtitle': (apiGoal['description'] ?? '').toString().isNotEmpty
          ? apiGoal['description'].toString()
          : 'Target ${_monthYear(apiGoal['targetDate'])}',
      'badgeText': badgeText,
      'badgeColor': progressColor,
      'badgeBgColor': progressColor.withOpacity(0.1),
      'saved': saved,
      'target': target,
      'progress': progress,
      'progressColor': progressColor,
      'monthly': monthlyRupees > 0 ? '₹${monthlyRupees.toStringAsFixed(0)}' : '₹0',
      // Was a fixed "Next: 10 Jul". The API has no next-contribution date, but
      // it does have the target date, which is the deadline that matters here.
      'rightLabel': 'By: ',
      'rightValue': _monthYear(apiGoal['targetDate']),
      'icon': progress >= 1.0 ? Icons.emoji_events_outlined : Icons.trending_up_rounded,
      'iconBgColor': progress >= 1.0 ? const Color(0xFFFFF9EC) : const Color(0xFFEEF4FA),
      'iconColor': progressColor,
      'isCompleted': progress >= 1.0,
    };
  }

  void _addNewGoalDialog() {
    Navigator.push(
      context,
      SmoothPageRoute(
        settings: const RouteSettings(name: '/investing_explained'),
        builder: (context) => InvestingExplainedScreen(
          onGoalCreated: (newGoal) async {
            setState(() {
              _goals.insert(0, newGoal);
            });
            try {
              final double target = newGoal['target'] ?? 10000.0;
              final double monthly = newGoal['saved'] ?? 500.0;
              await ApiService.instance.createGoal(
                name: newGoal['title'],
                description: newGoal['subtitle'],
                targetAmountPaise: (target * 100).toInt(),
                targetDate: DateTime.now().add(const Duration(days: 365)).toIso8601String(),
                monthlyContributionPaise: (monthly * 100).toInt(),
                priority: 'medium',
              );
            } catch (_) {}
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar (Figma node 640:3614)
            _buildAppBar(context),

            // Scrollable Goals List
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Overview Savings Card (Figma node 640:3623)
                    _buildOverviewCard(),
                    const SizedBox(height: 16),

                    // Add new goal action link (Figma node 640:3635)
                    _buildAddNewGoalLink(),
                    if (_goals.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          tr('Long-press a goal to delete it.'),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Goals cards list
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_goals.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.flag_outlined,
                                size: 28, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text(
                              tr('No goals yet'),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('Add a goal above to start tracking progress.'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _goals.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return _buildGoalCard(goal);
                      },
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left back arrow
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
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
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF475569),
                  size: 16,
                ),
              ),
            ),
          ),
          // Center title
          Text(
            tr('Goals'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          // Right search button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Search is not available in prototype mode.',
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
                  Icons.search_rounded,
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

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B2545),
            Color(0xFF13315C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('TOTAL GOAL SAVINGS'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.32,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '8,42,150',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: -1.08,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 17.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '4 active · 1 completed',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: '62%',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' on track'),
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

  Widget _buildAddNewGoalLink() {
    return GestureDetector(
      onTap: _addNewGoalDialog,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            const Icon(
              Icons.add_rounded,
              color: Color(0xFF2E75B6),
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              tr('Add new goal'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E75B6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Deletes a goal, after asking.
  ///
  /// Goals could be created but never removed, so a mistyped or abandoned one
  /// stayed on the list forever. Deletion is confirmed because the saved amount
  /// and its history go with it.
  Future<void> _confirmDelete(Map<String, dynamic> goal) async {
    final name = (goal['title'] ?? 'this goal').toString();
    final goalId = (goal['goalId'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr('Delete goal?'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        ),
        content: Text(
          '$name ${tr('and its contribution history will be removed. Money already saved stays in your account.')}',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: const Color(0xFF475569),
          ),
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
              tr('Delete'),
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

    if (confirmed != true || !mounted) return;

    // Removed locally first so the list responds immediately; the reload below
    // is what makes it stick, and restores the goal if the call failed.
    setState(() => _goals.removeWhere((g) => g['goalId'] == goal['goalId']));

    if (goalId.isNotEmpty) {
      await ApiService.instance.dissolveGoal(goalId);
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name ${tr('deleted')}')),
    );
    await _fetchGoals();
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final bool isCompleted = goal['isCompleted'] as bool;

    // Completed gold styling options
    final BoxDecoration cardDecoration = isCompleted
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8A951), width: 1),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFF9EC),
                Colors.white.withOpacity(0.3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.3, 1.0],
            ),
          )
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          );

    return GestureDetector(
      onLongPress: () => _confirmDelete(goal),
      onTap: () {
        Navigator.push(
          context,
          SmoothPageRoute(
            settings: const RouteSettings(name: '/goal_detail'),
            builder: (context) => GoalDetailScreen(goalData: goal),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(17.0),
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: goal['iconBgColor'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          goal['icon'],
                          color: goal['iconColor'],
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal['title'],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal['subtitle'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: goal['badgeBgColor'],
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    goal['badgeText'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: goal['badgeColor'],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 6,
                color: const Color(0xFFE2E8F0),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: goal['progress'],
                  child: Container(
                    color: goal['progressColor'],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Saved vs Target Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹${_formatCurrency(goal['saved'])}',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0A1628),
                    letterSpacing: -0.36,
                  ),
                ),
                Text(
                  'of ₹${_formatCurrency(goal['target'])}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),

            // Bottom Row (only for active/non-completed goals)
            if (!isCompleted) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 11.0),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF475569),
                        ),
                        children: [
                          const TextSpan(text: 'Monthly: '),
                          TextSpan(
                            text: goal['monthly'],
                            style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0A1628),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF475569),
                        ),
                        children: [
                          TextSpan(text: goal['rightLabel']),
                          TextSpan(
                            text: goal['rightValue'],
                            style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0A1628),
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
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(0)} Cr';
    }
    // Simple formatting for lakhs
    final int value = amount.toInt();
    if (value == 0) return '0';

    final String valStr = value.toString();
    if (valStr.length <= 3) return valStr;

    final String lastThree = valStr.substring(valStr.length - 3);
    String remaining = valStr.substring(0, valStr.length - 3);

    // Format remaining with commas every 2 digits (Indian numbering format)
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
