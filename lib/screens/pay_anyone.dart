import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pin_screen.dart';
import '../main.dart';
import 'payment_success.dart';

class PayAnyoneScreen extends StatefulWidget {
  const PayAnyoneScreen({super.key});

  static void showPaymentBottomSheet(BuildContext context, String name, String upiId) {
    final textController = TextEditingController(text: '1000'); // default amount

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
                'Pay to Contact',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A1628),
                ),
              ),
              const SizedBox(height: 12),
              // Contact detail Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF4FA),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B2545),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          upiId,
                          style: const TextStyle(
                            fontFamily: 'Geist_Mono',
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Amount label
              Text(
                'ENTER AMOUNT',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.66,
                ),
              ),
              const SizedBox(height: 8),
              // Input field
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Text(
                      '₹',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: GoogleFonts.fraunces(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
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
              // Pay CTA button
              GestureDetector(
                onTap: () {
                  final amountText = textController.text.trim();
                  final amount = double.tryParse(amountText) ?? 0.0;
                  if (amount <= 0) return;

                  Navigator.pop(context); // close bottom sheet

                  // Push PIN screen
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      builder: (context) => MobileDeviceFrame(
                        child: PinScreen(
                          title: 'Enter your 6-digit PIN',
                          subtitle: 'Paying to $name',
                          amount: amount,
                          onSuccess: () {
                            Navigator.pop(context); // Pop PinScreen
                            Navigator.pop(context); // Pop PayAnyoneScreen
                            Navigator.push(
                              context,
                              SmoothPageRoute(
                                builder: (context) => MobileDeviceFrame(
                                  child: PaymentSuccessScreen(
                                    recipientName: name,
                                    recipientUpi: upiId,
                                    amount: amount,
                                    fromAccount: 'HDFC ••• 8472',
                                    method: 'UPI Pay',
                                    referenceId: 'UPI${(100000 + (amount * 99).toInt()).toString()}XQ${(100 + (amount % 899).toInt()).toString()}',
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
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2545),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Pay Securely →',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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
  State<PayAnyoneScreen> createState() => _PayAnyoneScreenState();
}

class _PayAnyoneScreenState extends State<PayAnyoneScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _recents = [
    {
      'initials': 'RS',
      'name': 'Rohan',
      'gradient': const [Color(0xFF2E75B6), Color(0xFF0B2545)]
    },
    {
      'initials': 'PM',
      'name': 'Priya',
      'gradient': const [Color(0xFFC8A951), Color(0xFF8E7733)]
    },
    {
      'initials': 'AK',
      'name': 'Amit',
      'gradient': const [Color(0xFF12A34A), Color(0xFF14532D)]
    },
    {
      'initials': 'NV',
      'name': 'Neha',
      'gradient': const [Color(0xFFDC2626), Color(0xFF7F1D1D)]
    },
    {
      'initials': 'RK',
      'name': 'Ravi',
      'gradient': const [Color(0xFF2E75B6), Color(0xFF0B2545)]
    },
    {
      'initials': 'SS',
      'name': 'Sneha',
      'gradient': const [Color(0xFFF59E0B), Color(0xFF92400E)]
    },
  ];

  final List<Map<String, String>> _allContacts = [
    {
      'initials': 'RS',
      'name': 'Rohan Sharma',
      'upiId': 'rohan.sharma@okhdfcbank'
    },
    {
      'initials': 'PM',
      'name': 'Angel Priya',
      'upiId': 'priyam@ybl'
    },
    {
      'initials': 'AK',
      'name': 'Arjun Chauhan',
      'upiId': '9876543210@upi'
    },
    {
      'initials': 'NV',
      'name': 'Neha Verma',
      'upiId': 'nehaverma@okaxis'
    },
    {
      'initials': 'RK',
      'name': 'RaviKrishnan G',
      'upiId': 'ravi.k@paytm'
    },
    {
      'initials': 'SS',
      'name': 'Sneha Reddy',
      'upiId': 'snehas@okicici'
    },
  ];

  List<Map<String, String>> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = List.from(_allContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _query = val;
      if (val.isEmpty) {
        _filteredContacts = List.from(_allContacts);
      } else {
        final q = val.toLowerCase();
        _filteredContacts = _allContacts.where((c) {
          return c['name']!.toLowerCase().contains(q) ||
              c['upiId']!.toLowerCase().contains(q);
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
                    // Search Bar
                    _buildSearchBar(),

                    const SizedBox(height: 20),

                    if (_query.isEmpty) ...[
                      // Recent Section Title
                      Text(
                        'Recent',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Recents List
                      _buildRecentsList(),

                      const SizedBox(height: 28),
                    ],

                    // All Contacts Section Title
                    Text(
                      _query.isEmpty ? 'All contacts' : 'Search Results (${_filteredContacts.length})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vertical Contacts List
                    _buildAllContactsList(),

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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF475569),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search name, mobile, or UPI ID',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
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

  Widget _buildRecentsList() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recents.length,
        itemBuilder: (context, index) {
          final item = _recents[index];
          return GestureDetector(
            onTap: () => PayAnyoneScreen.showPaymentBottomSheet(
              context,
              item['name'] as String,
              '${(item['name'] as String).toLowerCase()}@upi',
            ),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 14.0),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: item['gradient'] as List<Color>,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        item['initials'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A1628),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllContactsList() {
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Text(
            'No contacts found.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return GestureDetector(
          onTap: () => PayAnyoneScreen.showPaymentBottomSheet(
            context,
            contact['name']!,
            contact['upiId']!,
          ),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 21.0, vertical: 13.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF4FA),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      contact['initials']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B2545),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact['upiId']!,
                        style: const TextStyle(
                          fontFamily: 'Geist_Mono',
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
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
            'Pay Anyone',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
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
