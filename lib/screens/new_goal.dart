import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

class NewGoalScreen extends StatefulWidget {
  final Function(Map<String, dynamic> newGoal) onGoalCreated;
  const NewGoalScreen({super.key, required this.onGoalCreated});

  @override
  State<NewGoalScreen> createState() => _NewGoalScreenState();
}

class _NewGoalScreenState extends State<NewGoalScreen> {
  final TextEditingController _nameController = TextEditingController(text: tr('Europe Trip'));
  final TextEditingController _amountController = TextEditingController(text: '480000');

  String _selectedCategory = 'Travel';
  DateTime _selectedDate = DateTime(2027, 8); // August 2027

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Travel', 'icon': Icons.airplanemode_active_rounded},
    {'name': 'Home', 'icon': Icons.home_rounded},
    {'name': 'Education', 'icon': Icons.school_rounded},
    {'name': 'Emergency', 'icon': Icons.security_rounded},
    {'name': 'Retirement', 'icon': Icons.trending_up_rounded},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      helpText: 'Select Target Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B2545),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0A1628),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month);
      });
    }
  }

  String _formatMonthYear(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _submitGoal() {
    final String title = _nameController.text.trim();
    final double target = double.tryParse(_amountController.text) ?? 100000.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Please enter a goal name.')),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Determine custom colors & icon based on category
    IconData icon = Icons.stars_rounded;
    Color iconColor = const Color(0xFF2E75B6);
    Color iconBgColor = const Color(0xFFEEF4FA);

    if (_selectedCategory == 'Home') {
      icon = Icons.home_rounded;
    } else if (_selectedCategory == 'Education') {
      icon = Icons.school_rounded;
    } else if (_selectedCategory == 'Emergency') {
      icon = Icons.security_rounded;
    } else if (_selectedCategory == 'Retirement') {
      icon = Icons.trending_up_rounded;
    } else if (_selectedCategory == 'Travel') {
      icon = Icons.airplanemode_active_rounded;
    }

    final String targetDateStr = _formatMonthYear(_selectedDate);
    final int monthsRemaining = _selectedDate.difference(DateTime.now()).inDays ~/ 30;
    final double monthlyDeposit = target / (monthsRemaining > 0 ? monthsRemaining : 1);

    widget.onGoalCreated({
      'title': title,
      'subtitle': '$targetDateStr · $monthsRemaining months to go',
      'badgeText': 'ON TRACK',
      'badgeColor': const Color(0xFF16A34A),
      'badgeBgColor': const Color(0xFF16A34A).withOpacity(0.1),
      'saved': 0.0,
      'target': target,
      'progress': 0.0,
      'progressColor': const Color(0xFF16A34A),
      'monthly': '₹${_formatCurrency(monthlyDeposit)}',
      'rightLabel': 'Next: ',
      'rightValue': '01 ${_formatNextMonth()}',
      'icon': icon,
      'iconBgColor': iconBgColor,
      'iconColor': iconColor,
      'isCompleted': false,
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Goal "$title" created successfully!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  String _formatNextMonth() {
    final nextMonth = DateTime.now().add(const Duration(days: 30));
    final monthsAbbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthsAbbr[nextMonth.month - 1];
  }

  String _formatCurrency(double amount) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar (Figma node 640:3725)
            _buildAppBar(context),

            // Scrollable Content Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // Headings (Figma node 640:3732)
                    Text(
                      "Let's build something\nto look forward to.",
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0B2545),
                        height: 1.2,
                        letterSpacing: -0.48,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pick a category, set a target. We'll suggest a realistic monthly contribution.",
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Category Title (Figma node 640:3735)
                    Text(
                      tr('CATEGORY'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.66,
                      ),
                    ),
                    const SizedBox(height: 11),

                    // Horizontal list of pills (Figma node 640:3736)
                    _buildCategoryPills(),
                    const SizedBox(height: 24),

                    // Goal Name Title (Figma node 640:3760)
                    Text(
                      tr('GOAL NAME'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.66,
                      ),
                    ),
                    const SizedBox(height: 11),

                    // Input Field Goal Name (Figma node 640:3761)
                    _buildGoalNameField(),
                    const SizedBox(height: 24),

                    // Target Amount Title (Figma node 640:3763)
                    Text(
                      tr('TARGET AMOUNT'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.66,
                      ),
                    ),
                    const SizedBox(height: 11),

                    // Target Amount input field (Figma node 640:3764)
                    _buildTargetAmountField(),
                    const SizedBox(height: 24),

                    // By When Title (Figma node 640:3767)
                    Text(
                      tr('BY WHEN'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.66,
                      ),
                    ),
                    const SizedBox(height: 11),

                    // By when date selector container (Figma node 640:3768)
                    _buildDateSelectorField(context),
                    const SizedBox(height: 48),

                    // Create Goal primary button (Figma node 640:3775)
                    GestureDetector(
                      onTap: _submitGoal,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2545),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            tr('Create goal'),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.16,
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left back arrow
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
          // Center title
          Text(
            tr('New Goal'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          // Spacer
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 37,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final bool isActive = _selectedCategory == cat['name'];

          final pillBgColor = isActive ? const Color(0xFFEEF4FA) : Colors.white;
          final pillBorderColor = isActive ? const Color(0xFF2E75B6) : const Color(0xFFE2E8F0);
          final pillTextColor = isActive ? const Color(0xFF2E75B6) : const Color(0xFF475569);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['name']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: pillBgColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: pillBorderColor, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'],
                    color: pillTextColor,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['name'],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pillTextColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalNameField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E75B6), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E75B6).withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _nameController,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0A1628),
          ),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 17),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetAmountField() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '₹',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF0B2545),
                letterSpacing: -0.26,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectorField(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              _formatMonthYear(_selectedDate),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A1628),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
