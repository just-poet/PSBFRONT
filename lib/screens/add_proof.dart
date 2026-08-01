import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProofScreen extends StatefulWidget {
  const AddProofScreen({super.key});

  @override
  State<AddProofScreen> createState() => _AddProofScreenState();
}

class _AddProofScreenState extends State<AddProofScreen> {
  String? _uploadedFileName;
  String _uploadStatus = 'Uploading document...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                    // Status Card (80C Declared)
                    _buildStatusCard(),
                    const SizedBox(height: 24),

                    // Section Heading: Deduction sections
                    Text(
                      'Deduction sections',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Deduction Sections List
                    _buildDeductionsList(context),
                    const SizedBox(height: 24),

                    // Upload Button
                    _buildUploadButton(context),
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

  // Custom App Bar
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Title
          Text(
            'Add Proof',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.15,
            ),
          ),

          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
            ),
          ),

          // Right ghost spacer to maintain title alignment
          const Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 34,
              height: 34,
            ),
          ),
        ],
      ),
    );
  }

  // Status Card (80C Declared)
  Widget _buildStatusCard() {
    const double claimedVal = 110000;
    const double totalVal = 150000;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.06),
            blurRadius: 1.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '80C DECLARED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹1,10,000',
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF0B2545),
                  letterSpacing: -0.52,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'of ₹1,50,000',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: claimedVal / totalVal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E75B6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹40,000 room left to claim',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E75B6),
            ),
          ),
        ],
      ),
    );
  }

  // Deductions List
  Widget _buildDeductionsList(BuildContext context) {
    return Column(
      children: [
        // 80C · ELSS, PF, LIC
        _buildDeductionTile(
          icon: Icons.done,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFF16A34A).withOpacity(0.1),
          title: '80C · ELSS, PF,\nLIC',
          description: '₹1,10,000 · 3\nproofs',
          badgeText: 'Partial',
          badgeColor: const Color(0xFF16A34A),
          badgeBgColor: const Color(0xFF16A34A).withOpacity(0.1),
        ),
        const SizedBox(height: 12),

        // 80D · Health premium
        _buildDeductionTile(
          icon: Icons.done,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFF16A34A).withOpacity(0.1),
          title: '80D · Health\npremium',
          description: '₹25,000 · 1 proof',
          badgeText: 'Done',
          badgeColor: const Color(0xFF16A34A),
          badgeBgColor: const Color(0xFF16A34A).withOpacity(0.1),
        ),
        const SizedBox(height: 12),

        // 80EEA · Home loan interest
        _buildDeductionTile(
          icon: Icons.file_upload_outlined,
          iconColor: const Color(0xFF2E75B6),
          iconBgColor: const Color(0xFFEEF4FA),
          title: '80EEA · Home loan\ninterest',
          description: _uploadedFileName != null ? '1 proof uploaded' : 'No proof uploaded',
          badgeText: _uploadedFileName != null ? 'Done' : 'Add',
          badgeColor: _uploadedFileName != null ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
          badgeBgColor: _uploadedFileName != null
              ? const Color(0xFF16A34A).withOpacity(0.1)
              : const Color(0xFFF59E0B).withOpacity(0.1),
        ),
        const SizedBox(height: 12),

        // HRA · Rent receipts
        _buildDeductionTile(
          icon: Icons.file_upload_outlined,
          iconColor: const Color(0xFF2E75B6),
          iconBgColor: const Color(0xFFEEF4FA),
          title: 'HRA · Rent receipts',
          description: 'No proof uploaded',
          badgeText: 'Add',
          badgeColor: const Color(0xFFF59E0B),
          badgeBgColor: const Color(0xFFF59E0B).withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildDeductionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
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
                    height: 1.25,
                    letterSpacing: -0.14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 9.0),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                badgeText,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                  letterSpacing: 0.105,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Upload Button & Simulation
  Widget _buildUploadButton(BuildContext context) {
    if (_uploadedFileName != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF16A34A)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uploadedFileName!,
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
                    'Uploaded successfully • verified by AI',
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
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
              onPressed: () {
                setState(() {
                  _uploadedFileName = null;
                });
              },
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _simulateUpload(context),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF0B2545),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '+ Upload a proof',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _simulateUpload(BuildContext context) {
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
                'Upload Proof Document',
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
                  'Take Photo / Scan',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0A1628)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startUploadFlow('scanned_receipt_80c.jpg');
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
                  _startUploadFlow('tax_declaration_proof.png');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFEEF4FA), shape: BoxShape.circle),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF0B2545)),
                ),
                title: Text(
                  'Upload PDF / Document',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0A1628)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startUploadFlow('HDFC_home_loan_interest_cert_FY26.pdf');
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
                  _uploadStatus = 'Verifying signature & authenticating...';
                });
              }
            });
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (dialogContext.mounted) {
                setDialogState(() {
                  _uploadStatus = 'Parsing document contents with AI...';
                });
              }
            });
            Future.delayed(const Duration(milliseconds: 1800), () {
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                setState(() {
                  _uploadedFileName = fileName;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF16A34A),
                    content: Text(
                      'Successfully uploaded: $fileName',
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
                      'Uploading File',
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

    _uploadStatus = 'Uploading document...';
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
