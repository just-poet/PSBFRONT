import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pin_screen.dart';
import '../main.dart';
import 'payment_success.dart';

class ToSelfTransferScreen extends StatefulWidget {
  const ToSelfTransferScreen({super.key});

  @override
  State<ToSelfTransferScreen> createState() => _ToSelfTransferScreenState();
}

class _ToSelfTransferScreenState extends State<ToSelfTransferScreen> {
  double _selectedAmount = 25000.0;

  void _onAmountSelected(double val) {
    setState(() {
      _selectedAmount = val;
    });
  }

  void _submitSelfTransfer() {
    Navigator.push(
      context,
      SmoothPageRoute(
        builder: (context) => MobileDeviceFrame(
          child: PinScreen(
            title: 'Enter your 6-digit PIN',
            subtitle: 'Self Transfer · HDFC Bank to SBI',
            amount: _selectedAmount,
            onSuccess: () {
              // Pop PinScreen
              Navigator.pop(context);
              // Pop ToSelfTransferScreen
              Navigator.pop(context);
              // Navigate to PaymentSuccessScreen
              Navigator.push(
                context,
                SmoothPageRoute(
                  builder: (context) => MobileDeviceFrame(
                    child: PaymentSuccessScreen(
                      recipientName: 'Self Transfer',
                      recipientUpi: 'State Bank of India',
                      amount: _selectedAmount,
                      fromAccount: 'HDFC ••• 8472',
                      method: 'Self Transfer',
                      referenceId: 'HDFC${(100000 + (_selectedAmount * 99).toInt()).toString()}XQ${(100 + (_selectedAmount % 899).toInt()).toString()}',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedVal = _selectedAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final String amountStr = '₹$formattedVal';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            const _AppBar(),

            // 3. Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading: Between your accounts
                    Text(
                      'Between your accounts',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Double Account Cards with Overlapping Swap Button
                    const _AccountCardsSection(),

                    const SizedBox(height: 36),

                    // Amount Label
                    const Center(
                      child: _AmountLabel(),
                    ),
                    const SizedBox(height: 8),

                    // Large Amount Display
                    Center(
                      child: Text(
                        amountStr,
                        style: GoogleFonts.fraunces(
                          fontSize: 56,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0B2545),
                          letterSpacing: -1.68,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preset Amount Pills Row
                    _PresetAmountsRow(
                      selectedAmount: _selectedAmount,
                      onAmountSelected: _onAmountSelected,
                    ),

                    const SizedBox(height: 24),

                    // Info Security Badge
                    const _SecurityBadge(),

                    const SizedBox(height: 32),

                    // Primary Action Button
                    GestureDetector(
                      onTap: _submitSelfTransfer,
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF13315C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Transfer Now',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 1. Status Bar Widget
// ---------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------
// 2. Custom App Bar Widget
// ---------------------------------------------------------------------
class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
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
            'Transfer to Self',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          // Symmetrical spacer
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF475569),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 3. Double Account Cards and Swap Button Stack
// ---------------------------------------------------------------------
class _AccountCardsSection extends StatelessWidget {
  const _AccountCardsSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            // FROM card (PSB)
            Container(
              padding: const EdgeInsets.all(17.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Logo container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F0F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'PSB',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B4F8C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Middle Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FROM',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Savings A/C',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'XXXX XXXX 4521',
                          style: TextStyle(
                            fontFamily: 'Geist_Mono',
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right Available Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'AVAILABLE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '₹2,18,450',
                        style: TextStyle(
                          fontFamily: 'Geist_Mono',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A1628),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16), // Separator

            // TO card (HDFC)
            Container(
              padding: const EdgeInsets.all(17.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Logo container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'HDFC',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB8311C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Middle Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Salary A/C',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'XXXX XXXX 8472',
                          style: TextStyle(
                            fontFamily: 'Geist_Mono',
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right Available Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'AVAILABLE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '₹68,200',
                        style: TextStyle(
                          fontFamily: 'Geist_Mono',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A1628),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        // Floating Swap Button positioned directly in the middle overlap
        Positioned(
          left: 0,
          right: 0,
          top: 75, // Centered vertically relative to card sizes and SizedBox(height: 16)
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0A000000), // 4% opacity black
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_vert_rounded,
                color: Color(0xFF0B4F8C),
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// 4. Amount Label Widget
// ---------------------------------------------------------------------
class _AmountLabel extends StatelessWidget {
  const _AmountLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'AMOUNT',
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
        letterSpacing: 1.32,
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 5. Preset Amounts Horizontal Row Widget
// ---------------------------------------------------------------------
class _PresetAmountsRow extends StatelessWidget {
  final double selectedAmount;
  final ValueChanged<double> onAmountSelected;

  const _PresetAmountsRow({
    required this.selectedAmount,
    required this.onAmountSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _amountPill(1000, isActive: selectedAmount == 1000),
        const SizedBox(width: 17),
        _amountPill(5000, isActive: selectedAmount == 5000),
        const SizedBox(width: 17),
        _amountPill(25000, isActive: selectedAmount == 25000),
        const SizedBox(width: 17),
        _amountPill(50000, isActive: selectedAmount == 50000),
      ],
    );
  }

  Widget _amountPill(double amount, {required bool isActive}) {
    final String formattedVal = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final String amountStr = '₹$formattedVal';

    return GestureDetector(
      onTap: () => onAmountSelected(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 9.0),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0B2545) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? const Color(0xFF0B2545) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          amountStr,
          style: TextStyle(
            fontFamily: 'Geist_Mono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF0A1628),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 6. Security Info Badge Widget
// ---------------------------------------------------------------------
class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Checked outline banner circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x1A16A34A), // color/spring-green/36 10% opacity
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: Color(0xFF16A34A),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Description text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instant transfer · No charges',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Both accounts verified · IMPS via NPCI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
