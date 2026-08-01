import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  // Active filter category
  String _activeCategory = 'All';

  // Downloading simulation state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // Mock Audit Log Data Model
  final List<AuditLogItem> _allLogs = [
    AuditLogItem(
      title: 'Transaction blocked by Risk Engine',
      details: '₹85,000 to +91 98765 ••• 340 · Risk 78 / 100',
      hash: '0x9b2c...4a7f',
      time: '02:14:32 IST',
      dateGroup: 'TODAY · 7 JUN 2026',
      categories: ['Payments'],
      icon: Icons.block_flipped,
      iconColor: const Color(0xFFDC2626),
      iconBgColor: const Color(0xFFDC2626).withOpacity(0.1),
    ),
    AuditLogItem(
      title: 'SIP debit successful',
      details: 'HDFC Bluechip · ₹5,000 · Ref HDFC8472',
      hash: '0x6d4e...8c1b',
      time: '10:00:14 IST',
      dateGroup: 'TODAY · 7 JUN 2026',
      categories: ['Payments'],
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF16A34A),
      iconBgColor: const Color(0xFF16A34A).withOpacity(0.1),
    ),
    AuditLogItem(
      title: 'Biometric login',
      details: 'Face ID · iPhone 14 Pro · Mumbai',
      hash: '0x1f8a...d293',
      time: '09:41:08 IST',
      dateGroup: 'TODAY · 7 JUN 2026',
      categories: ['Security'],
      icon: Icons.face_unlock_rounded,
      iconColor: const Color(0xFF2E75B6),
      iconBgColor: const Color(0xFFEEF4FA),
    ),
    AuditLogItem(
      title: 'Suspicious SMS flagged',
      details: 'Sender +91 98765 ••• 210 · 6 risk signals',
      hash: '0x3c5e...91ff',
      time: '23:20:55 IST',
      dateGroup: 'YESTERDAY · 6 JUN 2026',
      categories: ['Security'],
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFF59E0B),
      iconBgColor: const Color(0xFFF59E0B).withOpacity(0.1),
    ),
    AuditLogItem(
      title: 'PSB account synced via VA',
      details: '6 transactions imported · Read-only consent',
      hash: '0x4a7b...62de',
      time: '16:32:11 IST',
      dateGroup: 'YESTERDAY · 6 JUN 2026',
      categories: ['Account', 'Consent'],
      icon: Icons.credit_card_outlined,
      iconColor: const Color(0xFF475569),
      iconBgColor: const Color(0xFFF1F5F9),
    ),
    AuditLogItem(
      title: 'Health score updated',
      details: '758 → 782 · Liquidity pillar improved',
      hash: '0x8e3d...07ac',
      time: '04:00:00 IST',
      dateGroup: 'YESTERDAY · 6 JUN 2026',
      categories: ['Account', 'Security'],
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFF16A34A),
      iconBgColor: const Color(0xFF16A34A).withOpacity(0.1),
      isGreenTitle: true,
      scoreValue: '+24',
    ),
    AuditLogItem(
      title: 'Consent renewed · Axis Bank',
      details: 'Account Aggregator · Valid for 90 days',
      hash: '0x2b9f...e431',
      time: '05 Jun · 11:24',
      dateGroup: 'EARLIER THIS WEEK',
      categories: ['Consent'],
      icon: Icons.assignment_turned_in_outlined,
      iconColor: const Color(0xFF2E75B6),
      iconBgColor: const Color(0xFFEEF4FA),
    ),
  ];

  // Helper to trigger simulated download
  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _downloadProgress += 0.1;
        if (_downloadProgress >= 1.0) {
          timer.cancel();
          _isDownloading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Audit Log PDF saved to Downloads folder.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtered logs
    final filteredLogs = _allLogs.where((log) {
      if (_activeCategory == 'All') return true;
      return log.categories.contains(_activeCategory);
    }).toList();

    // Group logs by Date Group
    final Map<String, List<AuditLogItem>> groupedLogs = {};
    for (var log in filteredLogs) {
      groupedLogs.putIfAbsent(log.dateGroup, () => []).add(log);
    }

    // Standard group ordering
    final dateGroupsOrder = [
      'TODAY · 7 JUN 2026',
      'YESTERDAY · 6 JUN 2026',
      'EARLIER THIS WEEK'
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar (Figma node 640:5011)
                _buildAppBar(context),

                // Merkle-verified Status Banner (Figma node 640:5018)
                _buildMerkleBanner(),

                // Category Pills Section (Figma node 640:5026)
                _buildCategoryPills(),

                // Grouped Scroll View (Figma node 640:5037)
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    itemCount: dateGroupsOrder.length,
                    itemBuilder: (context, index) {
                      final groupName = dateGroupsOrder[index];
                      final logsInGroup = groupedLogs[groupName] ?? [];
                      if (logsInGroup.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date group title
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
                            child: Text(
                              groupName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          // Log items inside group
                          Column(
                            children: logsInGroup.map((log) => _buildLogCard(log)).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            // Downloading Progress Overlay
            if (_isDownloading) _buildDownloadOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF475569),
                  size: 16,
                ),
              ),
            ),
          ),
          // Center title
          Text(
            'Audit Logs',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.16,
            ),
          ),
          // Right download button
          GestureDetector(
            onTap: _startDownload,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.download_rounded,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerkleBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF16A34A),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MERKLE-VERIFIED',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF16A34A),
                      letterSpacing: 0.66,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Last hash: 0x7f3a...e891',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    final categories = ['All', 'Security', 'Payments', 'Account', 'Consent'];
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final bool isSelected = _activeCategory == cat;
          
          // Display count for the selected category pill matching Figma
          String displayLabel = cat;
          if (cat == 'All') {
            displayLabel = 'All · 28';
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategory = cat;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 0.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0B2545) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0B2545) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                displayLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(AuditLogItem log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: log.iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(log.icon, color: log.iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            // Body Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          log.title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                      ),
                      if (log.scoreValue != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          log.scoreValue!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: log.isGreenTitle ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Details
                  Text(
                    log.details,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Divider and Hash/Time row
                  Container(
                    padding: const EdgeInsets.only(top: 9.0),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          log.hash,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          log.time,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: const Color(0xFF0B2545),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Generating PDF Report...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B2545),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we compile the ledger logs.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuditLogItem {
  final String title;
  final String details;
  final String hash;
  final String time;
  final String dateGroup;
  final List<String> categories;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isGreenTitle;
  final String? scoreValue;

  const AuditLogItem({
    required this.title,
    required this.details,
    required this.hash,
    required this.time,
    required this.dateGroup,
    required this.categories,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.isGreenTitle = false,
    this.scoreValue,
  });
}
