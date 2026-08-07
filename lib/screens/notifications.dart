import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';

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
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  /// Whether the OS will let us put anything on the status bar.
  bool _pushAllowed = true;

  /// IDs already seen, so returning to this screen does not re-notify for
  /// everything in the feed.
  static final Set<String> _alreadyNotified = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
    _checkPushPermission();
  }

  Future<void> _checkPushPermission() async {
    final granted = await FinixNotifications.instance.hasPermission();
    if (!mounted) return;
    setState(() => _pushAllowed = granted);
  }

  Future<void> _enablePush() async {
    final granted = await FinixNotifications.instance.requestPermission();
    if (!mounted) return;
    setState(() => _pushAllowed = granted);
    if (granted) {
      await FinixNotifications.instance.show(
        title: 'Notifications on',
        body: 'FINIX will alert you about payments and security events.',
      );
    }
  }

  /// Raises a system notification for anything that arrived since last time.
  ///
  /// Only security and transaction notices interrupt; goal milestones and
  /// insights are not worth a buzz.
  Future<void> _pushNewArrivals(List<Map<String, dynamic>> items) async {
    if (!_pushAllowed) return;
    for (final n in items.take(5)) {
      final id = (n['id'] ?? '').toString();
      if (id.isEmpty || _alreadyNotified.contains(id)) continue;
      _alreadyNotified.add(id);

      final category = (n['category'] ?? '').toString();
      if (category != 'security' && category != 'transactions') continue;

      await FinixNotifications.instance.show(
        title: (n['title'] ?? '').toString(),
        body: (n['body'] ?? '').toString(),
        security: category == 'security',
      );
    }
  }

  /// Notifications come from /v1/notifications, which the backend derives from
  /// this customer's own activity: settled payments, security events off the
  /// audit trail, goal milestones actually reached and premiums falling due.
  ///
  /// The screen used to hold a fixed list — an "unusual transaction paused", a
  /// "₹85,000 transfer", a "₹3,00,000 emergency fund" — shown to every account
  /// including brand-new ones that had done nothing at all.
  Future<void> _load() async {
    final items = await ApiService.instance.getNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = items.map(_toModel).toList();
      _loading = false;
    });
    await _pushNewArrivals(items);
  }

  NotificationModel _toModel(Map<String, dynamic> n) {
    final category = (n['category'] ?? '').toString();
    final severity = (n['severity'] ?? 'info').toString();
    final at = DateTime.tryParse((n['createdAt'] ?? '').toString())?.toLocal();
    final style = _styleFor(category, severity);

    return NotificationModel(
      id: (n['id'] ?? '').toString(),
      title: (n['title'] ?? '').toString(),
      time: _relative(at),
      category: _filterFor(category),
      icon: style.icon,
      iconBgColor: style.colour,
      iconColor: Colors.white,
      section: _section(at),
      subtitleSpans: [TextSpan(text: (n['body'] ?? '').toString())],
    );
  }

  /// The backend's categories are finer-grained than this screen's four tabs.
  static NotificationFilter _filterFor(String category) {
    switch (category) {
      case 'security':
        return NotificationFilter.security;
      case 'transactions':
        return NotificationFilter.transactions;
      case 'goals':
      case 'insights':
      case 'tax':
        return NotificationFilter.wealth;
      default:
        return NotificationFilter.all;
    }
  }

  static ({IconData icon, Color colour}) _styleFor(String category, String severity) {
    if (severity == 'critical') {
      return (icon: Icons.block_flipped, colour: const Color(0xFFDC2626));
    }
    if (severity == 'warning') {
      return (icon: Icons.warning_amber_rounded, colour: const Color(0xFFF59E0B));
    }
    switch (category) {
      case 'security':
        return (icon: Icons.shield_outlined, colour: const Color(0xFF2E75B6));
      case 'transactions':
        return (icon: Icons.swap_horiz_rounded, colour: const Color(0xFF16A34A));
      case 'goals':
        return (icon: Icons.flag_outlined, colour: const Color(0xFFC8A951));
      default:
        return (icon: Icons.info_outline_rounded, colour: const Color(0xFF2E75B6));
    }
  }

  static String _relative(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.isNegative) return 'Scheduled';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${at.day}/${at.month}/${at.year}';
  }

  static String _section(DateTime? at) {
    if (at == null) return 'EARLIER';
    final now = DateTime.now();
    final date = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff <= 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return 'EARLIER';
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
            if (!_pushAllowed) _buildPushPrompt(),
            if (_notifications.isNotEmpty) _buildFiltersRow(),

            // 4. Notifications List / Empty State
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
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
            tr('Notifications'),
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
                    tr('Clear'),
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
  /// Offers to turn on system notifications. Shown only while they are off.
  Widget _buildPushPrompt() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E75B6).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              size: 18, color: Color(0xFF2E75B6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Get alerts on your phone for payments and security events.'),
              style: GoogleFonts.inter(
                fontSize: 11.5,
                height: 1.4,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          TextButton(
            onPressed: _enablePush,
            child: Text(
              tr('Turn on'),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E75B6),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            tr('All caught up!'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('No new notifications for you right now.'),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _loading = true);
              _load();
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
              tr('Reset Notifications'),
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
