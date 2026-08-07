import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'market_pulse_details.dart';
import 'sector_performance_details.dart';
import 'top_movers_details.dart';
import 'simulation.dart';
import 'portfolio_hub.dart';
import 'investing_explained.dart';
import 'bottom_nav_bar.dart' show activeTabNotifier;
import '../main.dart';

class MarketAnalysisScreen extends StatefulWidget {
  const MarketAnalysisScreen({super.key});

  @override
  State<MarketAnalysisScreen> createState() => _MarketAnalysisScreenState();
}

class _MarketAnalysisScreenState extends State<MarketAnalysisScreen> {
  int? _hoveredIndex;

  // Current selected index for chart
  String _selectedIndex = 'SENSEX';
  
  // Current selected timeframe
  String _selectedTimeframe = '1D';

  // Current selected tab in Top Movers
  String _selectedMoversTab = 'Gainers';

  // Available indices
  final List<String> _indices = ['SENSEX', 'NIFTY 50', 'GOLD / 10G', 'REPO RATE'];

  // Map of data per index
  final Map<String, Map<String, dynamic>> _indexData = {
    'SENSEX': {
      'value': '74,243.34',
      'change': '+0.42%',
      'changeAbs': '+305',
      'isPositive': true,
      'color': const Color(0xFF16A34A),
      'open': '74,120',
      'high': '74,450',
      'low': '73,890',
      'prevClose': '74,262',
      'yRange': ['74.5K', '74.2K', '73.9K'],
      'chartPoints': {
        '1D': [0.35, 0.45, 0.25, 0.65, 0.50, 0.85, 0.72],
        '1W': [0.10, 0.30, 0.20, 0.55, 0.70, 0.90, 0.72],
        '1M': [0.25, 0.40, 0.35, 0.50, 0.45, 0.65, 0.72],
        '3M': [0.15, 0.20, 0.30, 0.50, 0.60, 0.80, 0.72],
        '1Y': [0.05, 0.25, 0.40, 0.35, 0.55, 0.75, 0.72],
        '5Y': [0.00, 0.20, 0.35, 0.50, 0.60, 0.80, 0.72],
      }
    },
    'NIFTY 50': {
      'value': '22,104.00',
      'change': '+0.38%',
      'changeAbs': '+84',
      'isPositive': true,
      'color': const Color(0xFF16A34A),
      'open': '22,010',
      'high': '22,180',
      'low': '21,950',
      'prevClose': '22,020',
      'yRange': ['22.2K', '22.0K', '21.8K'],
      'chartPoints': {
        '1D': [0.40, 0.50, 0.35, 0.60, 0.55, 0.80, 0.75],
        '1W': [0.20, 0.40, 0.30, 0.50, 0.65, 0.85, 0.75],
        '1M': [0.30, 0.45, 0.40, 0.55, 0.50, 0.70, 0.75],
        '3M': [0.25, 0.30, 0.40, 0.55, 0.65, 0.80, 0.75],
        '1Y': [0.10, 0.30, 0.45, 0.40, 0.60, 0.78, 0.75],
        '5Y': [0.05, 0.25, 0.40, 0.55, 0.65, 0.82, 0.75],
      }
    },
    'GOLD / 10G': {
      'value': '62,180',
      'change': '-0.21%',
      'changeAbs': '-130',
      'isPositive': false,
      'color': const Color(0xFFDC2626),
      'open': '62,300',
      'high': '62,450',
      'low': '62,050',
      'prevClose': '62,310',
      'yRange': ['62.5K', '62.1K', '61.8K'],
      'chartPoints': {
        '1D': [0.60, 0.55, 0.45, 0.50, 0.40, 0.35, 0.30],
        '1W': [0.80, 0.70, 0.65, 0.50, 0.45, 0.35, 0.30],
        '1M': [0.70, 0.65, 0.55, 0.48, 0.40, 0.38, 0.30],
        '3M': [0.85, 0.80, 0.70, 0.60, 0.50, 0.40, 0.30],
        '1Y': [0.90, 0.75, 0.60, 0.55, 0.45, 0.38, 0.30],
        '5Y': [0.95, 0.80, 0.70, 0.60, 0.50, 0.40, 0.30],
      }
    },
    'REPO RATE': {
      'value': '6.50%',
      'change': 'Hold',
      'changeAbs': '—',
      'isPositive': null,
      'color': const Color(0xFF94A3B8),
      'open': '6.50%',
      'high': '6.50%',
      'low': '6.50%',
      'prevClose': '6.50%',
      'yRange': ['6.6%', '6.5%', '6.4%'],
      'chartPoints': {
        '1D': [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50],
        '1W': [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50],
        '1M': [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50],
        '3M': [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50],
        '1Y': [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50],
        '5Y': [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50],
      }
    }
  };

