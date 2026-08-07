import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_dashboard.dart';
import 'bottom_nav_bar.dart' show HideBottomNav;

class PaymentSuccessScreen extends StatelessWidget {
  final String recipientName;
  final String recipientUpi;
  final double amount;
  final String fromAccount;
  final String method;
  final String referenceId;

  const PaymentSuccessScreen({
    super.key,
    this.recipientName = 'Rohan Sharma',
    this.recipientUpi = 'rohan.sharma@okhdfcbank',
    this.amount = 2400.0,
    this.fromAccount = 'HDFC ••• 8472',
    this.method = 'UPI',
    this.referenceId = 'HDFC8472XQ491',
  });

  String _formatAmount(double amt) {
    final String raw = amt.toStringAsFixed(0);
    if (raw.length <= 3) return '₹$raw';
    final String lastThree = raw.substring(raw.length - 3);
    final String other = raw.substring(0, raw.length - 3);
    return '₹$other,$lastThree';
  }

  String _formatCurrentDateTime() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final String monthStr = months[now.month - 1];
    final String dayStr = now.day.toString().padLeft(2, '0');
    final String hourStr = now.hour.toString().padLeft(2, '0');
    final String minuteStr = now.minute.toString().padLeft(2, '0');
    return '$dayStr $monthStr $hourStr:$minuteStr IST';
  }

  @override
  Widget build(BuildContext context) {
    // The receipt ends the payment journey and clears the stack on its way to
    // the dashboard, so the tab bar has nothing useful to do here.
    return HideBottomNav(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Status Bar
              const _StatusBar(),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),

                      // Soft circular checkmark design
                      Center(
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: const BoxDecoration(
                            color: Color(0x0C16A34A), // 5% opacity green
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: Color(0x1A16A34A), // 10% opacity green
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF16A34A),
                              size: 48,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Center(
                        child: Text(
                          tr('Payment Successful'),
                          style: GoogleFonts.fraunces(
                            fontSize: 26,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF0B2545),
                            letterSpacing: -0.52,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle (Paid to Rohan Sharma)
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Paid to ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF475569),
                            ),
                            children: [
                              TextSpan(
                                text: recipientName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A1628),
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Large Amount
                      Center(
                        child: Text(
                          _formatAmount(amount),
                          style: GoogleFonts.fraunces(
                            fontSize: 44,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF0B2545),
                            letterSpacing: -1.32,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Details Card
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(17.0),
                        child: Column(
                          children: [
                            _buildDetailRow('From', fromAccount),
                            const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 16,
                                thickness: 1),
                            _buildDetailRow('To UPI', recipientUpi),
                            const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 16,
                                thickness: 1),
                            _buildDetailRow(
                                'Date · Time', _formatCurrentDateTime()),
                            const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 16,
                                thickness: 1),
                            _buildDetailRow('Method', method),
                            const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 16,
                                thickness: 1),
                            _buildDetailRow('Charges', '₹0.00', isGreen: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Reference Box
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: referenceId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Reference ID copied to clipboard!'),
                              backgroundColor: const Color(0xFF0B2545),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 11.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('REFERENCE'),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    referenceId,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0A1628),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.content_copy_outlined,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tri-button Actions (Receipt, Share, Save)
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context,
                              icon: Icons.file_download_outlined,
                              label: 'Receipt',
                              message: 'Receipt downloaded successfully!',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              icon: Icons.share_outlined,
                              label: 'Share',
                              message: 'Payment details shared!',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              icon: Icons.bookmark_border_rounded,
                              label: tr('Save'),
                              message: 'Payment saved successfully!',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Button Bar
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 13.0,
                  bottom: 24.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2545),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          settings: const RouteSettings(name: '/home'),
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const HomeDashboardScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text(
                      tr('Back to Home'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(width: 12),
        // Flexible and right-aligned: a bank transfer puts
        // "Account ••• 8472 · IFSC SBIN0000000" in the To row, which is wider
        // than the card and overflowed it.
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color:
                  isGreen ? const Color(0xFF16A34A) : const Color(0xFF0A1628),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String message,
  }) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(message),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF0A1628),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A1628),
              ),
            ),
          ],
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
