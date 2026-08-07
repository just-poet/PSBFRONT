import 'dart:ui';
import 'dart:math' as math;
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'linked_accounts.dart';
import 'scan_qr.dart';
import 'transfer.dart';
import 'pay_anyone.dart';
import 'to_self.dart';
import 'profile.dart';
import 'notifications.dart';
import 'market_analysis.dart';
import 'simulation.dart';
import 'transaction_history.dart';
import 'portfolio_hub.dart';
import 'health_score.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/health_band.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  Map<String, dynamic> _netWorth = {'netWorth': 248765000};
  // Empty until loaded. This used to default to 782/'Excellent', so every
  // customer saw a green healthy score for the first frame — and kept it if
  // the request failed.
  Map<String, dynamic> _healthScore = const {};
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];
  // Backing data for the cards that used to be hardcoded.
  List<Map<String, dynamic>> _investments = [];
  List<Map<String, dynamic>> _goals = [];
  Map<String, dynamic> _market = {};
  Map<String, dynamic> _insight = {};
  bool _accountFrozen = false;

  /// Whether balances on the net-worth card are blurred out. Session-only by
  /// design: it protects against someone glancing over your shoulder, so it
  /// should reset when the app is reopened rather than silently persisting.
  bool _amountsHidden = false;
  List<Map<String, dynamic>> _loans = [];
  Map<String, dynamic> _insurance = {};
  List<Map<String, dynamic>> _deductions = [];

  @override
  void initState() {
    super.initState();
    // Re-read whenever the customer changes something anywhere in the app.
    // Without this the screen kept whatever it loaded on first build, so a
    // payment made elsewhere left stale figures here.
    ApiService.instance.dataVersion.addListener(_onDataChanged);
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
    // Automatically re-load when connection state changes
    ApiService.instance.isConnected.addListener(_onConnectionStatusChanged);
  }

  @override
  void dispose() {
    ApiService.instance.dataVersion.removeListener(_onDataChanged);
    ApiService.instance.isConnected.removeListener(_onConnectionStatusChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onConnectionStatusChanged() {
    if (mounted) {
      _loadDashboardData();
    }
  }

  /// Re-reads on resume so money that arrived while the app was away — a
  /// transfer from another customer, say — shows up without a manual refresh.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  void _onDataChanged() {
    if (mounted) _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_isLoading) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await ApiService.instance.checkConnection();
      
      final results = await Future.wait([
        ApiService.instance.getNetWorth(),
        ApiService.instance.getHealthScore(),
        ApiService.instance.getAccounts(),
        ApiService.instance.getTransactionHistory(),
        ApiService.instance.getInvestments(),
        ApiService.instance.getGoals(),
        ApiService.instance.getMarketSnapshot(),
        ApiService.instance.getInsightsFeed(),
        ApiService.instance.getSecurityHealth(),
        // Loans and insurance are the customer's real recurring commitments,
        // which the "Upcoming" card used to invent (HDFC SIP, Airtel Postpaid,
        // LIC Premium). Deductions drive the 80C card.
        ApiService.instance.getLoans(),
        ApiService.instance.getInsurance(),
        ApiService.instance.getTaxDeductions(),
      ]);

      if (mounted) {
        setState(() {
          _netWorth = results[0] as Map<String, dynamic>;
          _healthScore = results[1] as Map<String, dynamic>;
          _accounts = (results[2] as List).cast<Map<String, dynamic>>();
          _transactions = (results[3] as List).cast<Map<String, dynamic>>();
          _investments = (results[4] as List).cast<Map<String, dynamic>>();
          _goals = (results[5] as List).cast<Map<String, dynamic>>();
          _market = results[6] as Map<String, dynamic>;
          final feed = (results[7] as List).cast<Map<String, dynamic>>();
          // The feed is priority-ordered; show the first entry.
          _insight = feed.isNotEmpty ? feed.first : {};
          _accountFrozen = (results[8] as Map)['is_frozen'] == true;
          // Drives the app-wide lock, so a freeze applied on another device
          // (or before this session) locks the app as soon as we learn of it.
          ApiService.instance.accountFrozen.value = _accountFrozen;
          _loans = (results[9] as List).cast<Map<String, dynamic>>();
          _insurance = results[10] as Map<String, dynamic>;
          _deductions = (results[11] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFF0B2545),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Bar
                const _StatusBar(),
                
                // 2. Profile / Top Bar
                const _TopProfileBar(),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // 3. Net Worth Card
                      _NetWorthCard(
                        data: _netWorth,
                        hidden: _amountsHidden,
                        onToggleHidden: () =>
                            setState(() => _amountsHidden = !_amountsHidden),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 4. Accounts & Score Pair
                      _AccountsAndScorePair(accounts: _accounts, healthScore: _healthScore),
                      
                      const SizedBox(height: 24),
                      
                      // 5. Quick Actions Section
                      const _QuickActions(),
                      
                      const SizedBox(height: 24),
                      
                      // 6. Overview Horizontal Scroll Section
                      _OverviewSection(
                        transactions: _transactions,
                        investments: _investments,
                        goals: _goals,
                        loans: _loans,
                        insurance: _insurance,
                        deductions: _deductions,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 7. AI Insight Card
                      _AiInsightCard(insight: _insight),
                      
                      const SizedBox(height: 24),
                      
                      // 8. Market Snapshot
                      _MarketSnapshot(data: _market),
                      
                      const SizedBox(height: 24),
                      
                      // 9. Recent Activity
                      _RecentActivity(transactions: _transactions),
                      
                      const SizedBox(height: 16),
                      
                      // 10. Emergency Freeze Banner
                      _EmergencyFreezeBanner(frozen: _accountFrozen),
                      
                      const SizedBox(height: 32),
                    ],
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
// 2. Profile / Top Bar Widget
// ---------------------------------------------------------------------
class _TopProfileBar extends StatelessWidget {
  const _TopProfileBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: ProfileScreen(),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  // Avatar and name follow the signed-in user. The avatar used
                  // to load a Figma asset from http://localhost:3845, which
                  // cannot resolve on a phone (and is blocked as cleartext), so
                  // it always fell through to the error builder anyway.
                  ValueListenableBuilder<String?>(
                    valueListenable: ApiService.instance.userName,
                    builder: (context, name, _) {
                      final display = (name == null || name.trim().isEmpty)
                          ? 'Signed out'
                          : name.toUpperCase();
                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2E75B6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                ApiService.instance.userInitials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                display,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0B2545),
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              // Connection Status Badge
              ValueListenableBuilder<bool>(
                valueListenable: ApiService.instance.isConnected,
                builder: (context, connected, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: connected 
                          ? const Color(0xFF16A34A).withOpacity(0.1) 
                          : const Color(0xFFD97706).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: connected ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          connected ? 'Live' : 'Sim',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: connected ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Settings. The only route in before was tapping the name, which
              // is not discoverable as "settings".
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      settings: const RouteSettings(name: '/settings'),
                      builder: (context) => const MobileDeviceFrame(
                        child: ProfileScreen(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF475569),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Notification Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      builder: (context) => const MobileDeviceFrame(
                        child: NotificationsScreen(),
                      ),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                    Positioned(
                      right: 9,
                      top: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 3. Net Worth Card Widget
// ---------------------------------------------------------------------
class _NetWorthCard extends StatelessWidget {
  final Map<String, dynamic> data;

  /// When true the amount and the weekly delta are blurred out.
  final bool hidden;
  final VoidCallback onToggleHidden;

  const _NetWorthCard({
    required this.data,
    required this.hidden,
    required this.onToggleHidden,
  });

  /// Weekly change straight from /v1/dashboard. Can be negative, which the
  /// hardcoded badge could never show.
  int get _weekDeltaPaise =>
      ((data['weekDeltaPaise'] as num?) ?? 0).toInt();

  Color get _deltaColour => _weekDeltaPaise < 0
      ? const Color(0xFFF87171)
      : const Color(0xFF4ADE80);

  String _formatPaise(int paise) {
    final double rupees = paise / 100;
    final int intRupees = rupees.toInt();
    final String s = intRupees.toString();
    if (s.length <= 3) return s;
    String lastThree = s.substring(s.length - 3);
    String other = s.substring(0, s.length - 3);
    String result = '';
    int count = 0;
    for (int i = other.length - 1; i >= 0; i--) {
      result = other[i] + result;
      count++;
      if (count == 2 && i > 0) {
        result = ',$result';
        count = 0;
      }
    }
    return '$result,$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    final int totalNetWorthPaise = data['netWorth'] ?? 248765000;
    final String formattedNetWorth = _formatPaise(totalNetWorthPaise);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2545), // color/azure/16
            Color(0xFF13315C), // color/azure/22
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Radial decorative design (from top right)
          Positioned(
            right: -40,
            top: -50,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2E75B6),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('TOTAL NET WORTH'),
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.32,
                      ),
                    ),
                    // Hides the balance from anyone glancing over the
                    // customer's shoulder. The icon was decorative before.
                    GestureDetector(
                      onTap: onToggleHidden,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          hidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹ ',
                      style: GoogleFonts.fraunces(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _Blurred(
                          hidden: hidden,
                          child: Text(
                            formattedNetWorth,
                            style: GoogleFonts.fraunces(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _deltaColour.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _weekDeltaPaise < 0
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: _deltaColour,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: _Blurred(
                                hidden: hidden,
                                child: Text(
                                  '₹${_formatPaise(_weekDeltaPaise.abs())} this week',
                                  style: GoogleFonts.inter(
                                    color: _deltaColour,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            builder: (context) => const MobileDeviceFrame(
                              child: PortfolioHubScreen(),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            tr('View Portfolio'),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 13,
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 4. Accounts & Score Pair Widget
// ---------------------------------------------------------------------
class _AccountsAndScorePair extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final Map<String, dynamic> healthScore;
  const _AccountsAndScorePair({required this.accounts, required this.healthScore});

  @override
  Widget build(BuildContext context) {
    final int? score = (healthScore['score300To900'] as num?)?.toInt();
    // Colour, icon and label all come from the band, so a 610 cannot render as
    // a green "Excellent" shield.
    final HealthBand healthBand =
        HealthBand.fromApi(healthScore['band'] as String?, score);
    
    // Group unique banks
    final uniqueBanks = accounts.isNotEmpty 
        ? accounts.map((a) => a['bankName'] as String).toSet().length
        : 4;
    final totalAccounts = accounts.isNotEmpty ? accounts.length : 8;

    return Row(
      children: [
        // All Accounts Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SmoothPageRoute(
                  builder: (context) => const MobileDeviceFrame(
                    child: LinkedAccountsScreen(),
                  ),
                ),
              );
            },
            child: Container(
              height: 87,
              padding: const EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF0B2545),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr('All Accounts'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                            letterSpacing: 0.22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$uniqueBanks bank${uniqueBanks == 1 ? '' : 's'}\nlinked',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Health Score Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SmoothPageRoute(
                  builder: (context) => const MobileDeviceFrame(
                    child: HealthScoreScreen(),
                  ),
                ),
              );
            },
            child: Container(
              height: 87,
              padding: const EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: healthBand.colour.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    healthBand.icon,
                    color: healthBand.colour,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr('Health Score'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                          letterSpacing: 0.22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              score?.toString() ?? '—',
                              style: GoogleFonts.fraunces(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0A1628),
                              ),
                            ),
                            Text(
                              ' · ${tr(healthBand.shortLabel)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: healthBand.colour,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// 5. Quick Actions Section Widget
// ---------------------------------------------------------------------
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Quick Actions'),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _actionButton(
              Icons.qr_code_scanner_rounded,
              'Scan & Pay',
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: ScanQrScreen(),
                    ),
                  ),
                );
              },
            ),
            _actionButton(
              Icons.swap_horiz_rounded,
              'Transfer',
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: BankTransferScreen(),
                    ),
                  ),
                );
              },
            ),
            _actionButton(
              Icons.person_outline_rounded,
              'To Contact',
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: PayAnyoneScreen(),
                    ),
                  ),
                );
              },
            ),
            _actionButton(
              Icons.sync_alt_rounded,
              'To Self',
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: ToSelfTransferScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        )
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0B2545),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            )
          ],
        ),
      ),
    ),
  );
}
}

