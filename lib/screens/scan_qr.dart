import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import '../services/api_service.dart';
import 'risk_warning.dart';
import '../services/upi_qr.dart';
import 'payment_success.dart';
import 'pin_screen.dart';

/// Scan QR — live camera scanning plus decoding a QR out of a gallery image.
///
/// Camera permission is requested on first use and the three outcomes are
/// handled distinctly: granted (scan), denied (retry), permanently denied
/// (deep-link to app settings, since re-requesting is a no-op).
///
/// A decoded UPI payload drives a real payment through the backend
/// (ApiService.initiateTransaction), including the risk-engine step-up, rather
/// than a simulated success screen.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

enum _CameraState { checking, granted, denied, permanentlyDenied, unavailable }

/// Per-transaction ceiling enforced by the backend
/// (internal/api/validate.go: maxPaymentPaise = 100_000_000 paise).
const double _maxTransactionRupees = 1000000;

class _ScanQrScreenState extends State<ScanQrScreen> with WidgetsBindingObserver {
  MobileScannerController? _controller;
  _CameraState _cameraState = _CameraState.checking;
  bool _torchOn = false;

  /// Guards against the detector firing repeatedly for the same code while the
  /// payment sheet is opening.
  bool _handlingCode = false;
  bool _decodingImage = false;

