import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SectorPerformanceDetailsScreen extends StatefulWidget {
  const SectorPerformanceDetailsScreen({super.key});

  @override
  State<SectorPerformanceDetailsScreen> createState() => _SectorPerformanceDetailsScreenState();
}

class _SectorPerformanceDetailsScreenState extends State<SectorPerformanceDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _sectors = [
    {
      'name': 'Banking',
      'subtitle': 'FINANCIALS',
      'change': '+2.45%',
      'isPositive': true,
      'progress': 0.75,
      'isRightAligned': false,
      'icon': Icons.account_balance_rounded,
      'insight': 'Lending growth outlook remains bullish for Q2 amidst stable repo rates.',
    },
    {
      'name': 'IT',
      'subtitle': 'TECHNOLOGY',
      'change': '-1.12%',
      'isPositive': false,
      'progress': 0.25,
      'isRightAligned': true,
      'icon': Icons.laptop_mac_rounded,
      'insight': 'Global tech spending deceleration impacting near-term revenue visibility.',
    },
    {
      'name': 'Pharma',
      'subtitle': 'HEALTHCARE',
      'change': '+0.85%',
      'isPositive': true,
      'progress': 0.50,
      'isRightAligned': false,
      'icon': Icons.medication_rounded,
      'insight': 'Strong export numbers expected; domestic demand remains resilient.',
    },
    {
      'name': 'Auto',
      'subtitle': 'AUTOMOBILE',
      'change': '+3.10%',
      'isPositive': true,
      'progress': 0.85,
      'isRightAligned': false,
      'icon': Icons.directions_car_rounded,
      'insight': 'EV adoption accelerating; rural demand shows strong signs of recovery.',
    },
    {
      'name': 'FMCG',
      'subtitle': 'CONSUMER GOODS',
      'change': '0.00%',
      'isPositive': null, // Neutral
      'progress': 0.50,
      'isRightAligned': false,
      'icon': Icons.shopping_basket_rounded,
      'insight': 'Raw material cost pressures stabilizing; volume growth muted.',
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
    final filteredSectors = _sectors.where((sector) {
      return sector['name'].toLowerCase().contains(q) ||
          sector['subtitle'].toLowerCase().contains(q) ||
          sector['insight'].toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            _buildAppBar(context),

            // 3. Scrollable List of Sector Cards
            Expanded(
              child: filteredSectors.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Text(
                          'No sectors match your query "$_searchQuery".',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF44474E),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                      itemCount: filteredSectors.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final sector = filteredSectors[index];
                        return _buildSectorCard(sector);
                      },
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
              width: 40,
              height: 40,
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
                        hintText: 'Search sector or performance...',
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
                        tr('Sector Performance'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF001026),
                        ),
                      ),
                    ),
            ),
          ),

          // Search / Close Button
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
              width: 40,
              height: 40,
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

  Widget _buildSectorCard(Map<String, dynamic> sector) {
    final bool? isPositive = sector['isPositive'];
    final bool isRightAligned = sector['isRightAligned'];
    final double progress = sector['progress'];

    Color valueColor;
    IconData trendIcon;
    Color barColor;

    if (isPositive == true) {
      valueColor = const Color(0xFF16A34A);
      trendIcon = Icons.arrow_upward_rounded;
      barColor = const Color(0xFF001026);
    } else if (isPositive == false) {
      valueColor = const Color(0xFFBA1A1A);
      trendIcon = Icons.arrow_downward_rounded;
      barColor = const Color(0xFFBA1A1A);
    } else {
      valueColor = const Color(0xFF74777F);
      trendIcon = Icons.remove_rounded;
      barColor = const Color(0xFF74777F);
    }

    return Container(
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC4C6CF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFAFCAFE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      sector['icon'],
                      color: const Color(0xFF001026),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sector['name'],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF001026),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sector['subtitle'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF44474E),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    trendIcon,
                    color: valueColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sector['change'],
                    style: GoogleFonts.spaceMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectorProgressBar(
            value: progress,
            fillColor: barColor,
            isRightAligned: isRightAligned,
          ),
          const SizedBox(height: 12),
          const Divider(
            color: Color(0xFFC4C6CF),
            height: 1,
            thickness: 0.5,
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF44474E),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sector['insight'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF44474E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectorProgressBar extends StatelessWidget {
  final double value;
  final Color fillColor;
  final bool isRightAligned;

  const _SectorProgressBar({
    required this.value,
    required this.fillColor,
    required this.isRightAligned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE3E2E5),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: FractionallySizedBox(
        widthFactor: value,
        alignment: isRightAligned ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
      ),
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
