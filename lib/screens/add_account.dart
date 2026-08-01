import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  // Select SBI by default
  String _selectedBankId = 'hdfc'; // default to hdfc since SBI is already linked

  bool _isLinking = false;
  bool _isSuccess = false;
  String _linkingStatusText = 'Connecting to NPCI & Sahamati...';

  final List<Map<String, dynamic>> _banks = [
    {
      'id': 'bob',
      'code': 'BoB',
      'name': 'Bank of Baroda',
      'bgColor': const Color(0xFFFFF2E6),
      'textColor': const Color(0xFFD97706),
      'balance': '₹1,45,280',
    },
    {
      'id': 'pnb',
      'code': 'PNB',
      'name': 'Punjab National Bank',
      'bgColor': const Color(0xFFFDF2F8),
      'textColor': const Color(0xFFDB2777),
      'balance': '₹62,150',
    },
    {
      'id': 'can',
      'code': 'CAN',
      'name': 'Canara Bank',
      'bgColor': const Color(0xFFFEF3C7),
      'textColor': const Color(0xFFD97706),
      'balance': '₹98,420',
    },
    {
      'id': 'ubi',
      'code': 'UBI',
      'name': 'Union Bank of India',
      'bgColor': const Color(0xFFE0F2FE),
      'textColor': const Color(0xFF0284C7),
      'balance': '₹43,720',
    },
    {
      'id': 'sbi',
      'code': 'SBI',
      'name': 'State Bank of India',
      'bgColor': const Color(0xFFE6F0F8),
      'textColor': const Color(0xFF0B4F8C),
      'balance': '₹2,87,450',
    },
    {
      'id': 'hdfc',
      'code': 'HDFC',
      'name': 'HDFC Bank',
      'bgColor': const Color(0xFFFFE6E1),
      'textColor': const Color(0xFFB8311C),
      'balance': '₹1,84,720',
    },
    {
      'id': 'icici',
      'code': 'ICICI',
      'name': 'ICICI Bank',
      'bgColor': const Color(0xFFFFF1DE),
      'textColor': const Color(0xFFA8541F),
      'balance': '₹84,250',
    },
  ];

  void _startLinkingFlow() async {
    setState(() {
      _isLinking = true;
      _linkingStatusText = 'Connecting to Sahamati AA consent manager...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _linkingStatusText = 'Requesting secure OTP authentication...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _linkingStatusText = 'Decrypting read-only accounts bundle...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isLinking = false;
      _isSuccess = true;
    });
  }

  void _finishLinking() {
    final selectedBank = _banks.firstWhere((b) => b['id'] == _selectedBankId);
    
    // Construct linked bank metadata to return
    final linkedData = {
      'logoText': selectedBank['code'],
      'logoBgColor': selectedBank['bgColor'],
      'logoTextColor': selectedBank['textColor'],
      'bankName': selectedBank['name'],
      'accountsCount': '1 account',
      'balance': selectedBank['balance'],
    };

    Navigator.pop(context, linkedData);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLinking) {
      return _buildLinkingLoader();
    }

    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            const _AppBar(),

            // 3. Main Content (Scrollable List)
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  // Heading
                  Text(
                    'Which bank\nwould you like to link?',
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0B2545),
                      height: 1.15,
                      letterSpacing: -0.52,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We connect via NPCI · Read-only access · No\npasswords needed',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  const _SearchBar(),

                  const SizedBox(height: 16),

                  // Bank list building
                  ..._banks.map((bank) {
                    final bool isSelected = bank['id'] == _selectedBankId;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBankId = bank['id'] as String;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 13.0),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEEF4FA) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2E75B6) : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Bank Initials Box
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: bank['bgColor'] as Color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  bank['code'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: bank['textColor'] as Color,
                                    letterSpacing: -0.26,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Bank Name
                            Expanded(
                              child: Text(
                                bank['name'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0A1628),
                                ),
                              ),
                            ),
                            // Radio Indicator
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2E75B6) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 6.0 : 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // 4. Sticky Footer Continue CTA Button Widget
            _StickyFooter(onTap: _startLinkingFlow),
          ],
        ),
      ),
    );
  }

  // 1. Linking Progress View
  Widget _buildLinkingLoader() {
    final selectedBank = _banks.firstWhere((b) => b['id'] == _selectedBankId);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _StatusBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Selected Bank Logo Box
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: selectedBank['bgColor'] as Color,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            selectedBank['code'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: selectedBank['textColor'] as Color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Circular Progress
                      const SizedBox(
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B2545)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Heading
                      Text(
                        'Linking your account',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B2545),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Changing audit state logs text
                      Text(
                        _linkingStatusText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Security footnote
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Protected with end-to-end AA cryptography.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
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

  // 2. Account Linked Success Screen
  Widget _buildSuccessScreen() {
    final selectedBank = _banks.firstWhere((b) => b['id'] == _selectedBankId);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const _StatusBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                child: Column(
                  children: [
                    // Checkmark badge rings
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF16A34A).withOpacity(0.06),
                        border: Border.all(
                          color: const Color(0xFF16A34A).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF16A34A),
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Success Heading Text
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B2545),
                          letterSpacing: -0.6,
                        ),
                        children: [
                          const TextSpan(text: 'Account linked\n'),
                          TextSpan(
                            text: 'successfully!',
                            style: GoogleFonts.fraunces(
                              color: const Color(0xFF10B981),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your credentials have been securely registered via NPCI. Access remains strictly read-only and audited.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Account Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LINKED DETAILS',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Row 1: Bank Name
                          _buildDetailRow('Bank', selectedBank['name'] as String),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),

                          // Row 2: Account Number
                          _buildDetailRow('Account No.', 'XXXX XXXX 4920'),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),

                          // Row 3: Account Type
                          _buildDetailRow('Type', 'Savings Account'),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),

                          // Row 4: Access type
                          _buildDetailRow('Access Mode', 'Read-Only (Audited)'),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),

                          // Row 5: Consent duration
                          _buildDetailRow('Consent Duration', '90 Days (Sahamati)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky bottom continue button
            Container(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 13.0, bottom: 24.0),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                ),
              ),
              child: GestureDetector(
                onTap: _finishLinking,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2545),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// 1. Status Bar Widget
// ---------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------
// 2. Custom App Bar Widget
// ---------------------------------------------------------------------
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
          // Back Button
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
          // Title
          Text(
            'Add Account',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          // Info Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF475569),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 3. Search Bar Widget
// ---------------------------------------------------------------------
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
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
              decoration: InputDecoration(
                hintText: 'Search 100+ banks',
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
}

// ---------------------------------------------------------------------
// 4. Sticky Footer Continue CTA Button Widget
// ---------------------------------------------------------------------
class _StickyFooter extends StatelessWidget {
  final VoidCallback onTap;
  const _StickyFooter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 13.0, bottom: 24.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF0B2545),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue ',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
