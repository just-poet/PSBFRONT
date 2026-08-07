import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../services/locale_service.dart';

/// Renders the FINIX privacy policy PDF in-app.
///
/// Settings › Privacy policy previously showed a "Privacy Policy tapped"
/// snackbar. The document ships as an asset and is shown here rather than
/// handed to an external viewer, so it is readable on a device with no PDF app
/// installed and does not leave the app to be read.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({
    super.key,
    this.assetPath = defaultAssetPath,
    this.title = 'Finix privacy policy',
    this.cacheName = 'finix-privacy-policy.pdf',
  });

  /// Bundled at `assets/docs/`. Named as the customer should see it.
  static const String defaultAssetPath =
      'assets/docs/Finix privacy policy.pdf';

  /// Which bundled PDF to render. Terms & conditions reuses this screen.
  final String assetPath;
  final String title;

  /// Filename used in the cache directory; must differ per document or the two
  /// would overwrite each other.
  final String cacheName;

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String? _localPath;
  String? _error;
  int _pages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  /// Copies the asset to a real file.
  ///
  /// Assets live inside the APK and have no filesystem path; the native PDF
  /// view needs one, so the bytes are written to the cache directory once.
  Future<void> _prepare() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.cacheName}');

      // Rewritten each launch: the cache can be cleared by the OS at any time,
      // and the document changes with an app update.
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );

      if (!mounted) return;
      setState(() => _localPath = file.path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
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
                size: 18, color: Color(0xFF0A1628)),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              tr(widget.title),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (_pages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                // Page numbers stay in Latin figures, like every other number
                // in the app.
                '${_currentPage + 1} / $_pages',
                style: GoogleFonts.spaceMono(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined,
                  size: 30, color: Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              Text(
                tr('The policy could not be opened.'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return PDFView(
      filePath: _localPath,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: false,
      onRender: (pages) => setState(() => _pages = pages ?? 0),
      onPageChanged: (page, _) => setState(() => _currentPage = page ?? 0),
      onError: (error) => setState(() => _error = error.toString()),
    );
  }
}
