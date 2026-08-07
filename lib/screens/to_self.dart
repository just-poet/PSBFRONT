import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'linked_accounts.dart';

import 'pin_screen.dart';
import '../main.dart';
import 'payment_success.dart';

class ToSelfTransferScreen extends StatefulWidget {
  const ToSelfTransferScreen({super.key});

  @override
  State<ToSelfTransferScreen> createState() => _ToSelfTransferScreenState();
}

class _ToSelfTransferScreenState extends State<ToSelfTransferScreen> {
  double _selectedAmount = 25000.0;

  // Which of the customer's own accounts money moves between. Held here rather
  // than inside the cards widget because the PIN and success screens have to
  // name the same two accounts the user is looking at.
  List<Map<String, dynamic>> _accounts = const [];
  int _fromIndex = 0;
  int _toIndex = 1;
  bool _loadingAccounts = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await ApiService.instance.getAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _fromIndex = 0;
      _toIndex = accounts.length > 1 ? 1 : 0;
      _loadingAccounts = false;
    });
  }

  void _swapAccounts() {
    if (_accounts.length < 2) return;
    setState(() {
      final tmp = _fromIndex;
      _fromIndex = _toIndex;
      _toIndex = tmp;
    });
  }

  Map<String, dynamic>? get _fromAccount =>
      _fromIndex < _accounts.length ? _accounts[_fromIndex] : null;

  Map<String, dynamic>? get _toAccount =>
      _toIndex < _accounts.length ? _accounts[_toIndex] : null;

  void _onAmountSelected(double val) {
    setState(() {
      _selectedAmount = val;
    });
  }

  void _submitSelfTransfer() {
    if (_accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link a second account to transfer to yourself.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      SmoothPageRoute(
        builder: (context) => MobileDeviceFrame(
          child: PinScreen(
            title: 'Enter your 6-digit PIN',
            subtitle: 'Self Transfer \u00B7 '
                '${_AccountCardsSection.shortBank(_fromAccount)} to '
                '${_AccountCardsSection.shortBank(_toAccount)}',
            amount: _selectedAmount,
            onSuccess: () {
              // Pop PinScreen
              Navigator.pop(context);
              // Pop ToSelfTransferScreen
              Navigator.pop(context);
              // Navigate to PaymentSuccessScreen
              Navigator.push(
                context,
                SmoothPageRoute(
                  builder: (context) => MobileDeviceFrame(
                    child: PaymentSuccessScreen(
                      recipientName: 'Self Transfer',
                      recipientUpi:
                          (_toAccount?['bankName'] ?? 'Your other account')
                              .toString(),
                      amount: _selectedAmount,
                      fromAccount:
                          '${_AccountCardsSection.shortBank(_fromAccount)} '
                          '\u2022\u2022\u2022 '
                          '${_AccountCardsSection.maskedTail(_fromAccount)}',
                      method: 'Self Transfer',
                      referenceId:
                          '${_AccountCardsSection.shortBank(_fromAccount)}'
                          '${(100000 + (_selectedAmount * 99).toInt())}'
                          'XQ${(100 + (_selectedAmount % 899).toInt())}',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedVal = _selectedAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final String amountStr = '₹$formattedVal';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            const _AppBar(),

            // 3. Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading: Between your accounts
                    Text(
                      tr('Between your accounts'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Double Account Cards with Overlapping Swap Button
                    _AccountCardsSection(
                      from: _fromAccount,
                      to: _toAccount,
                      loading: _loadingAccounts,
                      hasPair: _accounts.length >= 2,
                      onSwap: _swapAccounts,
                      onRelink: _loadAccounts,
                    ),

                    const SizedBox(height: 36),

                    // Amount Label
                    const Center(
                      child: _AmountLabel(),
                    ),
                    const SizedBox(height: 8),

                    // Large Amount Display
                    Center(
                      child: Text(
                        amountStr,
                        style: GoogleFonts.fraunces(
                          fontSize: 56,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0B2545),
                          letterSpacing: -1.68,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preset Amount Pills Row
                    _PresetAmountsRow(
                      selectedAmount: _selectedAmount,
                      onAmountSelected: _onAmountSelected,
                    ),

                    const SizedBox(height: 24),

                    // Info Security Badge
                    const _SecurityBadge(),

                    const SizedBox(height: 32),

                    // Primary Action Button
                    GestureDetector(
                      onTap: _submitSelfTransfer,
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF13315C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            tr('Transfer Now'),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

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
            tr('Transfer to Self'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          // Symmetrical spacer
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
// 3. Double Account Cards and Swap Button Stack
// ---------------------------------------------------------------------
class _AccountCardsSection extends StatelessWidget {
  const _AccountCardsSection({
    required this.from,
    required this.to,
    required this.loading,
    required this.hasPair,
    required this.onSwap,
    required this.onRelink,
  });

  final Map<String, dynamic>? from;
  final Map<String, dynamic>? to;
  final bool loading;
  final bool hasPair;
  final VoidCallback onSwap;

  /// Re-reads the account list after the customer links a new one.
  final VoidCallback onRelink;

  // The two cards were a fixed "PSB Savings XXXX 4521 / Rs 2,18,450" and
  // "HDFC Salary XXXX 8472 / Rs 68,200". A self-transfer screen has to name the
  // accounts the signed-in customer actually holds, so these come from
  // /v1/accounts, loaded by the parent screen.

  static String _money(num paise) {
    final n = (paise / 100).round().abs().toString();
    if (n.length <= 3) return '\u20B9$n';
    final last3 = n.substring(n.length - 3);
    var rest = n.substring(0, n.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '\u20B9${groups.join(',')},$last3';
  }

  /// The API never returns a full account number, only an opaque masked token.
  /// Showing its last four keeps the design's shape without inventing digits.
  static String maskedNumber(Map<String, dynamic>? acc) {
    if (acc == null) return 'XXXX XXXX XXXX';
    final token = (acc['accountNumberMaskedToken'] ?? acc['accountToken'] ?? '')
        .toString();
    if (token.length < 4) return 'XXXX XXXX XXXX';
    return 'XXXX XXXX ${token.substring(token.length - 4).toUpperCase()}';
  }

  /// Just the four characters, for inline "SBI ••• AB12" style labels.
  static String maskedTail(Map<String, dynamic>? acc) {
    final token = (acc?['accountNumberMaskedToken'] ?? acc?['accountToken'] ?? '')
        .toString();
    if (token.length < 4) return 'XXXX';
    return token.substring(token.length - 4).toUpperCase();
  }

  static String shortBank(Map<String, dynamic>? acc) {
    final bank = (acc?['bankName'] ?? '').toString().toLowerCase();
    if (bank.contains('sbi') || bank.contains('state bank')) return 'SBI';
    if (bank.contains('hdfc')) return 'HDFC';
    if (bank.contains('icici')) return 'ICICI';
    if (bank.contains('axis')) return 'AXIS';
    if (bank.contains('punjab') || bank.contains('psb')) return 'PSB';
    final words = (acc?['bankName'] ?? 'BANK').toString().split(' ');
    return words.first.toUpperCase();
  }

  static List<Color> _bankColours(String short) {
    switch (short) {
      case 'HDFC':
        return const [Color(0xFFFFE6E1), Color(0xFFB8311C)];
      case 'ICICI':
        return const [Color(0xFFFFF1DE), Color(0xFFA8541F)];
      case 'AXIS':
        return const [Color(0xFFF5E6E6), Color(0xFF8B1538)];
      default:
        return const [Color(0xFFE6F0F8), Color(0xFF0B4F8C)];
    }
  }

  static String _accountLabel(Map<String, dynamic>? acc) {
    if (acc == null) return 'No account';
    final nickname = (acc['nickname'] ?? '').toString();
    if (nickname.isNotEmpty) return nickname;
    final type = (acc['accountType'] ?? 'savings').toString();
    if (type.isEmpty) return 'Account';
    return '${type[0].toUpperCase()}${type.substring(1)} A/C';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!hasPair) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.swap_horiz_rounded,
                size: 28, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              tr('Link a second account'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A self-transfer needs two of your own accounts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            _accountCard('FROM', from),
            const SizedBox(height: 16), // Separator
            _accountCard('TO', to),
          ],
        ),
        // Floating swap button, now wired to actually reverse the direction.
        Positioned(
          left: 0,
          right: 0,
          top: 75,
          child: Center(
            child: GestureDetector(
              onTap: onSwap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0A000000),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFF0B4F8C),
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountCard(String direction, Map<String, dynamic>? acc) {
    final short = shortBank(acc);
    final colours = _bankColours(short);
    final balance = (acc?['balancePaise'] as num?)?.toInt() ??
        (acc?['balance'] as num?)?.toInt() ??
        0;

    return Container(
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colours[0],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                short,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colours[1],
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
                  direction,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _accountLabel(acc),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  maskedNumber(acc),
                  style: const TextStyle(
                    fontFamily: 'Geist_Mono',
                    fontSize: 11,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tr('AVAILABLE'),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _money(balance),
                style: const TextStyle(
                  fontFamily: 'Geist_Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A1628),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 4. Amount Label Widget
// ---------------------------------------------------------------------
class _AmountLabel extends StatelessWidget {
  const _AmountLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      tr('AMOUNT'),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
        letterSpacing: 1.32,
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 5. Preset Amounts Horizontal Row Widget
// ---------------------------------------------------------------------
class _PresetAmountsRow extends StatelessWidget {
  final double selectedAmount;
  final ValueChanged<double> onAmountSelected;

  const _PresetAmountsRow({
    required this.selectedAmount,
    required this.onAmountSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _amountPill(1000, isActive: selectedAmount == 1000),
        const SizedBox(width: 17),
        _amountPill(5000, isActive: selectedAmount == 5000),
        const SizedBox(width: 17),
        _amountPill(25000, isActive: selectedAmount == 25000),
        const SizedBox(width: 17),
        _amountPill(50000, isActive: selectedAmount == 50000),
      ],
    );
  }

  Widget _amountPill(double amount, {required bool isActive}) {
    final String formattedVal = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final String amountStr = '₹$formattedVal';

    return GestureDetector(
      onTap: () => onAmountSelected(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 9.0),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0B2545) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? const Color(0xFF0B2545) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          amountStr,
          style: TextStyle(
            fontFamily: 'Geist_Mono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF0A1628),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 6. Security Info Badge Widget
// ---------------------------------------------------------------------
class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Checked outline banner circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x1A16A34A), // color/spring-green/36 10% opacity
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: Color(0xFF16A34A),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Description text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Instant transfer · No charges'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Both accounts verified · IMPS via NPCI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
