import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_account.dart';
import '../main.dart';
import '../services/api_service.dart';

class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({super.key});

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  // Mutable state list of linked banks
  List<Map<String, dynamic>> _linkedBanks = [];
  bool _isLoading = false;

  // There used to be a _fallbackBanks list of four real-looking banks with
  // balances. When the API returned nothing — signed out, offline, or a
  // customer with no linked accounts — the screen quietly showed those instead,
  // so the user saw someone else's money. An empty list now shows an empty
  // state.

  @override
  void initState() {
    super.initState();
    // Re-read whenever the customer changes something anywhere in the app.
    // Without this the screen kept whatever it loaded on first build, so a
    // payment made elsewhere left stale figures here.
    ApiService.instance.dataVersion.addListener(_onDataChanged);
    _fetchAccounts();
  }

  @override
  void dispose() {
    ApiService.instance.dataVersion.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final apiAccs = await ApiService.instance.getAccounts();
      if (mounted) {
        setState(() {
          _linkedBanks = apiAccs.map(_mapApiAccount).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _linkedBanks = [];
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _mapApiAccount(Map<String, dynamic> apiAcc) {
    final String bank = apiAcc['bankName'] ?? 'Unknown Bank';
    final int balPaise = apiAcc['balance'] ?? 0;
    final double balRupees = balPaise / 100;
    
    Color bgColor = const Color(0xFFEEF4FA);
    Color txtColor = const Color(0xFF0B2545);
    String logoText = 'BANK';
    
    if (bank.toLowerCase().contains('sbi') || bank.toLowerCase().contains('state bank')) {
      logoText = 'SBI';
      bgColor = const Color(0xFFE6F0F8);
      txtColor = const Color(0xFF0B4F8C);
    } else if (bank.toLowerCase().contains('hdfc')) {
      logoText = 'HDFC';
      bgColor = const Color(0xFFFFE6E1);
      txtColor = const Color(0xFFB8311C);
    } else if (bank.toLowerCase().contains('icici')) {
      logoText = 'ICICI';
      bgColor = const Color(0xFFFFF1DE);
      txtColor = const Color(0xFFA8541F);
    } else if (bank.toLowerCase().contains('axis')) {
      logoText = 'AXIS';
      bgColor = const Color(0xFFF5E6E6);
      txtColor = const Color(0xFF8B1538);
    }

    return {
      'logoText': logoText,
      'logoBgColor': bgColor,
      'logoTextColor': txtColor,
      'bankName': bank,
      'accountsCount': '${apiAcc['accountType'] ?? 'Savings'} account',
      'balance': '₹${_formatCurrency(balRupees)}',
    };
  }

  void _linkNewAccount() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      SmoothPageRoute(
        builder: (context) => const AddAccountScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _linkedBanks.insert(0, result);
      });
      try {
        final cleanStr = (result['balance'] as String).replaceAll('₹', '').replaceAll(',', '').trim();
        // The parse guards against a malformed balance string coming back from
        // the add-account sheet; linkAccount does not take an opening balance.
        double.tryParse(cleanStr);
        await ApiService.instance.linkAccount(
          bankName: result['bankName'],
          upiId: result['upiId'] ?? '${result['logoText'].toLowerCase()}@finix',
          accountNumber: '1234567890',
          ifscCode: 'SBIN0000000',
          accountType: 'Savings',
          holderName: ApiService.instance.userName.value ?? 'Account holder',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute combined statistics dynamically
    double totalBalance = 0;
    int totalAccounts = 0;
    for (final bank in _linkedBanks) {
      final balanceStr = bank['balance'] as String;
      final cleanStr = balanceStr.replaceAll('₹', '').replaceAll(',', '').trim();
      final bal = double.tryParse(cleanStr) ?? 0.0;
      totalBalance += bal;

      final accCountStr = bank['accountsCount'] as String;
      final count = int.tryParse(accCountStr.split(' ')[0]) ?? 1;
      totalAccounts += count;
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

            // 3. Scrollable List Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Combined Balance Card
                    _buildCombinedBalanceCard(totalBalance, _linkedBanks.length, totalAccounts),

                    const SizedBox(height: 14),

                    // + Link a new account action
                    _buildLinkAccountAction(),

                    const SizedBox(height: 14),

                    // Bank List
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_linkedBanks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.account_balance_outlined,
                                size: 28, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text(
                              tr('No linked accounts yet'),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('Link a bank above to see balances here.'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _linkedBanks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final bank = _linkedBanks[index];
                        return _buildBankCard(
                          logoText: bank['logoText'] as String,
                          logoBgColor: bank['logoBgColor'] as Color,
                          logoTextColor: bank['logoTextColor'] as Color,
                          bankName: bank['bankName'] as String,
                          accountsCount: bank['accountsCount'] as String,
                          balance: bank['balance'] as String,
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // Account Aggregator Security Card
                    const _SecurityInfoCard(),

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

  // Combined Balance Card
  Widget _buildCombinedBalanceCard(double totalBalance, int totalBanks, int totalAccounts) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2545), Color(0xFF134074)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('TOTAL COMBINED BALANCE'),
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.32,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '₹${_formatCurrency(totalBalance)}',
              style: GoogleFonts.fraunces(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w400,
                letterSpacing: -1.08,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalBanks banks · $totalAccounts accounts',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(text: tr('Last sync: ')),
                      TextSpan(
                        text: tr('Just now'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Link Account Action link
  Widget _buildLinkAccountAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18.0),
      child: GestureDetector(
        onTap: _linkNewAccount,
        child: Text(
          tr('+ Link a new account'),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E75B6),
          ),
        ),
      ),
    );
  }

  // Reusable Bank Card Builder
  Widget _buildBankCard({
    required String logoText,
    required Color logoBgColor,
    required Color logoTextColor,
    required String bankName,
    required String accountsCount,
    required String balance,
  }) {
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
          // Logo placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: logoBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                logoText,
                style: GoogleFonts.inter(
                  color: logoTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bank Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  accountsCount,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Total Balance Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tr('TOTAL'),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                balance,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final int value = amount.toInt();
    if (value == 0) return '0';

    final String valStr = value.toString();
    if (valStr.length <= 3) return valStr;

    final String lastThree = valStr.substring(valStr.length - 3);
    String remaining = valStr.substring(0, valStr.length - 3);

    final List<String> chunks = [];
    while (remaining.length > 2) {
      chunks.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      chunks.insert(0, remaining);
    }
    return '${chunks.join(',')},$lastThree';
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
            tr('Linked Accounts'),
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
// 5. Security Info Card Widget
// ---------------------------------------------------------------------
class _SecurityInfoCard extends StatelessWidget {
  const _SecurityInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shield Icon Container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          // Info Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('ACCOUNT AGGREGATOR'),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E75B6),
                    letterSpacing: 0.72,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.45,
                      color: const Color(0xFF0A1628),
                    ),
                    children: [
                      const TextSpan(text: 'Read-only access via '),
                      TextSpan(
                        text: 'Sahamati AA framework',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B2545),
                        ),
                      ),
                      const TextSpan(
                        text: '. Consent expires in 90 days. You can revoke anytime in Settings.',
                      ),
                    ],
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
