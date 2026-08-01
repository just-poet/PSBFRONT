import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // All transaction model items
  final List<Map<String, dynamic>> _allTransactions = [
    {
      'title': 'Rohan Sharma',
      'dateGroup': 'Today',
      'subtitle': '2:14 PM · UPI',
      'amount': '−₹2,400',
      'type': 'debit',
      'initials': 'RS',
      'icon': null,
    },
    {
      'title': 'HDFC Bluechip SIP',
      'dateGroup': 'Today',
      'subtitle': '10:00 AM · Auto SIP',
      'amount': '−₹5,000',
      'type': 'debit',
      'initials': null,
      'icon': Icons.attach_money_rounded,
      'iconBg': const Color(0xFF0B2447),
      'iconColor': Colors.white,
    },
    {
      'title': 'Starbucks',
      'dateGroup': 'Today',
      'subtitle': '9:30 AM · Credit Card',
      'amount': '−₹450',
      'type': 'debit',
      'initials': null,
      'icon': Icons.local_cafe_rounded,
    },
    {
      'title': 'Salary Credit',
      'dateGroup': 'Yesterday',
      'subtitle': '12:01 AM · NEFT',
      'amount': '+₹85,000',
      'type': 'credit',
      'initials': null,
      'icon': Icons.arrow_upward_rounded,
      'iconBg': const Color(0xFFDCFCE7),
      'iconColor': const Color(0xFF16A34A),
    },
    {
      'title': 'Amazon.in',
      'dateGroup': 'Yesterday',
      'subtitle': '11:45 AM · Credit Card',
      'amount': '−₹1,250',
      'type': 'debit',
      'initials': null,
      'icon': Icons.shopping_cart_rounded,
    },
    {
      'title': 'Swiggy',
      'dateGroup': 'Yesterday',
      'subtitle': '8:15 PM · UPI',
      'amount': '−₹620',
      'type': 'debit',
      'initials': null,
      'icon': Icons.restaurant_rounded,
    },
    {
      'title': 'BYJU’s stock',
      'dateGroup': 'Yesterday',
      'subtitle': '6:30 PM · UPI',
      'amount': '−₹340',
      'type': 'stock',
      'initials': null,
      'icon': Icons.trending_down_rounded,
      'iconBg': const Color(0xFFFFDAD6),
      'iconColor': const Color(0xFFDC2626),
    },
    {
      'title': 'Netflix',
      'dateGroup': 'Last Week',
      'subtitle': 'May 14 · Credit Card',
      'amount': '−₹649',
      'type': 'debit',
      'initials': 'NF',
      'icon': null,
    },
    {
      'title': 'Jio Recharge',
      'dateGroup': 'Last Week',
      'subtitle': 'May 12 · UPI',
      'amount': '−₹749',
      'type': 'debit',
      'initials': null,
      'icon': Icons.phone_android_rounded,
    },
    {
      'title': 'ATM Withdrawal',
      'dateGroup': 'Last Week',
      'subtitle': 'May 10 · Debit Card',
      'amount': '−₹10,000',
      'type': 'debit',
      'initials': null,
      'icon': Icons.local_atm_rounded,
    },
    {
      'title': 'D-Mart',
      'dateGroup': 'Last Week',
      'subtitle': 'May 09 · Credit Card',
      'amount': '−₹4,200',
      'type': 'debit',
      'initials': null,
      'icon': Icons.shopping_bag_outlined,
    },
  ];

  @override
  void dispose() {
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
              child: filtered.isEmpty
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
            'Transaction History',
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
                      Text(
                        tx['title'],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0D1C2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx['subtitle'],
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

          // Right Side: Amount
          Text(
            tx['amount'],
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: amountColor,
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
              'No Transactions Found',
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
