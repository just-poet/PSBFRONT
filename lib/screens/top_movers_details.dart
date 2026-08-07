import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

class TopMoversDetailsScreen extends StatefulWidget {
  const TopMoversDetailsScreen({super.key});

  @override
  State<TopMoversDetailsScreen> createState() => _TopMoversDetailsScreenState();
}

class _TopMoversDetailsScreenState extends State<TopMoversDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _gainers = [
    {
      'symbol': 'TATA MOTORS',
      'sector': 'Auto',
      'price': '₹1,024.50',
      'change24h': '+4.2%',
      'change1w': '+8.5%',
      'isPositive': true,
    },
    {
      'symbol': 'HDFC BANK',
      'sector': 'Financial',
      'price': '₹1,645.20',
      'change24h': '+3.1%',
      'change1w': '+5.2%',
      'isPositive': true,
    },
    {
      'symbol': 'RELIANCE',
      'sector': 'Energy',
      'price': '₹2,950.00',
      'change24h': '+2.8%',
      'change1w': '+4.1%',
      'isPositive': true,
    },
  ];

  final List<Map<String, dynamic>> _losers = [
    {
      'symbol': 'INFY',
      'sector': 'IT',
      'price': '₹1,420.75',
      'change24h': '-2.5%',
      'change1w': '-4.0%',
      'isPositive': false,
    },
    {
      'symbol': 'WIPRO',
      'sector': 'IT',
      'price': '₹485.10',
      'change24h': '-1.8%',
      'change1w': '-3.2%',
      'isPositive': false,
    },
    {
      'symbol': 'TCS',
      'sector': 'IT',
      'price': '₹3,850.00',
      'change24h': '-1.2%',
      'change1w': '-2.1%',
      'isPositive': false,
    },
  ];

  final List<Map<String, dynamic>> _active = [
    {
      'symbol': 'ITC',
      'sector': 'FMCG',
      'volume': '12.5M',
      'price': '₹430.25',
      'change': '+0.5%',
      'isPositive': true,
    },
    {
      'symbol': 'SBIN',
      'sector': 'Banking',
      'volume': '8.2M',
      'price': '₹750.80',
      'change': '-0.2%',
      'isPositive': false,
    },
    {
      'symbol': 'ZOMATO',
      'sector': 'Food Tech',
      'volume': '25.4M',
      'price': '₹165.40',
      'change': '+5.6%',
      'isPositive': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase().trim();

    final filteredGainers = _gainers.where((stock) {
      return stock['symbol'].toLowerCase().contains(q) ||
          stock['sector'].toLowerCase().contains(q);
    }).toList();

    final filteredLosers = _losers.where((stock) {
      return stock['symbol'].toLowerCase().contains(q) ||
          stock['sector'].toLowerCase().contains(q);
    }).toList();

    final filteredActive = _active.where((stock) {
      return stock['symbol'].toLowerCase().contains(q) ||
          stock['sector'].toLowerCase().contains(q);
    }).toList();

    final bool hasResults = filteredGainers.isNotEmpty ||
        filteredLosers.isNotEmpty ||
        filteredActive.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            _buildAppBar(context),

            // 3. Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section
                    Text(
                      tr('Market Movers'),
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF001026),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time snapshot of the most significant price action across sectors.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF44474E),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!hasResults)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: Text(
                            'No stocks match your query "$_searchQuery".',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF44474E),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (filteredGainers.isNotEmpty) ...[
                        _buildSectionCard(
                          title: 'Gainers',
                          icon: Icons.trending_up_rounded,
                          iconColor: const Color(0xFF16A34A),
                          stocks: filteredGainers,
                          isMoversTable: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (filteredLosers.isNotEmpty) ...[
                        _buildSectionCard(
                          title: 'Losers',
                          icon: Icons.trending_down_rounded,
                          iconColor: const Color(0xFFBA1A1A),
                          stocks: filteredLosers,
                          isMoversTable: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (filteredActive.isNotEmpty) ...[
                        _buildSectionCard(
                          title: 'Most Active',
                          icon: Icons.whatshot_rounded,
                          iconColor: const Color(0xFF2E75B6),
                          stocks: filteredActive,
                          isMoversTable: false,
                        ),
                      ],
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9FC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFC4C6CF), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF001026),
                size: 20,
              ),
            ),
          ),

          // Title or TextField
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF001026),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search symbol or sector...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF74777F),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    )
                  : Center(
                      child: Text(
                        tr('Top Movers'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF001026),
                        ),
                      ),
                    ),
            ),
          ),

          // Search / Close Icon
          GestureDetector(
            onTap: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: const Color(0xFF001026),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> stocks,
    required bool isMoversTable,
  }) {
    return Container(
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF001026),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E7EB),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  stocks.length.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B1B1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Divider(
            color: Color(0xFFE3E2E5),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  tr('SYMBOL'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF44474E),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  isMoversTable ? 'PRICE' : 'VOL',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF44474E),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  isMoversTable ? '24H / 1W' : 'PRICE',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF44474E),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Column(
            children: List.generate(stocks.length, (index) {
              final stock = stocks[index];
              final isLast = index == stocks.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0xFFC4C6CF), width: 0.5),
                        ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock['symbol'],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF001026),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stock['sector'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF44474E),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: isMoversTable
                          ? Text(
                              stock['price'],
                              textAlign: TextAlign.right,
                              style: GoogleFonts.spaceMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1B1B1E),
                              ),
                            )
                          : Text(
                              stock['volume'],
                              textAlign: TextAlign.right,
                              style: GoogleFonts.spaceMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF445F8C),
                              ),
                            ),
                    ),
                    Expanded(
                      flex: 3,
                      child: isMoversTable
                          ? _buildMoversRates(stock)
                          : _buildActiveRates(stock),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMoversRates(Map<String, dynamic> stock) {
    final bool isPositive = stock['isPositive'];
    final pillBgColor = isPositive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final pillTextColor = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: pillBgColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            stock['change24h'],
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: pillTextColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stock['change1w'],
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF44474E),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRates(Map<String, dynamic> stock) {
    final bool isPositive = stock['isPositive'];
    final textColor = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          stock['price'],
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1B1B1E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stock['change'],
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
