import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/contact_service.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_acknowledgement.dart';
import '../main.dart';

class ReportFraudScreen extends StatefulWidget {
  const ReportFraudScreen({super.key});

  @override
  State<ReportFraudScreen> createState() => _ReportFraudScreenState();
}

class _ReportFraudScreenState extends State<ReportFraudScreen> {
  String? _uploadedEvidenceFile;
  String _uploadStatus = 'Uploading document...';
  String _selectedCategory = 'UPI Fraud';
  final TextEditingController _descController = TextEditingController();
  bool _forwardToCybercrime = false;

  final List<String> _categories = [
    'UPI Fraud',
    'Credit Card Fraud',
    'Debit Card Fraud',
    'Net Banking Fraud',
    'Identity Theft',
    'Other'
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submitReport() {
    Navigator.pushReplacement(
      context,
      SmoothPageRoute(
        settings: const RouteSettings(name: '/report_acknowledgement'),
        builder: (context) => const MobileDeviceFrame(child: ReportAcknowledgementScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Heading
                    Text(
                      tr('Category'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A1628), // color/text/ink
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown Field
                    _buildCategoryDropdown(),
                    const SizedBox(height: 18),

                    // Description Heading
                    Text(
                      tr('Description'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description Field
                    _buildDescriptionField(),
                    const SizedBox(height: 18),

                    // Evidence Heading
                    Text(
                      tr('Evidence'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Evidence Upload Card (Dashed Border)
                    _buildUploadArea(),
                    const SizedBox(height: 24),

                    // Checkbox Row
                    _buildCheckboxRow(),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Left back arrow
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
          // Title
          Expanded(
            child: Center(
              child: Text(
                tr('Report Fraud'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          // Spacer
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF94A3B8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF0A1628),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0A1628),
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
          items: _categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      width: double.infinity,
      height: 115,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF94A3B8)),
      ),
      child: TextField(
        controller: _descController,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF0A1628),
        ),
        decoration: InputDecoration(
          hintText: 'Describe what happened...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF475569).withOpacity(0.68),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    if (_uploadedEvidenceFile != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF16A34A)),
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
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uploadedEvidenceFile!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr('Attached successfully'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
              onPressed: () {
                setState(() {
                  _uploadedEvidenceFile = null;
                });
              },
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _simulateUpload,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFF94A3B8),
          strokeWidth: 1.0,
          gap: 4.0,
          dash: 6.0,
          borderRadius: 10.0,
        ),
        child: Container(
          width: double.infinity,
          height: 107,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: Color(0xFF475569),
                size: 31,
              ),
              const SizedBox(height: 9),
              Text(
                tr('Upload screenshot or receipt'),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A1628).withOpacity(0.46),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simulateUpload() {
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
                tr('Upload Evidence File'),
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
                  decoration: const BoxDecoration(color: Color(0xFFEEF4FA), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0B2545)),
                ),
                title: Text(
                  tr('Take Photo / Screenshot'),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0A1628)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startUploadFlow('screenshot_upi_receipt.jpg');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFEEF4FA), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF0B2545)),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0A1628)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startUploadFlow('transaction_evidence.png');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFEEF4FA), shape: BoxShape.circle),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF0B2545)),
                ),
                title: Text(
                  tr('Upload PDF / Statement'),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0A1628)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startUploadFlow('bank_statement_dec2025.pdf');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startUploadFlow(String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (dialogContext.mounted) {
                setDialogState(() {
                  _uploadStatus = 'Analyzing file integrity...';
                });
              }
            });
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (dialogContext.mounted) {
                setDialogState(() {
                  _uploadStatus = 'Extracting transaction references...';
                });
              }
            });
            Future.delayed(const Duration(milliseconds: 1800), () {
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                setState(() {
                  _uploadedEvidenceFile = fileName;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF16A34A),
                    content: Text(
                      'Evidence file attached: $fileName',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }
            });

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B2545)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      tr('Attaching Evidence'),
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _uploadStatus,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    _uploadStatus = 'Uploading evidence...';
  }

  Widget _buildCheckboxRow() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _forwardToCybercrime = !_forwardToCybercrime;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF475569)),
            ),
            child: _forwardToCybercrime
                ? const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFF0B2545),
                      size: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(text: tr('Forward to National Cybercrime Portal ( ')),
                  // Tapping the helpline opens the dialer: someone reporting a
                  // fraud should not have to memorise digits and retype them.
                  TextSpan(
                    text: FinixContacts.cyberCrimeHelpline,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E75B6),
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => FinixLauncher.dial(
                          context, FinixContacts.cyberCrimeHelpline),
                  ),
                  const TextSpan(text: ' )'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submitReport,
      child: Container(
        width: 306,
        height: 45,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF13315C), Color(0xFF2867C2)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.499, 0.727],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            tr('Submit report'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFF8FAFC),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Dashed Border Painter
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0;
    bool draw = true;

    for (var measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        final length = draw ? dash : gap;
        dashPath.addPath(
          measurePath.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
