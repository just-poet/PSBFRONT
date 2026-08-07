import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Populated from /v1/transactions/history. This was a hardcoded list, so
  // every customer saw the same "Rohan Sharma / Starbucks / Salary Credit"
  // history regardless of who signed in.
  List<Map<String, dynamic>> _allTransactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Re-read whenever the customer changes something anywhere in the app.
    // Without this the screen kept whatever it loaded on first build, so a
    // payment made elsewhere left stale figures here.
    ApiService.instance.dataVersion.addListener(_onDataChanged);
    _load();
  }

  void _onDataChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final txns = await ApiService.instance.getTransactionHistory();
    if (!mounted) return;
    setState(() {
      _allTransactions = txns.map(_toRow).toList();
      _loading = false;
    });
  }

  /// Maps an API transaction onto the row shape this screen renders.
  Map<String, dynamic> _toRow(Map<String, dynamic> t) {
    final isCredit = (t['type'] ?? 'debit') == 'credit';
    final paise = (t['amountPaise'] as num?)?.toInt() ?? 0;
    final when = DateTime.tryParse((t['timestamp'] ?? '').toString())?.toLocal();
    final title = (t['merchantName'] ?? t['recipient'] ?? 'Transaction').toString();

    return {
      'title': title,
      'dateGroup': _groupFor(when),
      'subtitle': '${_clockTime(when)} · ${_channel(t)}',
      'amount': '${isCredit ? '+' : '−'}₹${_money(paise / 100)}',
      'type': isCredit ? 'credit' : 'debit',
      'initials': _initials(title),
      'icon': null,
      if (isCredit) 'iconBg': const Color(0xFFDCFCE7),
      if (isCredit) 'iconColor': const Color(0xFF16A34A),
    };
  }

  /// The screen renders three buckets; anything older falls into "Last Week"
  /// so it stays visible rather than being silently dropped.
  static String _groupFor(DateTime? when) {
    if (when == null) return 'Last Week';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return 'Last Week';
  }

  static String _clockTime(DateTime? when) {
    if (when == null) return '--';
    final h24 = when.hour;
    final h = h24 % 12 == 0 ? 12 : h24 % 12;
    final m = when.minute.toString().padLeft(2, '0');
    return '$h:$m ${h24 < 12 ? 'AM' : 'PM'}';
  }

  static String _channel(Map<String, dynamic> t) {
    final c = (t['channel'] ?? '').toString();
    if (c.isEmpty) return 'Transfer';
    return c.toUpperCase() == c ? c : c.toUpperCase();
  }

  static String _initials(String name) {
    final parts = name
        .replaceAll(RegExp(r'[@._]'), ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  /// Indian digit grouping.
  static String _money(double rupees) {
    final n = rupees.round().abs().toString();
    if (n.length <= 3) return n;
    final last3 = n.substring(n.length - 3);
    var rest = n.substring(0, n.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$last3';
  }

  @override
  void dispose() {
    ApiService.instance.dataVersion.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter transactions statefully
    final filtered = _allTransactions.where((tx) {
      final title = tx['title'].toString().toLowerCase();
      final subtitle = tx['subtitle'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || subtitle.contains(query);
    }).toList();

    // Group filtered items by date group
    final List<String> groups = ['Today', 'Yesterday', 'Last Week'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            _buildAppBar(context),

            // 3. Search input
            _buildSearchBar(),

            // 4. Scrollable List Grouped
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      children: groups.map((group) {
                        final groupItems = filtered.where((tx) => tx['dateGroup'] == group).toList();
                        if (groupItems.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Group Header
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                              child: Text(
                                group,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A1628),
                                ),
                              ),
                            ),

                            // Transactions in this group
                            Column(
                              children: groupItems.map((tx) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildTransactionRow(tx),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom App Bar
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Title
          Text(
            tr('Transaction History'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D1C2E),
              letterSpacing: -0.2,
            ),
          ),

          // Back Button on left
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B2545).withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF475569),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Search input
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC6C6CD)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF1B1B1E),
          ),
          decoration: InputDecoration(
            hintText: 'Search transactions',
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
          ),
        ),
      ),
    );
  }

  // Row Item Widget
  Widget _buildTransactionRow(Map<String, dynamic> tx) {
    // Decide text colors based on types
    Color amountColor;
    if (tx['type'] == 'credit') {
      amountColor = const Color(0xFF16A34A); // Green
    } else if (tx['type'] == 'stock') {
      amountColor = const Color(0xFFDC2626); // Red Dip
    } else {
      amountColor = const Color(0xFF13315C); // Standard Debit
    }

    // Avatar icon widget
    Widget avatarWidget;
    if (tx['initials'] != null) {
      avatarWidget = Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            tx['initials'],
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D1C2E),
            ),
          ),
        ),
      );
    } else {
      avatarWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tx['iconBg'] ?? const Color(0xFFF8FAFC),
          shape: BoxShape.circle,
        ),
        child: Icon(
          tx['icon'],
          color: tx['iconColor'] ?? const Color(0xFF0D1C2E),
          size: 20,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(13.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC6C6CD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Avatar & Description
          Expanded(
            child: Row(
              children: [
                avatarWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipients can be long -- "Account 4521 (IFSC
                      // SBIN0000000)" -- and without a line limit the text
                      // overflowed its box and painted over the amount on the
                      // right. Ellipsis keeps each row to two tidy lines.
                      Text(
                        tx['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0D1C2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx['subtitle'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF45464D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right Side: Amount. Scales down rather than wrapping, so a large
          // figure stays on one line and never collides with the description.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                tx['amount'],
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty Search State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              tr('No Transactions Found'),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D1C2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any transactions matching "$_searchQuery". Try typing another query.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
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
