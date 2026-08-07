import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/locale_service.dart';
import 'ethical_charter_content.dart';

/// Renders the full FINIX Twin Ethical AI Charter.
///
/// Content is generated from FINIX_Ethical_AI_Charter.md.docx into
/// [ethicalCharterDocument] and drawn natively, so it inherits the app theme,
/// respects the system font scale, and is readable on a device with no
/// document viewer installed.
class EthicalCharterDocumentScreen extends StatelessWidget {
  const EthicalCharterDocumentScreen({super.key});

  static const Color _ink = Color(0xFF0A1628);
  static const Color _slate = Color(0xFF334155);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _navy = Color(0xFF0B2545);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: _ink),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      tr('Ethical AI Charter'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                itemCount: ethicalCharterDocument.length,
                itemBuilder: (context, index) {
                  final block = ethicalCharterDocument[index];
                  switch (block.kind) {
                    case CharterKind.heading:
                      return Padding(
                        padding: EdgeInsets.only(
                            top: index == 0 ? 0 : 22, bottom: 8),
                        child: Text(
                          block.text,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _navy,
                            height: 1.35,
                          ),
                        ),
                      );
                    case CharterKind.bullet:
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7, right: 10),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: _muted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                block.text,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  height: 1.65,
                                  color: _slate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    case CharterKind.body:
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          block.text,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.65,
                            color: _slate,
                          ),
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
