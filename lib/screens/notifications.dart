import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum NotificationFilter { all, security, wealth, transactions }

class NotificationModel {
  final String id;
  final String title;
  final String time;
  final NotificationFilter category;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String section;
  final List<TextSpan> subtitleSpans;

  NotificationModel({
    required this.id,
    required this.title,
    required this.time,
    required this.category,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.section,
    required this.subtitleSpans,
  });
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;

  // Notification items list
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _resetNotifications();
  }

  void _resetNotifications() {
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'Unusual transaction paused',
        time: '2 min ago',
        category: NotificationFilter.security,
        icon: Icons.block_flipped,
        iconBgColor: const Color(0xFFDC2626), // color/red/51
        iconColor: Colors.white,
        section: 'TODAY',
        subtitleSpans: [
          const TextSpan(text: 'We blocked a '),
          const TextSpan(text: '₹85,000 transfer', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B2545))),
          const TextSpan(text: ' to a first-time recipient at 1:47 AM. Review and decide.'),
        ],
      ),
      NotificationModel(
        id: '2',
        title: 'Your Europe Trip goal is ahead',
        time: '1 hr ago',
        category: NotificationFilter.wealth,
        icon: Icons.auto_awesome_outlined,
        iconBgColor: const Color(0xFFEEF4FA),
        iconColor: const Color(0xFF2E75B6),
        section: 'TODAY',
        subtitleSpans: [
          const TextSpan(text: "You're "),
          const TextSpan(text: '8 weeks ahead of schedule', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B2545))),
          const TextSpan(text: '. Consider redirecting ₹2,000/mo to retirement.'),
        ],
      ),
      NotificationModel(
        id: '3',
        title: 'SIP debit successful',
        time: '10:00 AM',
        category: NotificationFilter.transactions,
        icon: Icons.check_rounded,
        iconBgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF16A34A),
        section: 'TODAY',
        subtitleSpans: [
          const TextSpan(text: 'HDFC Bluechip SIP · '),
          const TextSpan(text: '₹5,000', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B2545))),
          const TextSpan(text: ' debited from XXXX 8472. Ref: HDFC8472.'),
        ],
      ),
      NotificationModel(
        id: '4',
        title: 'Goal achieved — Emergency Fund',
        time: '8:14 AM',
        category: NotificationFilter.wealth,
        icon: Icons.workspace_premium_outlined,
        iconBgColor: const Color(0xFFFFF9E6),
        iconColor: const Color(0xFFD97706),
        section: 'TODAY',
        subtitleSpans: [
          const TextSpan(text: "You've completed your "),
          const TextSpan(text: '₹3,00,000 emergency fund', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B2545))),
          const TextSpan(text: '. Congratulations!'),
        ],
      ),
      NotificationModel(
        id: '5',
        title: 'Suspicious SMS detected',
        time: '11:20 PM',
        category: NotificationFilter.security,
        icon: Icons.shield_outlined,
        iconBgColor: const Color(0xFFFFEDD5),
        iconColor: const Color(0xFFEA580C),
        section: 'YESTERDAY',
        subtitleSpans: [
          const TextSpan(text: 'Message from '),
          const TextSpan(text: '+91 98765 43210', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B2545))),
          const TextSpan(text: ' flagged as phishing. We did not let it through.'),
        ],
      ),
      NotificationModel(
        id: '6',
        title: 'SBI account synced',
        time: '4:32 PM',
        category: NotificationFilter.transactions,
        icon: Icons.credit_card_outlined,
        iconBgColor: const Color(0xFFEEF4FA),
        iconColor: const Color(0xFF0B2545),
        section: 'YESTERDAY',
        subtitleSpans: [
          const TextSpan(text: 'Latest balance updated · '),
          const TextSpan(text: '6 new transactions', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B2545))),
          const TextSpan(text: ' imported.'),
        ],
      ),
      NotificationModel(
        id: '7',
        title: 'Your health score increased',
        time: '04 Jun',
        category: NotificationFilter.wealth,
        icon: Icons.trending_up_rounded,
        iconBgColor: const Color(0xFFEEF4FA),
        iconColor: const Color(0xFF2E75B6),
        section: 'EARLIER THIS WEEK',
        subtitleSpans: [
          const TextSpan(text: 'Up by '),
          const TextSpan(text: '24 points', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0B2545))),
          const TextSpan(text: ' this month. Now at 782 / 900 — Excellent.'),
        ],
      ),
    ];
  }

  void _clearNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  // Filter notification items
  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == NotificationFilter.all) {
      return _notifications;
    }
    return _notifications.where((n) => n.category == _selectedFilter).toList();
  }

  // Count items matching a filter
  int _getCount(NotificationFilter filter) {
    if (filter == NotificationFilter.all) {
      return _notifications.length;
    }
    return _notifications.where((n) => n.category == filter).length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredNotifications;

    // Group filtered notifications by section
    final Map<String, List<NotificationModel>> groupedList = {};
    for (var n in filteredList) {
      groupedList.putIfAbsent(n.section, () => []).add(n);
    }

    // Maintain specific section order
    const orderedSections = ['TODAY', 'YESTERDAY', 'EARLIER THIS WEEK'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            _buildAppBar(context),

            // 3. Horizontal Filters Row
            if (_notifications.isNotEmpty) _buildFiltersRow(),

            // 4. Notifications List / Empty State
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var section in orderedSections)
                            if (groupedList.containsKey(section) && groupedList[section]!.isNotEmpty) ...[
                              _buildSectionHeader(section),
                              const SizedBox(height: 8),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: groupedList[section]!.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = groupedList[section]![index];
                                  return _buildNotificationCard(item);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom App Bar with back button and "Clear" text button
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF475569),
                size: 20,
              ),
            ),
          ),
          
          // Title
          Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628), // color/text/ink
            ),
          ),

          // Clear Button
          if (_notifications.isNotEmpty)
            GestureDetector(
              onTap: _clearNotifications,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 11.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E75B6), // color/brand/action
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 38), // Keep alignment
        ],
      ),
    );
  }

  // Filters Row Helper
  Widget _buildFiltersRow() {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        children: [
          _buildFilterPill(NotificationFilter.all, 'All'),
          const SizedBox(width: 8),
          _buildFilterPill(NotificationFilter.security, 'Security'),
          const SizedBox(width: 8),
          _buildFilterPill(NotificationFilter.wealth, 'Wealth'),
          const SizedBox(width: 8),
          _buildFilterPill(NotificationFilter.transactions, 'Transactions'),
        ],
      ),
    );
  }

  // Filter Pill Button Widget
  Widget _buildFilterPill(NotificationFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    final count = _getCount(filter);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B2545) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFF0B2545) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label · $count',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // Section Header Helper
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 12.0, bottom: 6.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8), // color/text/mist
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // Reusable Notification Card Widget
  Widget _buildNotificationCard(NotificationModel item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.iconBgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              item.icon,
              color: item.iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          
          // Notification Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1628), // color/text/ink
                  ),
                ),
                const SizedBox(height: 3.2),
                
                // Rich Subtitle Text
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569), // color/text/slate
                      height: 1.45,
                    ),
                    children: item.subtitleSpans,
                  ),
                ),
                const SizedBox(height: 4.8),

                // Time / Date Text
                Text(
                  item.time,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8), // color/text/mist
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Empty State Widget when notifications are cleared
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEEF4FA),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFF94A3B8),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All caught up!',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No new notifications for you right now.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resetNotifications();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2545),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Reset Notifications',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
