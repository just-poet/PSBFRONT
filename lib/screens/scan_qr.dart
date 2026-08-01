import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pin_screen.dart';
import '../main.dart';
import 'payment_success.dart';

class ScanQrScreen extends StatelessWidget {
  const ScanQrScreen({super.key});

  void _showPaymentBottomSheet(BuildContext context, String merchantName) {
    final textController = TextEditingController(text: '500'); // default amount

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay to Merchant',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A1628),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF4FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      color: Color(0xFF0B2545),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchantName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      Text(
                        'starbucks@upi',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'ENTER AMOUNT',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.55,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '₹ ',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B2545),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B2545),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2545),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final val = double.tryParse(textController.text) ?? 500.0;
                  Navigator.pop(context); // close bottom sheet
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      builder: (context) => MobileDeviceFrame(
                        child: PinScreen(
                          title: 'Enter your 6-digit PIN',
                          subtitle: '$merchantName · starbucks@upi',
                          amount: val,
                          onSuccess: () {
                            // Pop PinScreen
                            Navigator.pop(context);
                            // Pop ScanQrScreen
                            Navigator.pop(context);
                            // Navigate to PaymentSuccessScreen
                            Navigator.push(
                              context,
                              SmoothPageRoute(
                                builder: (context) => MobileDeviceFrame(
                                  child: PaymentSuccessScreen(
                                    recipientName: merchantName,
                                    recipientUpi: '${merchantName.toLowerCase().replaceAll(' ', '')}@upi',
                                    amount: val,
                                    fromAccount: 'HDFC ••• 8472',
                                    method: 'UPI',
                                    referenceId: 'HDFC${(100000 + (val * 99).toInt()).toString()}XQ${(100 + (val % 899).toInt()).toString()}',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Pay Now',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // Viewfinder dimensions
    const double cutoutWidth = 245.0;
    const double cutoutHeight = 245.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            const _AppBar(),

            // 3. Scanner Viewport
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double leftOffset = (constraints.maxWidth - cutoutWidth) / 2;
                  final double dynamicCutoutTop = (constraints.maxHeight - cutoutHeight) / 2 - 40;

                  return Stack(
                    children: [
                      // Camera Preview Placeholder Background with Tap-to-simulate scan
                      GestureDetector(
                        onTap: () => _showPaymentBottomSheet(context, 'Starbucks Coffee'),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: const Color(0xFF0B2545), // Brand Navy
                          child: Center(
                            child: Text(
                              'Tap viewfinder area to simulate QR scan',
                              style: GoogleFonts.inter(
                                color: const Color(0x80FFFFFF),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Translucent Overlay with transparent cutout
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: ScannerOverlayPainter(
                              cutoutWidth: cutoutWidth,
                              cutoutHeight: cutoutHeight,
                              cutoutTop: dynamicCutoutTop,
                            ),
                          ),
                        ),
                      ),

                      // Viewfinder corner brackets
                      Positioned(
                        left: leftOffset - 11,
                        top: dynamicCutoutTop - 11,
                        child: const IgnorePointer(
                          child: SizedBox(
                            width: cutoutWidth + 22,
                            height: cutoutHeight + 22,
                            child: _CornerBrackets(),
                          ),
                        ),
                      ),

                      // Gallery Image Picker Button
                      Positioned(
                        top: dynamicCutoutTop + cutoutHeight + 48,
                        left: (constraints.maxWidth - 56) / 2,
                        child: _GalleryPickerButton(
                          onTap: () => _simulateGalleryQrPick(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simulated Picker to scan QR Code from photos gallery
  void _simulateGalleryQrPick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select QR from Gallery',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A1628),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF4FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0B2545)),
                ),
                title: Text(
                  'qr_code_starbucks_receipt.png',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                subtitle: Text(
                  'Image · 142 KB · Decided Today',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext); // Close bottom sheet
                  
                  // Show scanning progress dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) {
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B2545)),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Scanning QR Code...',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A1628),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Decoding image with AI scanner',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  // Dismiss progress and show payment after 1.2s
                  Future.delayed(const Duration(milliseconds: 1200), () {
                    Navigator.pop(context); // Dismiss dialog
                    _showPaymentBottomSheet(context, 'Starbucks Coffee');
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
          const Text(
            'Scan QR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A1628),
            ),
          ),
          // Info Button
          GestureDetector(
            onTap: () {
              // Action for scanner info
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
// 3. Custom Scanner Overlay Painter
// ---------------------------------------------------------------------
class ScannerOverlayPainter extends CustomPainter {
  final double cutoutWidth;
  final double cutoutHeight;
  final double cutoutTop;

  const ScannerOverlayPainter({
    required this.cutoutWidth,
    required this.cutoutHeight,
    required this.cutoutTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Translucent dark overlay using Biscay Blue/Navy color with opacity
    final paint = Paint()
      ..color = const Color(0xE813315C) // color/blue/biscay-20 with high opacity
      ..style = PaintingStyle.fill;

    final double left = (size.width - cutoutWidth) / 2;
    final rect = Rect.fromLTWH(left, cutoutTop, cutoutWidth, cutoutHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Combine screen bounds and cutout path
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(rrect),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------
// 4. Viewfinder Corners Component
// ---------------------------------------------------------------------
class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: ViewfinderCornersPainter(),
    );
  }
}

class ViewfinderCornersPainter extends CustomPainter {
  final double cornerSize;
  final double borderRadius;
  final double strokeWidth;
  final Color strokeColor;

  const ViewfinderCornersPainter({
    this.cornerSize = 44.0,
    this.borderRadius = 28.0,
    this.strokeWidth = 4.0,
    this.strokeColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double r = borderRadius;
    final double s = cornerSize;

    // 1. Top-Left Corner
    final pathTL = Path()
      ..moveTo(0, s)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(s, 0);
    canvas.drawPath(pathTL, paint);

    // 2. Top-Right Corner
    final pathTR = Path()
      ..moveTo(w - s, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, s);
    canvas.drawPath(pathTR, paint);

    // 3. Bottom-Left Corner
    final pathBL = Path()
      ..moveTo(0, h - s)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(s, h);
    canvas.drawPath(pathBL, paint);

    // 4. Bottom-Right Corner
    final pathBR = Path()
      ..moveTo(w - s, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - s);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------
// 5. Gallery Picker Button Widget
// ---------------------------------------------------------------------
class _GalleryPickerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GalleryPickerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000), // 15% opacity black
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.photo_library_outlined,
          color: Color(0xFF0B2545),
          size: 24,
        ),
      ),
    );
  }
}
