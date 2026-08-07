import 'dart:async';
import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';
// main.dart import removed

class DocumentsDownloadScreen extends StatefulWidget {
  const DocumentsDownloadScreen({super.key});

  @override
  State<DocumentsDownloadScreen> createState() => _DocumentsDownloadScreenState();
}

class _DocumentsDownloadScreenState extends State<DocumentsDownloadScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // State to simulate downloading feedback
  final Map<String, bool> _downloadingMap = {};
  bool _downloadingAll = false;

  final List<DocumentItem> _documents = [
    // Loans
    DocumentItem(
      category: 'Loans',
      title: 'Home loan sanction letter',
      subtitle: 'SBI · PDF · 2.4 MB · 12/03/2024',
      icon: Icons.account_balance_rounded,
    ),
    DocumentItem(
      category: 'Loans',
      title: 'Loan statement FY 2025–26',
      subtitle: 'SBI · PDF · 840 KB · 01/04/2026',
      icon: Icons.description_outlined,
    ),
    DocumentItem(
      category: 'Loans',
      title: 'Amortisation schedule',
      subtitle: 'SBI · PDF · 1.1 MB · 01/04/2026',
      icon: Icons.table_chart_outlined,
    ),
    DocumentItem(
      category: 'Loans',
      title: 'No-objection certificate',
      subtitle: 'Requested 22/07/2026 · ready in 3 days',
      icon: Icons.access_time_rounded,
      isAwaiting: true,
    ),
    // Insurance
    DocumentItem(
      category: 'Insurance',
      title: 'LIC Jeevan Anand — policy',
      subtitle: 'Policy ●●●●4471 · PDF · 3.2 MB',
      icon: Icons.shield_outlined,
    ),
    DocumentItem(
      category: 'Insurance',
      title: 'Star Health family floater',
      subtitle: 'Policy ●●●●9012 · PDF · 1.8 MB',
      icon: Icons.favorite_border_rounded,
    ),
    DocumentItem(
      category: 'Insurance',
      title: 'Premium receipt FY 2025–26',
      subtitle: 'LIC · PDF · 210 KB · 10/05/2026',
      icon: Icons.receipt_long_outlined,
    ),
    // Investments
    DocumentItem(
      category: 'Investments',
      title: 'Consolidated account statement',
      subtitle: 'CAMS · PDF · 640 KB · 30/06/2026',
      icon: Icons.trending_up_rounded,
    ),
    DocumentItem(
      category: 'Investments',
      title: 'SIP mandate — HDFC Bluechip',
      subtitle: 'NACH · PDF · 180 KB · 05/01/2025',
      icon: Icons.description_outlined,
    ),
    DocumentItem(
      category: 'Investments',
      title: 'Demat holding statement',
      subtitle: 'NSDL · PDF · 390 KB · 30/06/2026',
      icon: Icons.pie_chart_outline_rounded,
    ),
    // Tax
    DocumentItem(
      category: 'Tax',
      title: 'Form 16 — FY 2025–26',
      subtitle: 'Employer · PDF · 420 KB · 15/06/2026',
      icon: Icons.description_outlined,
    ),
    DocumentItem(
      category: 'Tax',
      title: 'Capital gains statement',
      subtitle: 'CAMS · PDF · 320 KB · 30/06/2026',
      icon: Icons.bar_chart_rounded,
    ),
    DocumentItem(
      category: 'Tax',
      title: '80C proof bundle',
      subtitle: '8 files · ZIP · 4.7 MB · 12/07/2026',
      icon: Icons.folder_zip_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to start a simulated download animation
  void _startDownload(DocumentItem item) {
    if (item.isAwaiting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.title} is pending issuer release.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _downloadingMap[item.title] = true;
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _downloadingMap[item.title] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.title} downloaded successfully!'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _downloadAll() {
    setState(() {
      _downloadingAll = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _downloadingAll = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All documents compressed & downloaded as ZIP!'),
            backgroundColor: Color(0xFF16A34A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter documents based on query and selected category
    List<DocumentItem> filteredList = _documents.where((doc) {
      // Check query match
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          doc.title.toLowerCase().contains(query) ||
          doc.subtitle.toLowerCase().contains(query) ||
          doc.category.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      // Check category match
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Statements') {
        return doc.title.toLowerCase().contains('statement') ||
            doc.title.toLowerCase().contains('schedule') ||
            doc.title.toLowerCase().contains('receipt');
      }
      return doc.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    // Group filtered items by category for rendering sections
    final Map<String, List<DocumentItem>> groupedDocs = {};
    for (var doc in filteredList) {
      final key = _selectedCategory == 'Statements' ? 'Statements' : doc.category;
      groupedDocs.putIfAbsent(key, () => []).add(doc);
    }

    // Dynamic counts
    int totalCount = filteredList.length;
    int awaitingCount = filteredList.where((doc) => doc.isAwaiting).length;
    // Calculate sources: count distinct providers in filtered results
    int sourcesCount = filteredList.map((doc) {
      final parts = doc.subtitle.split('·');
      return parts.isNotEmpty ? parts[0].trim() : '';
    }).where((s) => s.isNotEmpty).toSet().length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            const _StatusBar(),

            // Custom AppBar
            _buildAppBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Search bar
                    _buildSearchBar(),
                    const SizedBox(height: 12),

                    // Summary Strip (DOCUMENTS, SOURCES, AWAITING)
                    _buildSummaryStrip(
                      totalCount: totalCount,
                      sourcesCount: sourcesCount,
                      awaitingCount: awaitingCount,
                    ),
                    const SizedBox(height: 16),

                    // Horizontal Filter Chips
                    _buildFilterChips(),
                    const SizedBox(height: 8),

                    // Document List grouped under Cards
                    if (filteredList.isEmpty)
                      _buildEmptyState()
                    else
                      ...groupedDocs.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildSectionHeader(entry.key.toUpperCase()),
                            const SizedBox(height: 8),
                            _buildCategoryCard(entry.value),
                          ],
                        );
                      }),

                    const SizedBox(height: 24),

                    // Verified Log notice card
                    _buildNoticeCard(),
                    const SizedBox(height: 24),

                    // Download all as ZIP button
                    _buildDownloadAllButton(),
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

  // App Bar
  Widget _buildAppBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Back Button
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
          Expanded(
            child: Center(
              child: Text(
                tr('Documents'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          // Download All icon button
          GestureDetector(
            onTap: _downloadingAll ? null : _downloadAll,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: _downloadingAll
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B2545)),
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        color: Color(0xFF475569),
                        size: 16,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0A1628),
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 18,
          ),
          hintText: 'Search by name, lender or policy',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                  },
                  child: const Icon(
                    Icons.clear_rounded,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // Summary Strip Widget (with beautiful counters)
  Widget _buildSummaryStrip({
    required int totalCount,
    required int sourcesCount,
    required int awaitingCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('$totalCount', 'DOCUMENTS'),
          Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
          _buildSummaryItem('$sourcesCount', 'SOURCES'),
          Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
          _buildSummaryItem('$awaitingCount', 'AWAITING'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String number, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF0B2545),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
              letterSpacing: 0.315,
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal Filter Chips
  Widget _buildFilterChips() {
    final categories = ['All', 'Loans', 'Insurance', 'Investments', 'Tax', 'Statements'];
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                }
              },
              selectedColor: const Color(0xFF0B2545),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0B2545) : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  // Section header (e.g. LOANS, INSURANCE)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
          letterSpacing: 0.99,
        ),
      ),
    );
  }

  // Category card containing filtered documents
  Widget _buildCategoryCard(List<DocumentItem> docs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(docs.length, (index) {
          final doc = docs[index];
          final isLast = index == docs.length - 1;
          final isDownloading = _downloadingMap[doc.title] ?? false;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    // Icon (either standard blue or orange awaiting)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: doc.isAwaiting
                            ? const Color(0xFFF59E0B).withOpacity(0.1)
                            : const Color(0xFFEEF4FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          doc.icon,
                          color: doc.isAwaiting
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF0B2545),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Document text titles
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0A1628),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            doc.subtitle,
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Download button (or progress/orange clock if awaiting)
                    GestureDetector(
                      onTap: () => _startDownload(doc),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: doc.isAwaiting
                              ? const Color(0xFFF59E0B).withOpacity(0.1)
                              : const Color(0xFFEEF4FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: isDownloading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B2545)),
                                  ),
                                )
                              : Icon(
                                  doc.isAwaiting
                                      ? Icons.access_time_rounded
                                      : Icons.download_rounded,
                                  color: doc.isAwaiting
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF0B2545),
                                  size: 17,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                  indent: 14,
                  endIndent: 14,
                ),
            ],
          );
        }),
      ),
    );
  }

  // Notice/Warning Log card
  Widget _buildNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF2E75B6),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Every download is logged\n',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const TextSpan(text: 'Files marked '),
                  TextSpan(
                    text: tr('Verified'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B2545),
                    ),
                  ),
                  const TextSpan(
                    text: ' came straight from the issuer through Account Aggregator. Each download writes an entry to your audit log.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Download all as ZIP button
  Widget _buildDownloadAllButton() {
    return GestureDetector(
      onTap: _downloadingAll ? null : _downloadAll,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0B2545)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _downloadingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B2545)),
                    ),
                  )
                : const Icon(
                    Icons.download_rounded,
                    color: Color(0xFF0B2545),
                    size: 17,
                  ),
            const SizedBox(width: 8),
            Text(
              tr('Download all as ZIP'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0B2545),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state when filters match nothing
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_off_outlined,
            color: Color(0xFF94A3B8),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            tr('No documents found'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching for another keyword or select a different filter category.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Status Bar Widget
// ---------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// Custom model representing each document row
class DocumentItem {
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAwaiting;

  DocumentItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAwaiting = false,
  });
}