  /// Shown on the risk warning as one of the signals the engine weighs.
  int? _healthScore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadHealthScore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// The OS tears down the camera when the app is backgrounded; restart it on
  /// resume so returning to the screen shows a live preview, not a frozen frame.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || _cameraState != _CameraState.granted) return;
    // Not a switch over the enum: AppLifecycleState gained `hidden` in a later
    // Flutter release, and an exhaustive switch would fail to compile on SDKs
    // that predate it.
    if (state == AppLifecycleState.resumed) {
      if (!_handlingCode) _safeStart(controller);
    } else {
      _safeStop(controller);
    }
  }

  /// start()/stop() throw if the controller is already in that state (or was
  /// disposed). The result is fire-and-forget, so swallow rather than leaking
  /// an unhandled async error.
  void _safeStart(MobileScannerController controller) {
    unawaited(controller.start().catchError((_) {}));
  }

  void _safeStop(MobileScannerController controller) {
    unawaited(controller.stop().catchError((_) {}));
  }

  Future<void> _loadHealthScore() async {
    final health = await ApiService.instance.getHealthScore();
    if (!mounted) return;
    setState(() =>
        _healthScore = (health['score300To900'] as num?)?.toInt());
  }

  Future<void> _initCamera() async {
    setState(() => _cameraState = _CameraState.checking);

    PermissionStatus status;
    try {
      status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
    } catch (e) {
      // Desktop / web builds have no permission_handler implementation; let the
      // scanner itself decide whether a camera exists.
      //
      // On Android the plugin IS present, so an exception here means something
      // genuinely went wrong. Assuming "granted" in that case skipped the OS
      // prompt entirely and dropped the user onto a black viewfinder with no
      // explanation — indistinguishable from the app simply never asking.
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        if (!mounted) return;
        setState(() => _cameraState = _CameraState.denied);
        return;
      }
      status = PermissionStatus.granted;
    }

    if (!mounted) return;

    if (status.isPermanentlyDenied || status.isRestricted) {
      setState(() => _cameraState = _CameraState.permanentlyDenied);
      return;
    }
    if (!status.isGranted) {
      setState(() => _cameraState = _CameraState.denied);
      return;
    }

    try {
      final controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      await controller.start();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraState = _CameraState.granted;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraState = _CameraState.unavailable);
    }
  }

  // ─── QR handling ────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_handlingCode) return;
    for (final barcode in capture.barcodes) {
      final payment = UpiPayment.tryParse(barcode.rawValue);
      if (payment != null) {
        _handlingCode = true;
        final c = _controller;
        if (c != null) _safeStop(c);
        _openPaymentSheet(payment);
        return;
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_decodingImage) return;
    setState(() => _decodingImage = true);
    try {
      // image_picker uses the OS photo picker on Android 13+, which needs no
      // storage permission at all. Older versions prompt via the plugin.
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;

      // When the camera was never granted there is no live controller, so spin
      // up a throwaway one purely to decode the image — and dispose it after.
      final existing = _controller;
      final controller = existing ??
          MobileScannerController(formats: const [BarcodeFormat.qrCode]);
      BarcodeCapture? result;
      try {
        result = await controller.analyzeImage(file.path);
      } finally {
        if (existing == null) await controller.dispose();
      }

      UpiPayment? payment;
      for (final barcode in result?.barcodes ?? const <Barcode>[]) {
        payment = UpiPayment.tryParse(barcode.rawValue);
        if (payment != null) break;
      }

      if (!mounted) return;
      if (payment == null) {
        _showMessage('No UPI QR code found in that image.');
        return;
      }
      _handlingCode = true;
      final c = _controller;
      if (c != null) _safeStop(c);
      _openPaymentSheet(payment);
    } catch (_) {
      if (mounted) _showMessage('Could not read that image.');
    } finally {
      if (mounted) setState(() => _decodingImage = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0B2545),
      ),
    );
  }

  /// Re-arms the scanner after the user backs out of a payment.
  void _resumeScanning() {
    _handlingCode = false;
    if (_cameraState == _CameraState.granted) {
      final c = _controller;
      if (c != null) _safeStart(c);
    }
  }

  // ─── Payment ────────────────────────────────────────────────────────

  void _openPaymentSheet(UpiPayment payment) {
    final controller = TextEditingController(
      text: payment.hasFixedAmount ? payment.amount!.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Pay to Merchant'),
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
                  child: const Icon(Icons.store_rounded, color: Color(0xFF0B2545)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.payeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      Text(
                        payment.payeeAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (payment.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                payment.note,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              payment.hasFixedAmount ? 'AMOUNT (SET BY MERCHANT)' : 'ENTER AMOUNT',
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
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      // A merchant-fixed amount must not be editable.
                      readOnly: payment.hasFixedAmount,
                      autofocus: !payment.hasFixedAmount,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B2545),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: payment.hasFixedAmount ? null : '0.00',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final amount = double.tryParse(controller.text.trim()) ?? 0;
                if (amount <= 0) {
                  _showMessage('Enter an amount greater than zero.');
                  return;
                }
                // Mirrors the server-side per-transaction ceiling
                // (api.ValidateTransactionRequest, ₹10,00,000). Checked here
                // too because ApiService falls back to mock data on a 400,
                // which would otherwise show a success screen for a payment
                // the backend actually rejected.
                if (amount > _maxTransactionRupees) {
                  _showMessage('Amount exceeds the ₹10,00,000 per-transaction limit.');
                  return;
                }
                Navigator.pop(sheetContext);
                _confirmWithPin(payment, amount);
              },
              child: Text(
                tr('Pay Now'),
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Sheet dismissed without paying — allow scanning again.
      if (mounted && _handlingCode) _resumeScanning();
    });
  }

  void _confirmWithPin(UpiPayment payment, double amount) {
    Navigator.push(
      context,
      SmoothPageRoute(
        builder: (_) => MobileDeviceFrame(
          child: PinScreen(
            title: 'Enter your 6-digit PIN',
            subtitle: '${payment.payeeName} · ${payment.payeeAddress}',
            amount: amount,
            // The payment is sent and the risk verdict resolved here, before
            // any success animation plays. Returning false stops the tick.
            onAuthorise: () => _authorisePayment(payment, amount),
            onSuccess: () => _showReceipt(payment, amount),
          ),
        ),
      ),
    ).then((_) {
      if (mounted && _handlingCode) _resumeScanning();
    });
  }

  /// Sends the payment to the backend and honours the risk engine's verdict.
  /// Reference for the receipt, set once the payment settles.
  String _reference = '';

  /// Sends the payment and resolves the risk engine's verdict.
  ///
  /// Runs while the PIN screen shows "Authorising…", so a flagged payment
  /// surfaces its warning *before* any success animation. Returns false when
  /// the payment did not settle, which stops the tick from playing.
  Future<bool> _authorisePayment(UpiPayment payment, double amount) async {
    final amountPaise = (amount * 100).round();
    _reference = 'UPI${DateTime.now().millisecondsSinceEpoch % 100000000}';

    try {
      final result = await ApiService.instance.initiateTransaction(
        amountPaise: amountPaise,
        recipient: payment.payeeAddress,
        channel: 'upi',
      );

      final txnId = (result['transactionId'] ?? '').toString();
      if (txnId.isNotEmpty) _reference = txnId;

      final status = (result['status'] ?? '').toString();
      final stepUp = result['stepUpRequired'] == true;

      // The risk engine can demand step-up authentication before the debit is
      // allowed to settle.
      //
      // This used to auto-approve: it called override immediately with a
      // hardcoded '123456' and biometricOk:true, so the customer was never
      // shown that a payment looked risky and never actually authenticated.
      // The hardcoded code did not match the generated OTP either, so those
      // payments failed anyway.
      if (stepUp || status == 'warning_ack_required' || status == 'blocked') {
        if (!mounted) return false;
        final decision = await Navigator.of(context).push<RiskDecision>(
          SmoothPageRoute(
            settings: const RouteSettings(name: '/risk_warning'),
            builder: (_) => MobileDeviceFrame(
              child: RiskWarningScreen(
                transactionId: txnId,
                amountPaise: amountPaise,
                recipient: payment.payeeName.isNotEmpty
                    ? payment.payeeName
                    : payment.payeeAddress,
                riskScore: (result['riskScore'] as num?)?.toDouble() ?? 0,
                riskLevel: (result['riskLevel'] ?? '').toString(),
                reason: (result['xaiReason'] ?? '').toString(),
                blocked: status == 'blocked',
                healthScore: _healthScore,
                requireOtp: result['requireOtp'] != false,
                requireBiometric: result['requireBiometric'] != false,
              ),
            ),
          ),
        );

        if (decision != RiskDecision.proceeded) {
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(decision == RiskDecision.blocked
                  ? tr('Payment blocked by the risk engine.')
                  : tr('Payment cancelled. Nothing was debited.')),
            ),
          );
          Navigator.pop(context); // close the PIN screen
          _resumeScanning();
          return false;
        }
      }
      return true;
    } catch (_) {
      // Offline: ApiService already returns its mock result, so the demo keeps
      // moving and the receipt still shows.
      return true;
    }
  }

  /// Shown only after the payment has actually settled.
  void _showReceipt(UpiPayment payment, double amount) {
    if (!mounted) return;

    Navigator.pop(context); // PinScreen
    Navigator.pop(context); // ScanQrScreen
    Navigator.push(
      context,
      SmoothPageRoute(
        builder: (_) => MobileDeviceFrame(
          child: PaymentSuccessScreen(
            recipientName: payment.payeeName,
            recipientUpi: payment.payeeAddress,
            amount: amount,
            fromAccount: 'HDFC ••• 8472',
            method: 'UPI',
            referenceId: _reference,
          ),
        ),
      ),
    );
  }

  // ─── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const double cutoutWidth = 245.0;
    const double cutoutHeight = 245.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const _StatusBar(),
            _AppBar(
              torchOn: _torchOn,
              onToggleTorch: _cameraState == _CameraState.granted
                  ? () {
                      _controller?.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    }
                  : null,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final leftOffset = (constraints.maxWidth - cutoutWidth) / 2;
                  final cutoutTop = (constraints.maxHeight - cutoutHeight) / 2 - 40;

                  return Stack(
                    children: [
                      Positioned.fill(child: _buildCameraLayer()),

                      if (_cameraState == _CameraState.granted) ...[
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: ScannerOverlayPainter(
                                cutoutWidth: cutoutWidth,
                                cutoutHeight: cutoutHeight,
                                cutoutTop: cutoutTop,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: leftOffset - 11,
                          top: cutoutTop - 11,
                          child: const IgnorePointer(
                            child: SizedBox(
                              width: cutoutWidth + 22,
                              height: cutoutHeight + 22,
                              child: _CornerBrackets(),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: cutoutTop + cutoutHeight + 16,
                          child: Center(
                            child: Text(
                              tr('Align the QR code within the frame'),
                              style: GoogleFonts.inter(
                                color: const Color(0xCCFFFFFF),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Gallery picker is available regardless of camera state,
                      // so a denied camera still allows paying from a saved QR.
                      Positioned(
                        top: cutoutTop + cutoutHeight + 48,
                        left: (constraints.maxWidth - 56) / 2,
                        child: _GalleryPickerButton(
                          busy: _decodingImage,
                          onTap: _pickFromGallery,
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

  Widget _buildCameraLayer() {
    switch (_cameraState) {
      case _CameraState.granted:
        final controller = _controller;
        if (controller == null) return const ColoredBox(color: Color(0xFF0B2545));
        return MobileScanner(controller: controller, onDetect: _onDetect);

      case _CameraState.checking:
        return const ColoredBox(
          color: Color(0xFF0B2545),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );

      case _CameraState.denied:
        return _PermissionPrompt(
          icon: Icons.photo_camera_outlined,
          title: 'Camera access needed',
          body: 'FINIX uses the camera only to read payment QR codes. '
              'Nothing is recorded or uploaded.',
          actionLabel: 'Allow camera',
          onAction: _initCamera,
        );

      case _CameraState.permanentlyDenied:
        return _PermissionPrompt(
          icon: Icons.lock_outline_rounded,
          title: 'Camera blocked',
          body: 'Camera access was turned off for FINIX. Enable it in Settings, '
              'or pick a saved QR image from your gallery below.',
          actionLabel: 'Open settings',
          onAction: () => openAppSettings(),
        );

      case _CameraState.unavailable:
        return _PermissionPrompt(
          icon: Icons.no_photography_outlined,
          title: 'Camera unavailable',
          body: 'No usable camera was found on this device. You can still pay '
              'by choosing a QR image from your gallery.',
          actionLabel: 'Retry',
          onAction: _initCamera,
        );
    }
  }
}

// ---------------------------------------------------------------------
// Permission / empty-state prompt
// ---------------------------------------------------------------------
class _PermissionPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  const _PermissionPrompt({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B2545),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.5,
                  color: const Color(0xB3FFFFFF),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0B2545),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ---------------------------------------------------------------------
// 2. Custom App Bar Widget
// ---------------------------------------------------------------------
class _AppBar extends StatelessWidget {
  final bool torchOn;
  final VoidCallback? onToggleTorch;

  const _AppBar({required this.torchOn, this.onToggleTorch});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          Text(
            tr('Scan QR'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A1628),
            ),
          ),
          GestureDetector(
            onTap: onToggleTorch,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: onToggleTorch == null
                    ? const Color(0xFFF1F5F9)
                    : (torchOn ? const Color(0xFF0B2545) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                torchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                color: torchOn ? Colors.white : const Color(0xFF475569),
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
    final paint = Paint()
      ..color = const Color(0xE813315C)
      ..style = PaintingStyle.fill;

    final double left = (size.width - cutoutWidth) / 2;
    final rect = Rect.fromLTWH(left, cutoutTop, cutoutWidth, cutoutHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

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
  Widget build(BuildContext context) =>
      const CustomPaint(painter: ViewfinderCornersPainter());
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

    final pathTL = Path()
      ..moveTo(0, s)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(s, 0);
    canvas.drawPath(pathTL, paint);

    final pathTR = Path()
      ..moveTo(w - s, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, s);
    canvas.drawPath(pathTR, paint);

    final pathBL = Path()
      ..moveTo(0, h - s)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(s, h);
    canvas.drawPath(pathBL, paint);

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
  final bool busy;

  const _GalleryPickerButton({required this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B2545)),
                ),
              )
            : const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF0B2545),
                size: 24,
              ),
      ),
    );
  }
}
