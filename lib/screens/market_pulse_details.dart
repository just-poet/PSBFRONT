import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

class MarketPulseDetailsScreen extends StatelessWidget {
  const MarketPulseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of market pulse details metrics
    final List<Map<String, dynamic>> metrics = [
      {
        'title': 'FII NET',
        'subtitle': 'Net Buying',
        'value': '+1,452.30',
        'change': '+0.45%',
        'isGreen': true,
        'icon': Icons.account_balance_rounded,
        'iconBg': const Color(0xFFB1C7F0),
        'iconColor': const Color(0xFF0F172A),
        'topOffset': 0.275,
        'bottomOffset': 0.125,
      },
      {
        'title': 'DII NET',
        'subtitle': 'Net Selling',
        'value': '-890.15',
        'change': '-0.21%',
        'isGreen': false,
        'icon': Icons.account_balance_rounded,
        'iconBg': const Color(0xFFFFDAD6),
        'iconColor': const Color(0xFFBA1A1A),
        'topOffset': 0.125,
        'bottomOffset': 0.475,
      },
      {
        'title': 'INDIA VIX',
        'subtitle': '2.10% Calmer',
        'value': '14.85',
        'change': '-2.10%',
        'isGreen': true,
        'icon': Icons.show_chart_rounded,
        'iconBg': const Color(0xFFB1C7F0),
        'iconColor': const Color(0xFF0F172A),
        'topOffset': 0.45,
        'bottomOffset': 0.25,
      },
      {
        'title': 'USD/INR',
        'subtitle': 'Rupee Weaker',
        'value': '83.15',
        'change': '+0.12%',
        'isGreen': false,
        'icon': Icons.currency_rupee_rounded,
        'iconBg': const Color(0xFFFFDAD6),
        'iconColor': const Color(0xFFBA1A1A),
        'topOffset': 0.25,
        'bottomOffset': 0.25,
      },
      {
        'title': 'CRUDE OIL',
        'subtitle': 'Trending Up',
        'value': '78.45',
        'change': '+1.25%',
        'isGreen': true,
        'icon': Icons.oil_barrel_rounded,
        'iconBg': const Color(0xFFB1C7F0),
        'iconColor': const Color(0xFF0F172A),
        'topOffset': 0.175,
        'bottomOffset': 0.125,
      },
      {
        'title': 'GOLD',
        'subtitle': 'Stronger',
        'value': '62,450',
        'change': '+0.85%',
        'isGreen': true,
        'icon': Icons.diamond_outlined,
        'iconBg': const Color(0xFFB1C7F0),
        'iconColor': const Color(0xFF0F172A),
        'topOffset': 0.25,
        'bottomOffset': 0.25,
      },
      {
        'title': 'SILVER',
        'subtitle': 'Marginal Dip',
        'value': '74,210',
        'change': '-0.15%',
        'isGreen': false,
        'icon': Icons.layers_outlined,
        'iconBg': const Color(0xFFFFDAD6),
        'iconColor': const Color(0xFFBA1A1A),
        'topOffset': 0.375,
        'bottomOffset': 0.325,
      },
      {
        'title': '10Y YIELD',
        'subtitle': 'Yielding Higher',
        'value': '7.15%',
        'change': '+0.05%',
        'isGreen': true,
        'icon': Icons.trending_up_rounded,
        'iconBg': const Color(0xFFB1C7F0),
        'iconColor': const Color(0xFF0F172A),
        'topOffset': 0.425,
        'bottomOffset': 0.375,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            _buildAppBar(context),

            // 3. Scrollable List of Metric Cards
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                itemCount: metrics.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final metric = metrics[index];
                  return _buildMetricCard(metric);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom App Bar with back button
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9FC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFC4C6CF), width: 0.5),
        ),
      ),
      child: Row(
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
                border: Border.all(color: const Color(0xFFC4C6CF)),
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
          const SizedBox(width: 59),

          // Title
          Text(
            tr('Market Pulse Details'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF001026),
            ),
          ),
        ],
      ),
    );
  }

  // Metric Card Widget
  Widget _buildMetricCard(Map<String, dynamic> metric) {
    final bool isGreen = metric['isGreen'];
    final solidColor = isGreen ? const Color(0xFF16A34A) : const Color(0xFFBA1A1A);

    return Container(
      padding: const EdgeInsets.all(21.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E2E5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Icon + Label/Subtitle info
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: metric['iconBg'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  metric['icon'],
                  color: metric['iconColor'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric['title'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF44474E),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric['subtitle'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1B1B1E),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Value, rate, and Candlestick indicator
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    metric['value'],
                    style: GoogleFonts.spaceMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: solidColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric['change'],
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: solidColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Custom Candlestick indicator widget
              _CandlestickIndicator(
                isGreen: isGreen,
                topOffset: metric['topOffset'],
                bottomOffset: metric['bottomOffset'],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// High Fidelity Candlestick Indicator Widget
// ---------------------------------------------------------------------
class _CandlestickIndicator extends StatelessWidget {
  final bool isGreen;
  final double topOffset;
  final double bottomOffset;

  const _CandlestickIndicator({
    required this.isGreen,
    required this.topOffset,
    required this.bottomOffset,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = isGreen ? const Color(0xFFDCFCE7) : const Color(0xFFFFDAD6);
    final solidColor = isGreen ? const Color(0xFF16A34A) : const Color(0xFFBA1A1A);

    return Container(
      width: 8,
      height: 32,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Wick (Vertical Line from top to bottom)
          Positioned(
            top: 4,
            bottom: 4,
            child: Container(
              width: 1,
              color: solidColor,
            ),
          ),
          
          // Body (Solid color container representing price movement box)
          Positioned(
            left: 0,
            right: 0,
            top: 32 * topOffset,
            bottom: 32 * bottomOffset,
            child: Container(
              decoration: BoxDecoration(
                color: solidColor,
                borderRadius: BorderRadius.circular(2),
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