// ---------------------------------------------------------------------
// 6. Overview Section Widget (Horizontal Scrolling Cards)
// ---------------------------------------------------------------------
class _OverviewSection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> investments;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> loans;
  final Map<String, dynamic> insurance;
  final List<Map<String, dynamic>> deductions;

  const _OverviewSection({
    required this.transactions,
    required this.investments,
    required this.goals,
    required this.loans,
    required this.insurance,
    required this.deductions,
  });

  /// The customer's known recurring commitments: one row per loan EMI and one
  /// per insurance premium. There is no bills/mandates endpoint, so these are
  /// the only scheduled outflows the backend actually knows about.
  List<({String name, String due, int paise})> _commitments() {
    final rows = <({String name, String due, int paise})>[];
    for (final l in loans) {
      final emi = (l['emiPaise'] as num?)?.toInt() ?? 0;
      if (emi <= 0) continue;
      final type = (l['loanType'] ?? 'Loan').toString();
      final lender = (l['lender'] ?? '').toString();
      rows.add((
        name: '$lender ${type[0].toUpperCase()}${type.substring(1)} EMI'.trim(),
        due: 'Monthly',
        paise: emi,
      ));
    }
    for (final pol in ((insurance['policies'] as List?) ?? const [])) {
      final m = Map<String, dynamic>.from(pol as Map);
      final premium = (m['premiumPaise'] as num?)?.toInt() ?? 0;
      if (premium <= 0) continue;
      rows.add((
        name: '${m['insurer'] ?? m['provider'] ?? 'Insurer'} premium',
        due: _shortDate(m['nextDueDate'] ?? m['dueDate']),
        paise: premium,
      ));
    }
    return rows;
  }

  int _commitmentsTotalPaise() =>
      _commitments().fold<int>(0, (sum, r) => sum + r.paise);

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _shortDate(dynamic iso) {
    final d = DateTime.tryParse((iso ?? '').toString());
    if (d == null) return 'Scheduled';
    return '${d.day} ${_monthNames[d.month - 1]}';
  }

  /// 80C usage from /v1/tax/deductions; was a fixed 96K of a 1.5L limit.
  ({double used, double limit}) _section80C() {
    for (final d in deductions) {
      if ((d['section'] ?? '').toString() == '80C') {
        return (
          used: ((d['usedPaise'] as num?) ?? 0) / 100,
          limit: ((d['limitPaise'] as num?) ?? 0) / 100,
        );
      }
    }
    return (used: 0, limit: 0);
  }

  static String _compactRupees(double rupees) {
    if (rupees >= 10000000) return '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
    if (rupees >= 100000) return '₹${(rupees / 100000).toStringAsFixed(1)}L';
    if (rupees >= 1000) return '₹${(rupees / 1000).round()}K';
    return '₹${rupees.round()}';
  }

  /// Debits in the current calendar month, in rupees.
  double _spentThisMonth() => _spentIn(DateTime.now());

  /// Debits in the same calendar month one month earlier, for the comparison.
  double _spentLastMonth() {
    final now = DateTime.now();
    return _spentIn(DateTime(now.year, now.month - 1));
  }

  double _spentIn(DateTime month) {
    var paise = 0;
    for (final t in transactions) {
      if (t['type'] != 'debit') continue;
      // Only settled money counts; a blocked transfer never left the account.
      final status = (t['status'] ?? '').toString();
      if (status != 'success' && status.isNotEmpty) continue;
      final ts = DateTime.tryParse((t['timestamp'] ?? '').toString());
      if (ts == null) continue;
      final local = ts.toLocal();
      if (local.year == month.year && local.month == month.month) {
        paise += (t['amountPaise'] as num?)?.toInt() ?? 0;
      }
    }
    return paise / 100;
  }

  /// Percentage change vs last month; null when there is no baseline to
  /// compare against (a brand-new account), so the UI can omit the claim
  /// instead of printing a fabricated "0%".
  double? _spendDeltaPercent() {
    final prev = _spentLastMonth();
    if (prev <= 0) return null;
    return ((_spentThisMonth() - prev) / prev) * 100;
  }

  /// Portfolio split by instrument category, largest first, as
  /// (label, share 0..1) pairs. Categories beyond the fourth are folded into
  /// "Other" so the legend stays readable.
  List<MapEntry<String, double>> _allocation() {
    final totals = <String, double>{};
    var grand = 0.0;
    for (final inv in investments) {
      final value = ((inv['currentValuePaise'] as num?)?.toDouble() ?? 0) / 100;
      if (value <= 0) continue;
      totals[_categoryLabel((inv['category'] ?? 'other').toString())] =
          (totals[_categoryLabel((inv['category'] ?? 'other').toString())] ?? 0) + value;
      grand += value;
    }
    if (grand <= 0) return const [];

    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();
    final rest = sorted.skip(4).fold<double>(0, (sum, e) => sum + e.value);
    final out = [for (final e in top) MapEntry(e.key, e.value / grand)];
    if (rest > 0) out.add(MapEntry('Other', rest / grand));
    return out;
  }

  static String _categoryLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'mutual_fund':
        return 'MF';
      case 'equity':
      case 'stocks':
        return 'Stocks';
      case 'liquid':
      case 'cash':
        return 'Cash';
      case 'fd':
      case 'fixed_deposit':
        return 'FD';
      case 'ppf':
        return 'PPF';
      case 'gold':
        return 'Gold';
      case 'debt':
        return 'Debt';
      case 'elss':
        return 'ELSS';
      default:
        return raw.isEmpty ? 'Other' : raw[0].toUpperCase() + raw.substring(1);
    }
  }

  /// The active goal closest to completion — the most encouraging one to show.
  Map<String, dynamic>? _featuredGoal() {
    final active = goals.where((g) => (g['status'] ?? 'active') == 'active').toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => _progress(b).compareTo(_progress(a)));
    return active.first;
  }

  static double _progress(Map<String, dynamic> g) {
    final target = (g['targetAmountPaise'] as num?)?.toDouble() ?? 0;
    if (target <= 0) return 0;
    final saved = (g['savedAmountPaise'] as num?)?.toDouble() ?? 0;
    return (saved / target).clamp(0.0, 1.0);
  }

  /// Whole weeks until the goal's target date, or null when it has passed.
  static int? _weeksTo(Map<String, dynamic> g) {
    final d = DateTime.tryParse((g['targetDate'] ?? '').toString());
    if (d == null) return null;
    final days = d.difference(DateTime.now()).inDays;
    return days <= 0 ? null : (days / 7).ceil();
  }

  /// Indian digit grouping: last three digits, then pairs (32,00,000).
  static String _money(double rupees) {
    final n = rupees.round().abs().toString();
    if (n.length <= 3) return '₹$n';
    final last3 = n.substring(n.length - 3);
    var rest = n.substring(0, n.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '₹${groups.join(',')},$last3';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Overview'),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 177,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              // Card 1: Spent this month
              _overviewCard(
                width: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Spent this month'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _money(_spentThisMonth()),
                      style: GoogleFonts.spaceMono(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (context) {
                        final delta = _spendDeltaPercent();
                        if (delta == null) {
                          // No prior month to compare with — say so rather than
                          // invent a trend.
                          return Text(
                            tr('No prior month'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          );
                        }
                        // Spending more is the bad direction here, so the
                        // colour follows the sign rather than being fixed red.
                        final up = delta >= 0;
                        final colour =
                            up ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
                        return Row(
                          children: [
                            Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                                color: colour, size: 9),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${delta.abs().toStringAsFixed(0)}% vs last month',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colour,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 28,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: SparklinePainter(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Card 2: Asset Allocation
              _overviewCard(
                width: 168,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Asset Allocation'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _AllocationRing(
                        slices: [
                          for (var i = 0; i < _allocation().length; i++)
                            (
                              label: _allocation()[i].key,
                              share: _allocation()[i].value,
                              colour: _sliceColours[i % _sliceColours.length],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card 3: Goals Progress
              _overviewCard(
                width: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Goals Progress'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_featuredGoal()?['name'] ?? 'No active goals').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _featuredGoal() == null
                          ? '--'
                          : '${(_progress(_featuredGoal()!) * 100).round()}%',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0B2545),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _featuredGoal() == null
                            ? 0.0
                            : _progress(_featuredGoal()!),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0B2545),
                                Color(0xFF2E75B6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      () {
                        final g = _featuredGoal();
                        if (g == null) return 'Create a goal to start';
                        final w = _weeksTo(g);
                        return w == null ? 'Target date passed' : '$w weeks to go';
                      }(),
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Card 4: Credit Score
              _overviewCard(
                width: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Credit Score'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CustomPaint(
                              painter: CreditScoreGaugePainter(0.784),
                              child: Center(
                                child: Text(
                                  '784',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tr('Excellent'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'CIBIL · +12 pts\nthis month',
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF475569),
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card 5: Upcoming Bills
              _overviewCard(
                width: 154,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Upcoming commitments'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_commitments().isEmpty)
                      Text(
                        tr('Nothing scheduled'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      )
                    else
                      for (final row in _commitments().take(3)) ...[
                        _billItem(row.name, row.due,
                            _compactRupees(row.paise / 100)),
                        const SizedBox(height: 4),
                      ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFE2E8F0),
                            style: BorderStyle.solid,
                            width: 0.75,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('TOTAL'),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          Text(
                            _compactRupees(_commitmentsTotalPaise() / 100),
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A1628),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // Card 6: Protection Status
              _overviewCard(
                width: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Protection'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: Color(0xFF16A34A),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('All Clear'),
                                style: GoogleFonts.fraunces(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                              Text(
                                'scan 9:30 AM',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '3 threats blocked\n2 SMS flagged this week',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A1628),
                        height: 1.25,
                      ),
                    )
                  ],
                ),
              ),

              // Card 7: Tax Saved
              _overviewCard(
                width: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tax Saved · 80C',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _compactRupees(_section80C().used),
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    Text(
                      'of ${_compactRupees(_section80C().limit)} limit',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.64, // 96k / 150k
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFC8A951),
                                Color(0xFFB89642),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '₹54,000',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0A1628),
                            ),
                          ),
                          TextSpan(
                            text: ' headroom left',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
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
        )
      ],
    );
  }

  Widget _overviewCard({required double width, required Widget child}) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 10, top: 2, bottom: 6),
      padding: const EdgeInsets.all(13.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _legendItem(Color color, String label, String percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            )
          ],
        ),
        Text(
          percentage,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        )
      ],
    );
  }

  Widget _billItem(String title, String due, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A1628),
                ),
              ),
              Text(
                due,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        )
      ],
    );
  }
}

