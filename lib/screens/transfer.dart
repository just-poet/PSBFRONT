import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'search_ifsc.dart';
import 'pin_screen.dart';
import '../main.dart';
import 'payment_success.dart';
import '../services/api_service.dart';

class BankTransferScreen extends StatelessWidget {
  const BankTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    // Secure Ledger Card
                    const _SecureLedgerCard(),

                    const SizedBox(height: 24),

                    // Form section
                    const _TransferForm(),

                    const SizedBox(height: 24),

                    // Recent Transfers Section
                    const _RecentTransfersSection(),

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
            'Bank transfer',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          // Info Button
          GestureDetector(
            onTap: () {
              // Action for transfer info
            },
            child: Container(
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
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 3. Secure Ledger Card Widget
// ---------------------------------------------------------------------
class _SecureLedgerCard extends StatelessWidget {
  const _SecureLedgerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF13315C), // color/azure/22
            Color(0xFF0A1628), // color/azure/10
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Decorative atmospheric blur glow
          Positioned(
            right: -32,
            top: -32,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 128,
                height: 128,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2E75B6),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Ledger Transfer',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Verified by FINIX Protocol',
                            style: GoogleFonts.inter(
                              color: const Color(0xE6FFFFFF), // 90% opacity white
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0x14FFFFFF), // 8% opacity white
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
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

class _TransferForm extends StatefulWidget {
  const _TransferForm();

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '10000');

  @override
  void dispose() {
    _accountController.dispose();
    _ifscController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitTransfer() {
    final account = _accountController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final amountText = _amountController.text.trim();

    if (account.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid account number (9-18 digits).',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (ifsc.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid 11-digit IFSC code.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid payment amount.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String lastFour = account.substring(account.length - 4);
    Navigator.push(
      context,
      SmoothPageRoute(
        builder: (context) => MobileDeviceFrame(
          child: PinScreen(
            title: 'Enter your 6-digit PIN',
            subtitle: 'Account ••• $lastFour · IFSC $ifsc',
            amount: amount,
            onSuccess: () async {
              try {
                final int amountPaise = (amount * 100).toInt();
                final initResult = await ApiService.instance.initiateTransaction(
                  amountPaise: amountPaise,
                  recipient: 'Account ••• $lastFour (IFSC $ifsc)',
                  channel: 'IMPS',
                );

                final String txnId = initResult['transactionId'] ?? 'txn_000';
                final bool requiresOverride = initResult['stepUpRequired'] ?? false;

                if (requiresOverride) {
                  await ApiService.instance.overrideTransaction(
                    transactionId: txnId,
                    otp: '123456',
                    biometricOk: true,
                  );
                }
              } catch (_) {}

              if (!context.mounted) return;

              // Pop PinScreen
              Navigator.pop(context);
              // Pop BankTransferScreen
              Navigator.pop(context);
              // Navigate to PaymentSuccessScreen
              Navigator.push(
                context,
                SmoothPageRoute(
                  builder: (context) => MobileDeviceFrame(
                    child: PaymentSuccessScreen(
                      recipientName: 'Account Holder',
                      recipientUpi: 'Account ••• $lastFour · IFSC $ifsc',
                      amount: amount,
                      fromAccount: 'HDFC ••• 8472',
                      method: 'Bank Transfer',
                      referenceId: 'HDFC${(100000 + (amount * 99).toInt()).toString()}XQ${(100 + (amount % 899).toInt()).toString()}',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Number Label
        Text(
          'BANK ACCOUNT NUMBER',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
            letterSpacing: 0.55,
          ),
        ),
        const SizedBox(height: 8),
        // Account Number Input field
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 17.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter 9–18 digit account number',
                    hintStyle: TextStyle(
                      fontFamily: 'Geist_Mono',
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // IFSC Label and Search link Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'IFSC CODE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
                letterSpacing: 0.55,
              ),
            ),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: SearchIfscScreen(),
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _ifscController.text = result;
                  });
                }
              },
              child: Text(
                'Search for IFSC',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3980F4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // IFSC Input field
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 17.0),
          child: Center(
            child: TextField(
              controller: _ifscController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ex: HDFC0001234',
                hintStyle: TextStyle(
                  fontFamily: 'Geist_Mono',
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Amount Label
        Text(
          'AMOUNT (₹)',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
            letterSpacing: 0.55,
          ),
        ),
        const SizedBox(height: 8),
        // Amount Input field
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 17.0),
          child: Center(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter transfer amount',
                hintStyle: TextStyle(
                  fontFamily: 'Geist_Mono',
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Continue Button CTA
        GestureDetector(
          onTap: _submitTransfer,
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF13315C), // color/azure/22
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// 5. Recent Transfers Widget (Empty State)
// ---------------------------------------------------------------------
class _RecentTransfersSection extends StatelessWidget {
  const _RecentTransfersSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent transfers',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 33.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular background with clock history icon
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F9FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.history_rounded,
                    color: Color(0xFF2E75B6),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No recent transfers yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Once you send money, your frequent\ncontacts will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
