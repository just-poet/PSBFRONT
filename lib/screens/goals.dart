import 'package:flutter/material.dart';
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

  final List<Map<String, dynamic>> _fallbackGoals = [
    {
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
    },
    {
      'title': 'Home Down Payment',
      'subtitle': 'Dec 2028 · 3 months behind',
      'badgeText': 'CATCH UP',
      'badgeColor': const Color(0xFFF59E0B),
      'badgeBgColor': const Color(0xFFF59E0B).withOpacity(0.1),
      'saved': 420000.0,
      'target': 1500000.0,
      'progress': 0.28,
      'progressColor': const Color(0xFFF59E0B),
      'monthly': '₹25,000',
      'rightLabel': 'Suggested: ',
      'rightValue': '₹28,500',
      'icon': Icons.home_rounded,
      'iconBgColor': const Color(0xFFEEF4FA),
      'iconColor': const Color(0xFF2E75B6),
      'isCompleted': false,
    },
    {
      'title': 'Child Education',
      'subtitle': 'May 2031 · On track',
      'badgeText': 'ON TRACK',
      'badgeColor': const Color(0xFF16A34A),
      'badgeBgColor': const Color(0xFF16A34A).withOpacity(0.1),
      'saved': 180000.0,
      'target': 1000000.0,
      'progress': 0.18,
      'progressColor': const Color(0xFF16A34A),
      'monthly': '₹8,000',
      'rightLabel': 'Next: ',
      'rightValue': '10 Jul',
      'icon': Icons.school_rounded,
      'iconBgColor': const Color(0xFFEEF4FA),
      'iconColor': const Color(0xFF2E75B6),
      'isCompleted': false,
    },
    {
      'title': 'Emergency Fund',
      'subtitle': 'Completed · 12 Feb 2026',
      'badgeText': 'ACHIEVED',
      'badgeColor': const Color(0xFFC8A951),
      'badgeBgColor': const Color(0xFFC8A951).withOpacity(0.13),
      'saved': 300000.0,
      'target': 300000.0,
      'progress': 1.0,
      'progressColor': const Color(0xFFC8A951),
      'monthly': '',
      'rightLabel': '',
      'rightValue': '',
      'icon': Icons.emoji_events_outlined,
      'iconBgColor': const Color(0xFFFFF9EC),
      'iconColor': const Color(0xFFC8A951),
      'isCompleted': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    setState(() => _isLoading = true);
    try {
      final apiGoals = await ApiService.instance.getGoals();
      if (mounted) {
        setState(() {
          if (apiGoals.isNotEmpty) {
            _goals = apiGoals.map((g) => _mapApiGoal(g)).toList();
          } else {
            _goals = List.from(_fallbackGoals);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _goals = List.from(_fallbackGoals);
          _isLoading = false;
        });
      }
    }
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
      'title': apiGoal['name'] ?? 'Financial Goal',
      'subtitle': '${apiGoal['description'] ?? 'Active Goal'}',
      'badgeText': badgeText,
      'badgeColor': progressColor,
      'badgeBgColor': progressColor.withOpacity(0.1),
      'saved': saved,
      'target': target,
      'progress': progress,
      'progressColor': progressColor,
      'monthly': monthlyRupees > 0 ? '₹${monthlyRupees.toStringAsFixed(0)}' : '₹0',
      'rightLabel': 'Next: ',
      'rightValue': '10 Jul',
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
                    const SizedBox(height: 12),

                    // Goals cards list
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
            'Goals',
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
            'TOTAL GOAL SAVINGS',
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
              'Add new goal',
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