// Sparkline Painter for Spent this month card
class SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDC2626)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFDC2626).withOpacity(0.15),
          const Color(0xFFDC2626).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Smooth sparkline wave coordinates
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.9),
      Offset(size.width * 0.45, size.height * 0.65),
      Offset(size.width * 0.6, size.height * 0.8),
      Offset(size.width * 0.75, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.6),
      Offset(size.width, size.height * 0.3),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final xc = (points[i].dx + points[i + 1].dx) / 2;
      final yc = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Draw the gradient filled area underneath
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Donut Chart Painter for Asset Allocation card
/// Slice colours, shared by the donut and its legend so the two always match.
const List<Color> _sliceColours = [
  Color(0xFF0B2545),
  Color(0xFF2E75B6),
  Color(0xFF16A34A),
  Color(0xFFC8A951),
  Color(0xFF7C3AED),
];

class DonutChartPainter extends CustomPainter {
  /// (colour, share 0..1) pairs, in draw order. Supplied by the caller from the
  /// customer's real holdings; the percentages used to be hardcoded here and so
  /// could not agree with the portfolio.
  final List<MapEntry<Color, double>> slices;

  /// Sweep fraction, 0..1. Drives the load-in animation; 1 draws the full
  /// chart.
  final double progress;

  const DonutChartPainter({required this.slices, this.progress = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius - 3);

    if (slices.isEmpty) {
      // Empty portfolio: draw a track rather than nothing, so the card keeps
      // its shape.
      canvas.drawArc(
        rect, 0, 2 * math.pi, false,
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0,
      );
      return;
    }

    // Track behind the slices, so a partially-swept ring still reads as a
    // chart rather than a stray arc.
    canvas.drawArc(
      rect, 0, 2 * math.pi, false,
      Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );

    double startAngle = -math.pi / 2; // start from top
    for (final slice in slices) {
      final sweepAngle = slice.value * 2 * math.pi * progress.clamp(0.0, 1.0);
      if (sweepAngle <= 0) continue;
      final paint = Paint()
        ..color = slice.key
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      // Trim each arc slightly so adjacent slices read as separate.
      final gap = sweepAngle > 0.2 ? 0.05 : 0.0;
      canvas.drawArc(rect, startAngle + gap, sweepAngle - gap * 2, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.progress != progress;
}

// Credit Score Gauge Painter
class CreditScoreGaugePainter extends CustomPainter {
  final double value;
  CreditScoreGaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius - 3);

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final valPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);
    canvas.drawArc(rect, -math.pi / 2, value * 2 * math.pi, false, valPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------
// 7. AI Insight Widget (FINIX INSIGHT)
// ---------------------------------------------------------------------
class _AiInsightCard extends StatelessWidget {
  /// One entry from /v1/insights/feed (title, body, reason).
  final Map<String, dynamic> insight;

  const _AiInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1628).withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
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
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tr('FINIX INSIGHT'),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF2E75B6),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.54,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (insight['title'] ?? 'FINIX Insight').toString(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B2545),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (insight['body'] ?? 'Connect to see personalised insights.')
                      .toString(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF0A1628),
                    height: 1.4,
                  ),
                ),
                if ((insight['reason'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    insight['reason'].toString(),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        settings: const RouteSettings(name: '/simulation'),
                        builder: (context) => const MobileDeviceFrame(
                          child: SimulationScreen(),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('Run simulation'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2E75B6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF2E75B6),
                        size: 12,
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 8. Market Snapshot Widget
// ---------------------------------------------------------------------
class _MarketSnapshot extends StatelessWidget {
  /// Payload from /v1/dashboard/market-snapshot. The four figures below were
  /// hardcoded, so the card showed stale index levels no matter what the
  /// backend reported.
  final Map<String, dynamic> data;

  const _MarketSnapshot({required this.data});

  static String _num(Object? v, {int decimals = 2}) {
    final d = (v as num?)?.toDouble();
    if (d == null) return '--';
    final s = d.toStringAsFixed(decimals);
    final parts = s.split('.');
    final n = parts[0];
    if (n.length <= 3) return s;
    // Indian grouping for index levels (75,180.42).
    final last3 = n.substring(n.length - 3);
    var rest = n.substring(0, n.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    final whole = '${groups.join(',')},$last3';
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Market Snapshot'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: MarketAnalysisScreen(),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    tr('See full analysis'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E75B6),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF2E75B6),
                    size: 12,
                  )
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B2545),
                Color(0xFF13315C),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              // Live Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr('LIVE'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF4ADE80),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Updated 2m ago',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // Market Numbers (4 columns)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // The API reports levels, not day-change, so the second line
                  // carries the portfolio impact it does provide rather than a
                  // percentage that would have to be invented.
                  _marketStat('Sensex', _num(data['sensex']), 'Index', null),
                  _marketStat('Nifty 50', _num(data['nifty']), 'Index', null),
                  _marketStat('Gold/10g', _num(data['goldPer10g'], decimals: 0),
                      'Spot', null),
                  _marketStat(
                    'Repo',
                    data['repoRate'] == null
                        ? '--'
                        : '${(data['repoRate'] as num).toStringAsFixed(2)}%',
                    'Policy',
                    null,
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _marketStat(String label, String value, String change, bool? isUp) {
    Color changeColor = Colors.white.withOpacity(0.7);
    if (isUp != null) {
      changeColor = isUp ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5);
    }
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          // Three stats share one row and gold now reads six figures
          // (₹1,10,406), which at 17pt overran its third of the card. Smaller
          // by default, and scaled down further rather than clipped when a
          // value grows.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.fraunces(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              if (isUp != null)
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: changeColor,
                  size: 9,
                ),
              if (isUp != null) const SizedBox(width: 2),
              Text(
                change,
                style: GoogleFonts.spaceMono(
                  color: changeColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 9. Recent Activity Widget
// ---------------------------------------------------------------------
class _RecentActivity extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _RecentActivity({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Recent Activity'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const MobileDeviceFrame(
                      child: TransactionHistoryScreen(),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    tr('See all'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E75B6),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF2E75B6),
                    size: 12,
                  )
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Transaction List
        Column(
          children: transactions.isNotEmpty
              ? transactions.take(3).map((txn) {
                  final bool isDebit = txn['type'] == 'debit';
                  final int amtPaise = txn['amountPaise'] ?? 0;
                  final double amtRupees = amtPaise / 100;
                  final String sign = isDebit ? '−' : '+';
                  final String formattedAmt = '$sign₹${amtRupees.toStringAsFixed(0)}';
                  final String category = txn['category'] ?? 'Payment';
                  
                  final String merchant = txn['merchantName'] ?? 'Unknown';
                  final String initials = merchant.length >= 2 
                      ? merchant.substring(0, 2).toUpperCase() 
                      : (merchant.isNotEmpty ? merchant[0].toUpperCase() : 'TX');
                  
                  Widget avatar;
                  if (category.toLowerCase().contains('income') || !isDebit) {
                    avatar = _iconWidget(Icons.arrow_upward_rounded, const Color(0xFF16A34A));
                  } else if (category.toLowerCase().contains('investment')) {
                    avatar = _iconWidget(Icons.trending_up_rounded, const Color(0xFF0B2545));
                  } else {
                    avatar = _avatarWidget(initials);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _activityRow(
                      avatar: avatar,
                      title: merchant,
                      subtitle: 'Recent · $category',
                      amount: formattedAmt,
                      isPositive: !isDebit,
                    ),
                  );
                }).toList()
              : [
                  // Fallback hardcoded transactions
                  _activityRow(
                    avatar: _avatarWidget('RS'),
                    title: 'Rohan Sharma',
                    subtitle: 'Today, 2:14 PM · UPI',
                    amount: '−₹2,400',
                    isPositive: false,
                  ),
                  const SizedBox(height: 8),
                  _activityRow(
                    avatar: _iconWidget(Icons.trending_up_rounded, const Color(0xFF0B2545)),
                    title: 'HDFC Bluechip SIP',
                    subtitle: 'Today, 10:00 AM · Auto SIP',
                    amount: '−₹5,000',
                    isPositive: false,
                    badge: 'AUTO',
                  ),
                  const SizedBox(height: 8),
                  _activityRow(
                    avatar: _iconWidget(Icons.arrow_upward_rounded, const Color(0xFF16A34A)),
                    title: 'Salary Credit',
                    subtitle: 'Yesterday, 12:01 AM · NEFT',
                    amount: '+₹85,000',
                    isPositive: true,
                  ),
                ],
        )
      ],
    );
  }

  Widget _activityRow({
    required Widget avatar,
    required String title,
    required String subtitle,
    required String amount,
    required bool isPositive,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Flexible, not bare: a recipient like "Account 4521 (IFSC
                    // SBIN0000000)" is longer than the card and was pushing the
                    // verified badge out and painting over the amount.
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF16A34A),
                          size: 9,
                        ),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Capped and scaled so a large figure stays on one line instead of
          // squeezing the description or spilling past the card edge.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 108),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                amount,
                maxLines: 1,
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPositive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF0A1628),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _avatarWidget(String text) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: const Color(0xFF0B2545),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _iconWidget(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 10. Emergency Freeze Widget (Dashed Border Banner)
// ---------------------------------------------------------------------
class _EmergencyFreezeBanner extends StatelessWidget {
  /// Whether outgoing transfers are currently frozen, from
  /// /v1/security/health. The banner used to be a fixed tip, so a frozen
  /// account looked identical to a healthy one on the dashboard.
  final bool frozen;

  const _EmergencyFreezeBanner({required this.frozen});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(color: const Color(0xFFDC2626), strokeWidth: 0.75),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(0.06), // red with transparency
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_person_rounded,
                  color: Color(0xFFDC2626),
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
                    color: Colors.black,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: frozen
                          ? 'Account frozen — '
                          : 'Emergency Freeze — ',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: frozen
                          ? 'Outgoing transfers are blocked. Unfreeze from the Security screen.'
                          : 'Long-press the shield icon in Security to halt all outgoing transactions instantly.',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Dashed Border Painter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  
  DashedBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );

    // We can approximate a dashed rounded path or draw custom segments.
    // To be clean and responsive, draw segments using path metrics.
    final path = Path()..addRRect(outerRect);
    
    // Draw dashed path
    const double dashWidth = 5.0;
    const double gapWidth = 4.0;
    
    final Path dashPath = Path();
    
    for (var metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + gapWidth;
      }
    }
    
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Blurs its child when [hidden], leaving the layout untouched.
///
/// An ImageFiltered keeps the widget's size and position exactly as they were,
/// so toggling cannot shift anything around it — replacing the digits with dots
/// would change the text width and make the card jump.
class _Blurred extends StatelessWidget {
  const _Blurred({required this.hidden, required this.child});

  final bool hidden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: hidden
          ? ImageFiltered(
              key: const ValueKey('hidden'),
              imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              // Blur alone leaves faint but readable shapes at this size, so
              // the text is also dimmed before blurring.
              child: Opacity(opacity: 0.75, child: child),
            )
          : KeyedSubtree(key: const ValueKey('shown'), child: child),
    );
  }
}

/// Animated allocation ring with its own legend.
///
/// The ring sweeps in on first build so it is visibly a chart loading rather
/// than a static arc, and the dominant holding's share sits in the middle.
///
/// Labels are placed beside the ring, not radially around its edge: this card
/// is 168px wide, and text pinned to the rim of a 62px ring overlaps itself as
/// soon as two slices are adjacent. Colour pairs each label to its slice.
class _AllocationRing extends StatelessWidget {
  const _AllocationRing({required this.slices});

  final List<({String label, double share, Color colour})> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Center(
        child: Text(
          tr('No holdings'),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
      );
    }

    final dominant = slices.reduce((a, b) => a.share >= b.share ? a : b);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top three only; a 168px card cannot hold more without the
                  // labels wrapping.
                  for (final slice in slices.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: slice.colour,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              tr(slice.label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            // Percentages count up with the sweep.
                            '${(slice.share * 100 * t).round()}%',
                            style: GoogleFonts.spaceMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A1628),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(62, 62),
                    painter: DonutChartPainter(
                      slices: [
                        for (final slice in slices)
                          MapEntry(slice.colour, slice.share),
                      ],
                      progress: t,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(dominant.share * 100 * t).round()}%',
                        style: GoogleFonts.fraunces(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      Text(
                        tr(dominant.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
