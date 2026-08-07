import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyFreezeScreen extends StatefulWidget {
  final VoidCallback onFreezeConfirmed;
  const EmergencyFreezeScreen({super.key, required this.onFreezeConfirmed});

  @override
  State<EmergencyFreezeScreen> createState() => _EmergencyFreezeScreenState();
}

class _EmergencyFreezeScreenState extends State<EmergencyFreezeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Center Content scroll area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),

                    // Red Badge at the top (Figma node 640:4745)
                    Container(
                      width: 80,
                      height: 49.09,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title (Figma node 640:4750)
                    Text(
                      tr('Emergency Freeze'),
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0B2545),
                        letterSpacing: -0.84,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle (Figma node 640:4753)
                    Text(
                      tr('This will instantly halt all outgoing transactions\nacross every linked account.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Details Card Container (Figma node 640:4755)
                    Container(
                      padding: const EdgeInsets.all(17.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header label
                          Text(
                            tr('WHAT HAPPENS WHEN YOU FREEZE'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                              letterSpacing: 0.88,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Bullet items with divider lines
                          _buildDetailsItem(
                            isBoldStart: true,
                            boldStartText: 'All outgoing payments ',
                            normalEndText: 'blocked — UPI, NEFT, IMPS',
                          ),
                          const Divider(height: 22, thickness: 1, color: Color(0xFFE2E8F0)),
                          _buildDetailsItem(
                            isBoldStart: false,
                            normalEndText: 'Cards paused — debit, credit, virtual',
                          ),
                          const Divider(height: 22, thickness: 1, color: Color(0xFFE2E8F0)),
                          _buildDetailsItem(
                            isBoldStart: false,
                            boldStartText: 'Incoming credits ',
                            normalEndText: 'still work — salary, refunds',
                            alternativeHighlight: true, // bolding the middle part
                          ),
                          const Divider(height: 22, thickness: 1, color: Color(0xFFE2E8F0)),
                          _buildDetailsItem(
                            isBoldStart: false,
                            boldStartText: 'Unfreezing needs ',
                            normalEndText: '24-hour cooling-off + biometrics',
                            alternativeHighlight2: true, // bolding cooling off
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Fixed Action Section at the bottom (Figma node 640:4770)
            Container(
              padding: const EdgeInsets.fromLTRB(20.0, 17.0, 20.0, 24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Interactive Slider
                  SlideToFreezeButton(
                    onTriggered: () {
                      widget.onFreezeConfirmed();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Cancel text button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        tr('Cancel — keep accounts active'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E75B6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsItem({
    required bool isBoldStart,
    String? boldStartText,
    required String normalEndText,
    bool alternativeHighlight = false,
    bool alternativeHighlight2 = false,
  }) {
    if (alternativeHighlight) {
      return RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF0A1628),
            height: 1.4,
          ),
          children: const [
            TextSpan(text: 'Incoming credits '),
            TextSpan(text: 'still work', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' — salary, refunds'),
          ],
        ),
      );
    }

    if (alternativeHighlight2) {
      return RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF0A1628),
            height: 1.4,
          ),
          children: const [
            TextSpan(text: 'Unfreezing needs '),
            TextSpan(text: '24-hour cooling-off', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' + biometrics'),
          ],
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF0A1628),
          height: 1.4,
        ),
        children: [
          if (boldStartText != null)
            TextSpan(
              text: boldStartText,
              style: TextStyle(
                fontWeight: isBoldStart ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          TextSpan(
            text: normalEndText,
            style: TextStyle(
              fontWeight: isBoldStart ? FontWeight.normal : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class SlideToFreezeButton extends StatefulWidget {
  final VoidCallback onTriggered;
  const SlideToFreezeButton({super.key, required this.onTriggered});

  @override
  State<SlideToFreezeButton> createState() => _SlideToFreezeButtonState();
}

class _SlideToFreezeButtonState extends State<SlideToFreezeButton> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _springAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_springController);
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _springBack(double from) {
    _springAnimation = Tween<double>(begin: from, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _springAnimation.value;
        });
      });
    _springController.reset();
    _springController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute maximum drag width dynamically based on bounds
        final double maxDragDistance = constraints.maxWidth - 56 - 6;

        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              // Sliding track background text
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: 0.4,
                      child: Text(
                        '>>>  ',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 1.95,
                        ),
                      ),
                    ),
                    Text(
                      tr('SLIDE TO FREEZE ALL'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.95,
                      ),
                    ),
                  ],
                ),
              ),

              // Draggable white handle
              Positioned(
                left: 3 + _dragOffset,
                top: 2,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragOffset += details.primaryDelta!;
                      if (_dragOffset < 0) _dragOffset = 0;
                      if (_dragOffset > maxDragDistance) _dragOffset = maxDragDistance;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragOffset >= maxDragDistance * 0.9) {
                      setState(() {
                        _dragOffset = maxDragDistance;
                      });
                      widget.onTriggered();
                    } else {
                      _springBack(_dragOffset);
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_open_rounded,
                        color: Color(0xFFDC2626),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