  @override
  Widget build(BuildContext context) {
    final currentData = _indexData[_selectedIndex]!;
    final chartPoints = currentData['chartPoints'][_selectedTimeframe] as List<double>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Market Overview Card (Hero)
                    _buildOverviewHeroCard(),
                    const SizedBox(height: 16),

                    // Portfolio Impact Strip
                    _buildPortfolioImpactStrip(),
                    const SizedBox(height: 16),

                    // Chart Card
                    _buildChartCard(currentData, chartPoints),
                    const SizedBox(height: 24),

                    // Market Pulse Section
                    _buildMarketPulseSection(),
                    const SizedBox(height: 24),

                    // Sector Performance Section
                    _buildSectorPerformanceSection(),
                    const SizedBox(height: 24),

                    // Top Movers Section
                    _buildTopMoversSection(),
                    const SizedBox(height: 24),

                    // Top AI Insights Section
                    _buildAIInsightsSection(),
                    const SizedBox(height: 24),

                    // Market News Section
                    _buildMarketNewsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom App Bar with back button and Search button
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            tr('Markets'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF001026),
            ),
          ),

          // Search Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFF475569),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // Market Overview Card (Hero)
  Widget _buildOverviewHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2545), // color/azure/16
            Color(0xFF13315C), // color/azure/22
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    tr('MARKET OVERVIEW'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      tr('Live'),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Updated 2m ago',
                style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2x2 Grid of Indexes
          Table(
            children: [
              TableRow(
                children: [
                  _buildIndexStat('SENSEX', '74,243.34', '0.42%', '+305', true),
                  _buildIndexStat('NIFTY 50', '22,104.00', '0.38%', '+84', true),
                ],
              ),
              const TableRow(
                children: [
                  SizedBox(height: 20),
                  SizedBox(height: 20),
                ],
              ),
              TableRow(
                children: [
                  _buildIndexStat('GOLD / 10G', '62,180', '0.21%', '−130', false),
                  _buildIndexStat('REPO RATE', '6.50%', 'Hold', '—', null),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Index Stat Column for Hero Card
  Widget _buildIndexStat(String label, String value, String percent, String absolute, bool? isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        if (isPositive != null)
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 11,
              ),
              const SizedBox(width: 2),
              Text(
                '$percent ($absolute)',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ),
            ],
          )
        else
          Text(
            '— $percent',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  // Portfolio Impact Strip
  Widget _buildPortfolioImpactStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF16A34A),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('YOUR PORTFOLIO TODAY'),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0F172A),
                    ),
                    children: const [
                      TextSpan(text: 'Up '),
                      TextSpan(
                        text: '+₹4,280',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                      ),
                      TextSpan(text: ' across 12 holdings — banking led gains.'),
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

  // Interactive Chart Card
  Widget _buildChartCard(Map<String, dynamic> data, List<double> points) {
    final bool? isPositive = data['isPositive'];
    final Color chartColor = isPositive == true
        ? const Color(0xFF16A34A)
        : (isPositive == false ? const Color(0xFFDC2626) : const Color(0xFF94A3B8));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row with Dropdown & Price
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown Button Selector
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        setState(() {
                          _selectedIndex = value;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return _indices.map((String value) {
                          return PopupMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              _selectedIndex,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF475569),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hoveredIndex != null
                          ? _getValueAtPoint(_selectedIndex, data, _hoveredIndex!, _selectedTimeframe)
                          : data['value'],
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                
                // Translucent Change Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPositive == true
                        ? const Color(0xFFDCFCE7)
                        : (isPositive == false ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isPositive == true
                        ? '↑ ${data['change']}'
                        : (isPositive == false ? '↓ ${data['change']}' : '— Hold'),
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isPositive == true
                          ? const Color(0xFF16A34A)
                          : (isPositive == false ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Time Tabs selector row
          Container(
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: ['1D', '1W', '1M', '3M', '1Y', '5Y'].map((time) {
                final isSel = _selectedTimeframe == time;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeframe = time;
                        _hoveredIndex = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                          color: isSel ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Custom Painted Chart Area
          Container(
            height: 130,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanUpdate: (details) {
                            final double touchX = details.localPosition.dx;
                            final double chartWidth = constraints.maxWidth;
                            final int idx = ((touchX / chartWidth) * (points.length - 1)).round().clamp(0, points.length - 1);
                            setState(() {
                              _hoveredIndex = idx;
                            });
                          },
                          onPanEnd: (details) {
                            setState(() {
                              _hoveredIndex = null;
                            });
                          },
                          onTapDown: (details) {
                            final double touchX = details.localPosition.dx;
                            final double chartWidth = constraints.maxWidth;
                            final int idx = ((touchX / chartWidth) * (points.length - 1)).round().clamp(0, points.length - 1);
                            setState(() {
                              _hoveredIndex = idx;
                            });
                          },
                          onTapUp: (details) {
                            setState(() {
                              _hoveredIndex = null;
                            });
                          },
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: CustomPaint(
                              painter: LineChartPainter(
                                points: points,
                                strokeColor: chartColor,
                                fillColor: chartColor.withOpacity(0.08),
                                hoveredIndex: _hoveredIndex,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Y-Axis Labels
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: (data['yRange'] as List<String>).map((label) {
                      return Text(
                        label,
                        style: GoogleFonts.spaceMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // X-Axis Time Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTimeframe == '1D' ? '09:15' : 'Start',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  _selectedTimeframe == '1D' ? '12:30' : 'Midpoint',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  _selectedTimeframe == '1D' ? '15:30' : 'End',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 40), // alignment offset for Y-axis space
              ],
            ),
          ),

          // OHLC stats grid
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOHLCItem('OPEN', data['open'], null),
                _buildOHLCItem('HIGH', data['high'], const Color(0xFF16A34A)),
                _buildOHLCItem('LOW', data['low'], const Color(0xFFDC2626)),
                _buildOHLCItem('PREV. CL', data['prevClose'], null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // OHLC Item Helper
  Widget _buildOHLCItem(String label, String value, Color? valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // Market Pulse Section
  Widget _buildMarketPulseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Market pulse'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: MarketPulseDetailsScreen(),
                    ),
                  ),
                );
              },
              child: Text(
                tr('Details →'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 2x2 Grid of Market Pulse cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildPulseCard('FII NET', '+₹1,847 Cr', '+0.45%', true, Icons.show_chart_rounded),
            _buildPulseCard('DII NET', '+₹932 Cr', '+0.22%', true, Icons.show_chart_rounded),
            _buildPulseCard('INDIA VIX', '13.42', '↓ 2.30% Volatile', false, Icons.analytics_outlined),
            _buildPulseCard('USD / INR', '83.24', '+0.08%', true, Icons.attach_money_rounded),
          ],
        ),
      ],
    );
  }

  // Pulse Card Helper
  Widget _buildPulseCard(String title, String value, String rate, bool isPositive, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF475569)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.fraunces(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                rate,
                style: GoogleFonts.spaceMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sector Performance Section
  Widget _buildSectorPerformanceSection() {
    final List<Map<String, dynamic>> sectors = [
      {'name': 'Banking', 'change': '+1.24%', 'isPositive': true, 'progress': 0.75},
      {'name': 'IT', 'change': '+0.86%', 'isPositive': true, 'progress': 0.55},
      {'name': 'Pharma', 'change': '-0.34%', 'isPositive': false, 'progress': 0.25},
      {'name': 'Auto', 'change': '+0.52%', 'isPositive': true, 'progress': 0.40},
      {'name': 'FMCG', 'change': '-0.18%', 'isPositive': false, 'progress': 0.15},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Sector performance'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: SectorPerformanceDetailsScreen(),
                    ),
                  ),
                );
              },
              child: Text(
                tr('View all →'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: sectors.map((sector) {
              final color = sector['isPositive'] ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
              final index = sectors.indexOf(sector);
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: index == sectors.length - 1
                    ? null
                    : const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getSectorIcon(sector['name']),
                        size: 15,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Name & Slider
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sector['name'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 5),
                          
                          // Custom horizontal progress indicator
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Container(
                                    height: 4,
                                    width: constraints.maxWidth * sector['progress'],
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Value
                    Text(
                      sector['change'],
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getSectorIcon(String name) {
    switch (name) {
      case 'Banking':
        return Icons.account_balance_rounded;
      case 'IT':
        return Icons.computer_rounded;
      case 'Pharma':
        return Icons.biotech_rounded;
      case 'Auto':
        return Icons.directions_car_filled_rounded;
      default:
        return Icons.shopping_basket_rounded;
    }
  }

  // Top Movers Section
  Widget _buildTopMoversSection() {
    final Map<String, List<Map<String, dynamic>>> moversData = {
      'Gainers': [
        {'symbol': 'HDFCBANK', 'price': '₹1,684.20', 'change': '+2.34%', 'logo': 'HDF'},
        {'symbol': 'TCS', 'price': '₹4,012.85', 'change': '+2.33%', 'logo': 'TCS'},
        {'symbol': 'RELIANCE', 'price': '₹2,948.30', 'change': '+1.87%', 'logo': 'REL'},
        {'symbol': 'INFY', 'price': '₹1,547.90', 'change': '+1.40%', 'logo': 'INF'},
      ],
      'Losers': [
        {'symbol': 'SBIN', 'price': '₹812.50', 'change': '-1.45%', 'logo': 'SBI'},
        {'symbol': 'ICICIBANK', 'price': '₹1,114.30', 'change': '-1.12%', 'logo': 'ICI'},
        {'symbol': 'AXISBANK', 'price': '₹1,048.90', 'change': '-0.95%', 'logo': 'AXI'},
        {'symbol': 'WIPRO', 'price': '₹452.10', 'change': '-0.82%', 'logo': 'WIP'},
      ],
      'Most active': [
        {'symbol': 'TATAMOTORS', 'price': '₹984.60', 'change': '+0.45%', 'logo': 'TAT'},
        {'symbol': 'SBIN', 'price': '₹812.50', 'change': '-1.45%', 'logo': 'SBI'},
        {'symbol': 'RELIANCE', 'price': '₹2,948.30', 'change': '+1.87%', 'logo': 'REL'},
        {'symbol': 'HDFCBANK', 'price': '₹1,684.20', 'change': '+2.34%', 'logo': 'HDF'},
      ],
    };

    final selectedList = moversData[_selectedMoversTab]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Top movers'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: TopMoversDetailsScreen(),
                    ),
                  ),
                );
              },
              child: Text(
                tr('View all →'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Tabs Header row
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: moversData.keys.map((tab) {
                    final isSel = _selectedMoversTab == tab;
                    return Container(
                      margin: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMoversTab = tab;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          decoration: isSel
                              ? const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Color(0xFF2E75B6), width: 2.0),
                                  ),
                                )
                              : null,
                          child: Text(
                            tab,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                              color: isSel ? const Color(0xFF2E75B6) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Stock Rows
              Column(
                children: selectedList.map((stock) {
                  final changeText = stock['change'] as String;
                  final isPositive = changeText.startsWith('+');
                  final color = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
                  final index = selectedList.indexOf(stock);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: index == selectedList.length - 1
                        ? null
                        : const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF4FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                stock['logo'],
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              stock['symbol'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              stock['price'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stock['change'],
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Top AI Insights Section
  Widget _buildAIInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Top AI insights'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              child: Text(
                tr('View all →'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Opportunity Card (Green)
        _buildAIInsightCard(
          title: 'OPPORTUNITY',
          description: 'Banking sector outperforming on Q1 leading growth.',
          meta: 'AI Engine · 10m ago',
          actionText: 'Run simulation →',
          accentColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFE8F5E9),
          icon: Icons.flash_on_rounded,
          onTap: () {
            Navigator.push(
              context,
              SmoothPageRoute(
                settings: const RouteSettings(name: '/simulation'),
                builder: (context) => const MobileDeviceFrame(
                  child: SimulationScreen(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Watch Out Card (Orange)
        _buildAIInsightCard(
          title: 'WATCH OUT',
          description: 'Gold prices softening — possible re-entry window.',
          meta: 'Net financial advice. Market Analyst · 1h ago',
          actionText: 'Read more →',
          accentColor: const Color(0xFFEA580C),
          bgColor: const Color(0xFFFFF7ED),
          icon: Icons.warning_amber_rounded,
          onTap: () {
            Navigator.push(
              context,
              SmoothPageRoute(
                builder: (context) => MobileDeviceFrame(
                  child: InvestingExplainedScreen(
                    onGoalCreated: (_) {},
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Portfolio Card (Blue)
        _buildAIInsightCard(
          title: 'PORTFOLIO',
          description: 'Your bluechip SIP outperformed Nifty by 3.2% YTD.',
          meta: 'Portfolio Analytics · Today',
          actionText: 'View portfolio →',
          accentColor: const Color(0xFF2E75B6),
          bgColor: const Color(0xFFEEF4FA),
          icon: Icons.show_chart_rounded,
          onTap: () {
            // Emulate tab change to Portfolio
            final navState = navigatorKey.currentState;
            if (navState != null) {
              navState.pushAndRemoveUntil(
                PageRouteBuilder(
                  settings: const RouteSettings(name: '/portfolio'),
                  pageBuilder: (context, animation, secondaryAnimation) => const PortfolioHubScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 150),
                ),
                (route) => route.isFirst,
              );
              activeTabNotifier.value = 'portfolio';
            }
          },
        ),
      ],
    );
  }

  // AI Insight Card Helper
  Widget _buildAIInsightCard({
    required String title,
    required String description,
    required String meta,
    required String actionText,
    required Color accentColor,
    required Color bgColor,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Box
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 12),

            // Text & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        actionText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to dynamically interpolate value at hovered chart point
  String _getValueAtPoint(String indexName, Map<String, dynamic> data, int pointIndex, String timeframe) {
    final points = data['chartPoints'][timeframe] as List<double>;
    if (pointIndex < 0 || pointIndex >= points.length) return data['value'];
    final normVal = points[pointIndex];
    final lowStr = data['low'] as String;
    final highStr = data['high'] as String;

    if (indexName == 'REPO RATE') {
      return '6.50%';
    }

    try {
      final double lowVal = double.parse(lowStr.replaceAll(',', '').replaceAll('₹', ''));
      final double highVal = double.parse(highStr.replaceAll(',', '').replaceAll('₹', ''));
      final double val = lowVal + (highVal - lowVal) * normVal;

      if (indexName.contains('GOLD')) {
        return '₹${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      } else {
        return val.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},}');
      }
    } catch (_) {
      return data['value'];
    }
  }

  // Market News Section
  Widget _buildMarketNewsSection() {
    final List<Map<String, String>> news = [
      {
        'title': 'RBI keeps repo rate unchanged at 6.5% for 7th consecutive time',
        'source': 'Mint',
        'time': '18m ago',
      },
      {
        'title': 'PSU banks rally on strong Q4 earnings expectations',
        'source': 'Moneycontrol',
        'time': '45m ago',
      },
      {
        'title': 'FII inflows resume after brief pause, lift benchmark indices',
        'source': 'Economic Times',
        'time': '2h ago',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Market news'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              child: Text(
                tr('All news →'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: news.map((item) {
              final index = news.indexOf(item);
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: index == news.length - 1
                    ? null
                    : const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E75B6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                item['source']!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                ' · ${item['time']!}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Custom Line Chart Painter
// ---------------------------------------------------------------------
class LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color strokeColor;
  final Color fillColor;
  final int? hoveredIndex;

  LineChartPainter({
    required this.points,
    required this.strokeColor,
    required this.fillColor,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    final fillPath = Path();

    final double dx = size.width / (points.length - 1);

    // Start path
    path.moveTo(0, size.height * (1 - points[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1 - points[0]));

    for (int i = 0; i < points.length - 1; i++) {
      final x1 = i * dx;
      final y1 = size.height * (1 - points[i]);
      final x2 = (i + 1) * dx;
      final y2 = size.height * (1 - points[i + 1]);

      // Control points for cubic bezier curves (smooth transition)
      final cx1 = x1 + dx / 2;
      final cy1 = y1;
      final cx2 = x2 - dx / 2;
      final cy2 = y2;

      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
      fillPath.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw background gradient fill, then curved stroke line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Draw interaction crosshair and point if hovered
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < points.length) {
      final double hoveredX = hoveredIndex! * dx;
      final double hoveredY = size.height * (1 - points[hoveredIndex!]);

      // Draw vertical dashed line
      final dashPaint = Paint()
        ..color = strokeColor.withOpacity(0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      double dashHeight = 4.0;
      double dashSpace = 4.0;
      double startY = 0.0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(hoveredX, startY),
          Offset(hoveredX, startY + dashHeight),
          dashPaint,
        );
        startY += dashHeight + dashSpace;
      }

      // Draw highlighted dot (inner and outer circles)
      final dotOuterPaint = Paint()
        ..color = strokeColor.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final dotInnerPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(hoveredX, hoveredY), 6.0, dotOuterPaint);
      canvas.drawCircle(Offset(hoveredX, hoveredY), 3.0, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.hoveredIndex != hoveredIndex;
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
