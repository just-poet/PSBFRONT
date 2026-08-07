import 'package:flutter/material.dart';

import '../services/api_service.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'simulation_success.dart';
import 'smooth_route.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  String _selectedTry = 'Increase SIP'; // 'Increase SIP', 'Home loan', 'Job loss', 'Custom'
  double _extraAmount = 5000.0; // ₹1,000 to ₹15,000
  int _years = 12; // 5, 12, 20

  bool _isSaved = false;

  // Format number to Indian format (e.g., 62,40,000)
  String _formatIndianCurrency(int number) {
    String numStr = number.toString();
    if (numStr.length <= 3) return numStr;
    
    String lastThree = numStr.substring(numStr.length - 3);
    String remaining = numStr.substring(0, numStr.length - 3);
    
    List<String> chunks = [];
    while (remaining.length > 2) {
      chunks.add(remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      chunks.add(remaining);
    }
    
    return '${chunks.reversed.join(",")},$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic simulation calculations
    // Baseline is ₹48,20,000
    const int baselineCorpus = 4820000;
    
    // Growth factor representing compound returns (approx. 11% p.a. equity return)
    // E.g., over 12 years: ~1.97x total deposits, over 5 years: ~1.3x, over 20 years: ~3.8x
    double growthFactor = 1.972;
    if (_years == 5) {
      growthFactor = 1.28;
    } else if (_years == 20) {
      growthFactor = 3.65;
    }
    
    int delta = (_extraAmount * 12 * _years * growthFactor).round();
    // Round delta to nearest thousand
    delta = (delta / 1000).round() * 1000;
    
    int projectedCorpus = baselineCorpus + delta;
    
    // Dynamic changes impact
    int baselineScore = 782;
    int projectedScore = baselineScore + (_extraAmount / 350).round();
    if (projectedScore > 850) projectedScore = 850; // cap score
    
    // Europe trip goal delay (higher SIP redirection reduces short term goal speed)
    int tripDelayWeeks = (3 + (_extraAmount / 2500).round()).clamp(1, 12);
    
    // Surplus left
    int surplusLeft = (8200 - _extraAmount).round().clamp(0, 8200);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            const _StatusBar(),

            // Custom AppBar
            _buildAppBar(),

            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    Text(
                      tr('What do you want to try?'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.13,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Try Chips Selection Row
                    _buildTryChips(),
                    const SizedBox(height: 16),

                    // Controls Card
                    _buildControlsCard(),
                    const SizedBox(height: 16),

                    // Run Simulation primary CTA button
                    _buildRunSimulationButton(),
                    const SizedBox(height: 20),

                    // Result card (Navy Blue Gradient)
                    _buildResultCard(
                      projectedCorpus: projectedCorpus,
                      delta: delta,
                      baselineCorpus: baselineCorpus,
                    ),
                    const SizedBox(height: 24),

                    // What this changes section
                    Text(
                      tr('What this changes'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildChangesCard(
                      projectedScore: projectedScore,
                      tripDelayWeeks: tripDelayWeeks,
                      surplusLeft: surplusLeft,
                    ),
                    const SizedBox(height: 24),

                    // How we worked this out section
                    Text(
                      tr('How we worked this out'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildAssumptionsCard(),
                    const SizedBox(height: 16),

                    // Warning notice card
                    _buildWarningNotice(),
                    const SizedBox(height: 24),

                    // Bottom action buttons
                    _buildBottomActionButtons(),
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

  // App Bar
  Widget _buildAppBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF475569),
                  size: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                tr('Run a simulation'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          // Bookmark/Save Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isSaved = !_isSaved;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isSaved ? 'Simulation bookmarked!' : 'Bookmark removed!'),
                  backgroundColor: const Color(0xFF0B2545),
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Icon(
                  _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _isSaved ? const Color(0xFF2E75B6) : const Color(0xFF475569),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Try Chips Selector Row
  Widget _buildTryChips() {
    final tries = [
      {'label': 'Increase SIP', 'icon': Icons.trending_up_rounded},
      {'label': 'Home loan', 'icon': Icons.home_outlined},
      {'label': 'Job loss', 'icon': Icons.business_center_outlined},
      {'label': 'Custom', 'icon': Icons.tune_rounded},
    ];

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tries.length,
        itemBuilder: (context, index) {
          final item = tries[index];
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = label == _selectedTry;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF475569),
                size: 14,
              ),
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTry = label;
                    // Reset slider/stepper based on try preset
                    if (label == 'Increase SIP') {
                      _extraAmount = 5000.0;
                      _years = 12;
                    } else if (label == 'Home loan') {
                      _extraAmount = 8000.0;
                      _years = 20;
                    } else if (label == 'Job loss') {
                      _extraAmount = 2000.0;
                      _years = 5;
                    }
                  });
                }
              },
              selectedColor: const Color(0xFF0B2545),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0B2545) : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  // Controls Card
  Widget _buildControlsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Extra each month heading & value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('EXTRA EACH MONTH'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.48,
                ),
              ),
              Text(
                '₹${_formatIndianCurrency(_extraAmount.round())}',
                style: GoogleFonts.robotoMono(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B2545),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF2E75B6),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: Colors.white,
              trackHeight: 6,
              overlayColor: const Color(0xFF2E75B6).withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 3),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: _extraAmount,
              min: 1000.0,
              max: 15000.0,
              divisions: 14, // steps of 1000
              onChanged: (val) {
                setState(() {
                  _extraAmount = val;
                });
              },
            ),
          ),

          // Slider scale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹1,000',
                style: GoogleFonts.robotoMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                '₹15,000',
                style: GoogleFonts.robotoMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // For how long section
          Text(
            tr('FOR HOW LONG'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
              letterSpacing: 0.48,
            ),
          ),
          const SizedBox(height: 8),

          // Stepper options
          Row(
            children: [
              _buildStepOption(5, '5 yr'),
              const SizedBox(width: 8),
              _buildStepOption(12, '12 yr'),
              const SizedBox(width: 8),
              _buildStepOption(20, '20 yr'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepOption(int val, String label) {
    final isSelected = _years == val;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _years = val;
          });
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF4FA) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E75B6) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2E75B6) : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _runSimulationSequence() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E75B6)),
              ),
              const SizedBox(height: 16),
              Text(
                tr('Running compounding projection...'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0B2545),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      const int baselineCorpus = 4820000;
      double growthFactor = 1.972;
      if (_years == 5) {
        growthFactor = 1.28;
      } else if (_years == 20) {
        growthFactor = 3.65;
      }
      int delta = (_extraAmount * 12 * _years * growthFactor).round();
      delta = (delta / 1000).round() * 1000;
      int projectedCorpusVal = baselineCorpus + delta;
      String projectedCorpusStr = '₹${_formatIndianCurrency(projectedCorpusVal)}';

      Navigator.push(
        context,
        SmoothPageRoute(
          builder: (context) => SimulationSuccessScreen(
            extraAmount: _extraAmount,
            years: _years,
            projectedCorpus: projectedCorpusStr,
          ),
        ),
      );
    });
  }

  // Run simulation Button
  Widget _buildRunSimulationButton() {
    return GestureDetector(
      onTap: _runSimulationSequence,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF0B2545),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              tr('Run simulation'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Projected Result Card (Navy Gradient)
  Widget _buildResultCard({
    required int projectedCorpus,
    required int delta,
    required int baselineCorpus,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2545), Color(0xFF13315C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Radial Mesh Glow glow back decoration
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2E75B6).withOpacity(0.45),
                    const Color(0xFF2E75B6).withOpacity(0),
                  ],
                  stops: const [0, 0.7],
                ),
              ),
            ),
          ),

          // Content Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROJECTED CORPUS BY 2038',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.32,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹',
                    style: GoogleFonts.fraunces(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatIndianCurrency(projectedCorpus),
                    style: GoogleFonts.fraunces(
                      fontSize: 42,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: -1.26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Delta green badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: Color(0xFF4ADE80),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+₹${_formatIndianCurrency(delta)} vs today\'s plan',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Custom Painter Chart Line
              SizedBox(
                height: 96,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SimulationChartPainter(
                    extraAmountFactor: _extraAmount / 15000.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Chart Legends Row
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'With ₹${_formatIndianCurrency(_extraAmount.round())} more',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Today\'s plan',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Baseline text
              Text(
                'Today\'s plan reaches ₹${_formatIndianCurrency(baselineCorpus)}',
                style: GoogleFonts.robotoMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Changes Card ("What this changes")
  Widget _buildChangesCard({
    required int projectedScore,
    required int tripDelayWeeks,
    required int surplusLeft,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Financial Health Score
          _buildImpactRow(
            icon: Icons.star_outline_rounded,
            iconColor: const Color(0xFF16A34A),
            iconBgColor: const Color(0xFF16A34A).withOpacity(0.1),
            title: 'Financial Health Score',
            subtitle: 'Savings rate pillar improves',
            valueText: '782 → $projectedScore',
            valueColor: const Color(0xFF16A34A),
          ),
          _buildDivider(),
          // Europe Trip Goal
          _buildImpactRow(
            icon: Icons.radar_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBgColor: const Color(0xFFF59E0B).withOpacity(0.1),
            title: 'Europe Trip goal',
            subtitle: 'Slips because surplus is redirected',
            valueText: '+$tripDelayWeeks weeks',
            valueColor: const Color(0xFFF59E0B),
          ),
          _buildDivider(),
          // Monthly surplus
          _buildImpactRow(
            icon: Icons.credit_card_rounded,
            iconColor: const Color(0xFF0B2545),
            iconBgColor: const Color(0xFFEEF4FA),
            title: 'Monthly surplus',
            subtitle: 'Cushion left after fixed costs',
            valueText: '₹8,200 → ₹${_formatIndianCurrency(surplusLeft)}',
            valueColor: const Color(0xFF475569),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String valueText,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valueText,
            style: GoogleFonts.robotoMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // Assumptions Card ("How we worked this out")
  Widget _buildAssumptionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAssumptionRow('Assumed equity return', '11.0% p.a.'),
          _buildDivider(),
          _buildAssumptionRow('Assumed inflation', '6.0% p.a.'),
          _buildDivider(),
          _buildAssumptionRow('Existing SIPs counted', '₹18,000/mo'),
          _buildDivider(),
          _buildAssumptionRow('Horizon', '$_years years'),
        ],
      ),
    );
  }

  Widget _buildAssumptionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
        ],
      ),
    );
  }

  // Warning Notice
  Widget _buildWarningNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('These are projections, not promises'),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Markets move. Returns are estimated from long-run averages and may be lower — or negative in any given year.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom action buttons
  Widget _buildBottomActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulation saved to bookmarks!'),
                  backgroundColor: Color(0xFF0B2545),
                ),
              );
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0B2545)),
              ),
              child: Center(
                child: Text(
                  tr('Save'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B2545),
                    letterSpacing: -0.15,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 140, // flex 1.4 equivalent ratio
          child: GestureDetector(
            // Persists the accepted what-if and raises the monthly
            // contribution on the customer's first active goal. This used to
            // show a success message and change nothing, so the goals screen
            // still showed the old contribution afterwards.
            onTap: () async {
              final ok = await ApiService.instance.applySimulation(
                scenario: 'extra_monthly_contribution',
                summary:
                    'Extra ₹${_formatIndianCurrency(_extraAmount.round())} a month',
                deltaPaise: (_extraAmount * 100).round(),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Contribution increased by ₹${_formatIndianCurrency(_extraAmount.round())} a month.'
                      : 'Could not apply that change. Try again.'),
                  backgroundColor: ok
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              );
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF0B2545),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  tr('Apply this change'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Divider Helper
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFE2E8F0),
      indent: 16,
      endIndent: 16,
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

// Chart Painter to dynamically draw simulation graph lines
class _SimulationChartPainter extends CustomPainter {
  final double extraAmountFactor; // ranges 0.0 to 1.0

  _SimulationChartPainter({required this.extraAmountFactor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw baseline today's plan (dashed gray line)
    final baselinePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final baselinePath = Path();
    baselinePath.moveTo(0, size.height * 0.8);
    baselinePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.6,
      size.width,
      size.height * 0.45,
    );

    // Draw dashed path for baseline
    final dashPath = Path();
    double distance = 0;
    bool draw = true;
    for (var measurePath in baselinePath.computeMetrics()) {
      while (distance < measurePath.length) {
        final length = draw ? 6.0 : 4.0;
        dashPath.addPath(
          measurePath.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, baselinePaint);

    // 2. Draw Simulation Line (solid bright green line)
    // The curve rises higher depending on extraAmountFactor
    final simPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Splitting gradient glow below simulation path
    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final simPath = Path();
    simPath.moveTo(0, size.height * 0.8);
    
    // Ending height is pulled upwards based on extra factor
    double endY = size.height * (0.35 - (extraAmountFactor * 0.28));
    double controlY = size.height * (0.55 - (extraAmountFactor * 0.15));
    
    simPath.quadraticBezierTo(
      size.width * 0.5,
      controlY,
      size.width,
      endY,
    );

    // Draw gradient fill under simulated line
    final fillPath = Path.from(simPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    fillPaint.shader = LinearGradient(
      colors: [
        const Color(0xFF4ADE80).withOpacity(0.18),
        const Color(0xFF4ADE80).withOpacity(0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(simPath, simPaint);
  }

  @override
  bool shouldRepaint(covariant _SimulationChartPainter oldDelegate) {
    return oldDelegate.extraAmountFactor != extraAmountFactor;
  }
}
