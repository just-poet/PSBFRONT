import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchIfscScreen extends StatefulWidget {
  const SearchIfscScreen({super.key});

  @override
  State<SearchIfscScreen> createState() => _SearchIfscScreenState();
}

class _SearchIfscScreenState extends State<SearchIfscScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _allBanks = [
    {'name': 'HDFC BANK', 'branch': 'Old Puttur Road', 'ifsc': 'HDFC0002562'},
    {'name': 'ICICI BANK', 'branch': 'MG Road Metro', 'ifsc': 'ICIC0001042'},
    {'name': 'STATE BANK OF INDIA', 'branch': 'Central Plaza', 'ifsc': 'SBIN0004821'},
    {'name': 'AXIS BANK', 'branch': 'Brigade Road', 'ifsc': 'UTIB0000842'},
    {'name': 'KOTAK MAHINDRA BANK', 'branch': 'Indiranagar', 'ifsc': 'KKBK0000429'},
  ];

  List<Map<String, String>> _filteredBanks = [];

  @override
  void initState() {
    super.initState();
    _filteredBanks = List.from(_allBanks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      if (value.isEmpty) {
        _filteredBanks = List.from(_allBanks);
      } else {
        _filteredBanks = _allBanks.where((bank) {
          final q = value.toLowerCase();
          return bank['name']!.toLowerCase().contains(q) ||
              bank['branch']!.toLowerCase().contains(q) ||
              bank['ifsc']!.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

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
            const _AppBar(),

            // 3. Main List Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Input Box
                    _buildSearchBar(),

                    const SizedBox(height: 24),

                    if (_query.isEmpty) ...[
                      // Recent Searches Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('Recent Searches'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0A1628),
                            ),
                          ),
                          Text(
                            tr('Manage'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E75B6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Default Recent Card (HDFC Old Puttur Road)
                      _buildBankCard(
                        name: 'HDFC BANK',
                        branch: 'Old Puttur Road',
                        ifsc: 'HDFC0002562',
                      ),
                    ] else ...[
                      // Filtered Search Results
                      Text(
                        'Search Results (${_filteredBanks.length})',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_filteredBanks.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Text(
                              tr('No banks found.'),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredBanks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bank = _filteredBanks[index];
                            return _buildBankCard(
                              name: bank['name']!,
                              branch: bank['branch']!,
                              ifsc: bank['ifsc']!,
                            );
                          },
                        ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF475569),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search bank, branch, or IFSC',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFAFBACA),
                  letterSpacing: -0.2,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard({
    required String name,
    required String branch,
    required String ifsc,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, ifsc);
      },
      child: Container(
        width: double.infinity,
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  branch,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0x1F2E75B6),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                ifsc,
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0B2545),
                ),
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
            tr('Search for IFSC'),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}
