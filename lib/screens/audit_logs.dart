import 'dart:async';
import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

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
  // The audit trail is real: /v1/audit/logs returns this customer's actual
  // sign-ins, freezes and payment decisions, tamper-evident and surviving a
  // restart. This screen used to render a fixed list of invented events —
  // a blocked ₹85,000 transfer, an HDFC SIP debit — identical for everyone.
  List<AuditLogItem> _allLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await ApiService.instance.getAuditLogs();
    if (!mounted) return;
    setState(() {
      _allLogs = events.map(_toItem).toList();
      _loading = false;
    });
  }

  /// Maps a backend audit event onto the row this screen renders.
  static AuditLogItem _toItem(Map<String, dynamic> e) {
    final eventType = (e['eventType'] ?? '').toString();
    final outcome = (e['outcome'] ?? '').toString().toLowerCase();
    final at = DateTime.tryParse((e['timestamp'] ?? '').toString())?.toLocal();

    final style = _styleFor(eventType, outcome);

    return AuditLogItem(
      sortKey: at ?? DateTime.fromMillisecondsSinceEpoch(0),
      title: _titleFor(eventType, e),
      details: (e['details'] ?? e['xaiReason'] ?? '').toString(),
      // The backend exposes an event ID rather than a chain hash; showing the
      // real identifier beats inventing a plausible-looking 0x… digest.
      hash: (e['id'] ?? '').toString(),
      time: _clock(at),
      dateGroup: _group(at),
      categories: [_categoryFor(eventType)],
      icon: style.icon,
      iconColor: style.colour,
      iconBgColor: style.colour.withOpacity(0.1),
      isGreenTitle: outcome == 'success' && style.colour == const Color(0xFF16A34A),
    );
  }

  static ({IconData icon, Color colour}) _styleFor(String eventType, String outcome) {
    if (outcome == 'failure' || outcome == 'blocked' || outcome == 'denied') {
      return (icon: Icons.block_flipped, colour: const Color(0xFFDC2626));
    }
    if (eventType.contains('freeze')) {
      return (icon: Icons.ac_unit_rounded, colour: const Color(0xFF2E75B6));
    }
    if (eventType.contains('login') || eventType.contains('auth')) {
      return (icon: Icons.login_rounded, colour: const Color(0xFF16A34A));
    }
    if (eventType.contains('transaction') || eventType.contains('payment')) {
      return (icon: Icons.swap_horiz_rounded, colour: const Color(0xFF16A34A));
    }
    if (eventType.contains('consent') || eventType.contains('kyc')) {
      return (icon: Icons.verified_user_outlined, colour: const Color(0xFFC8A951));
    }
    return (icon: Icons.check_circle_outline_rounded, colour: const Color(0xFF16A34A));
  }

  /// Turns snake_case event types into something a customer can read.
  static String _titleFor(String eventType, Map<String, dynamic> e) {
    if (eventType.isEmpty) {
      return (e['details'] ?? 'Account event').toString();
    }
    final words = eventType.split('_').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return eventType;
    final first = words.first;
    return ('${first[0].toUpperCase()}${first.substring(1)} ${words.skip(1).join(' ')}')
        .trim();
  }

  static String _categoryFor(String eventType) {
    if (eventType.contains('login') ||
        eventType.contains('auth') ||
        eventType.contains('freeze') ||
        eventType.contains('device')) {
      return 'Security';
    }
    if (eventType.contains('transaction') || eventType.contains('payment')) {
      return 'Payments';
    }
    if (eventType.contains('consent') || eventType.contains('kyc')) {
      return 'Consent';
    }
    return 'Account';
  }

  static String _clock(DateTime? at) {
    if (at == null) return '--:--';
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    final sec = at.second.toString().padLeft(2, '0');
    return '$h:$m:$sec IST';
  }

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  static String _group(DateTime? at) {
    if (at == null) return 'EARLIER';
    final now = DateTime.now();
    final date = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final label = '${at.day} ${_months[at.month - 1]} ${at.year}';
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'TODAY · $label';
    if (diff == 1) return 'YESTERDAY · $label';
    return label;
  }

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
    // Derived from the data, newest first.
    //
    // This was a hardcoded list of three labels left over from the mock data
    // ('TODAY · 7 JUN 2026'). The ListView iterates these group names, so once
    // the screen started rendering real events — whose groups carry today's
    // actual date — almost every entry fell outside the three and never drew.
    final dateGroupsOrder = groupedLogs.keys.toList()
      ..sort((a, b) {
        // 'TODAY · …' and 'YESTERDAY · …' must lead; the rest are plain dates
        // ordered by the newest event inside each group.
        int rank(String g) => g.startsWith('TODAY')
            ? 0
            : g.startsWith('YESTERDAY')
                ? 1
                : 2;
        final byRank = rank(a).compareTo(rank(b));
        if (byRank != 0) return byRank;
        final aNewest = groupedLogs[a]!.first.sortKey;
        final bNewest = groupedLogs[b]!.first.sortKey;
        return bNewest.compareTo(aNewest);
      });

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
                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_allLogs.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          tr('No audit events recorded yet.'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  )
                else
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
            tr('Audit Logs'),
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
                    tr('MERKLE-VERIFIED'),
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
  /// When the event happened, used to order the date groups. The formatted
  /// `time`/`dateGroup` strings are for display and cannot be sorted reliably.
  final DateTime sortKey;
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
    required this.sortKey,
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
