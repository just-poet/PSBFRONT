import 'dart:math' as math;
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:flutter/material.dart';
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

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _netWorth = {'netWorth': 248765000};
  Map<String, dynamic> _healthScore = {'score300To900': 782, 'band': 'Excellent'};
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Automatically re-load when connection state changes
    ApiService.instance.isConnected.addListener(_onConnectionStatusChanged);
  }

  @override
  void dispose() {
    ApiService.instance.isConnected.removeListener(_onConnectionStatusChanged);
    super.dispose();
  }

  void _onConnectionStatusChanged() {
    if (mounted) {
      _loadDashboardData();
    }
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
      ]);

      if (mounted) {
        setState(() {
          _netWorth = results[0] as Map<String, dynamic>;
          _healthScore = results[1] as Map<String, dynamic>;
          _accounts = (results[2] as List).cast<Map<String, dynamic>>();
          _transactions = (results[3] as List).cast<Map<String, dynamic>>();
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
                      _NetWorthCard(data: _netWorth),
                      
                      const SizedBox(height: 12),
                      
                      // 4. Accounts & Score Pair
                      _AccountsAndScorePair(accounts: _accounts, healthScore: _healthScore),
                      
                      const SizedBox(height: 24),
                      
                      // 5. Quick Actions Section
                      const _QuickActions(),
                      
                      const SizedBox(height: 24),
                      
                      // 6. Overview Horizontal Scroll Section
                      const _OverviewSection(),
                      
                      const SizedBox(height: 20),
                      
                      // 7. AI Insight Card
                      const _AiInsightCard(),
                      
                      const SizedBox(height: 24),
                      
                      // 8. Market Snapshot
                      const _MarketSnapshot(),
                      
                      const SizedBox(height: 24),
                      
                      // 9. Recent Activity
                      _RecentActivity(transactions: _transactions),
                      
                      const SizedBox(height: 16),
                      
                      // 10. Emergency Freeze Banner
                      const _EmergencyFreezeBanner(),
                      
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
                  // User Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEEF4FA),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'http://localhost:3845/assets/d95318b4f8385b27f2a9af78c3b9c52d86c79074.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback profile circle with initials
                          return Container(
                            color: const Color(0xFF2E75B6),
                            child: const Center(
                              child: Text(
                                'VA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // User Name with Overflow Safety
                  Expanded(
                    child: Text(
                      'VENKAT A',
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
  const _NetWorthCard({required this.data});

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
                      'TOTAL NET WORTH',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.32,
                      ),
                    ),
                    Container(
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
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: Colors.white,
                        size: 14,
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
                          color: const Color(0xFF4ADE80).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_upward,
                              color: Color(0xFF4ADE80),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '₹12,400 this week',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF4ADE80),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                            'View Portfolio',
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
    final int score = healthScore['score300To900'] ?? 782;
    final String band = healthScore['band'] ?? 'Excellent';
    
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
                          'All Accounts',
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
                    color: const Color(0xFF16A34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF16A34A),
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
                        'Health Score',
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
                              score.toString(),
                              style: GoogleFonts.fraunces(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0A1628),
                              ),
                            ),
                            Text(
                              ' · $band',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
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
          'Quick Actions',
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
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
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
                      'Spent this month',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹32,400',
                      style: GoogleFonts.spaceMono(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_downward,
                          color: Color(0xFFDC2626),
                          size: 9,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '8% vs last month',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
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
                width: 154,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asset Allocation',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        children: [
                          // Legend
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _legendItem(const Color(0xFF0B2545), 'MF', '40%'),
                                const SizedBox(height: 2.5),
                                _legendItem(const Color(0xFF2E75B6), 'Stocks', '30%'),
                                const SizedBox(height: 2.5),
                                _legendItem(const Color(0xFF16A34A), 'Cash', '20%'),
                                const SizedBox(height: 2.5),
                                _legendItem(const Color(0xFFC8A951), 'FD', '10%'),
                              ],
                            ),
                          ),
                          // Pie donut Chart
                          SizedBox(
                            width: 55,
                            height: 55,
                            child: CustomPaint(
                              painter: DonutChartPainter(),
                            ),
                          ),
                        ],
                      ),
                    )
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
                      'Goals Progress',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Europe Trip',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '72%',
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
                        widthFactor: 0.72,
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
                      '8 weeks to go',
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
                      'Credit Score',
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
                                  'Excellent',
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
                      'Upcoming (7 days)',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _billItem('HDFC SIP', 'Mon, 5 Jun', '₹5,000'),
                    const SizedBox(height: 4),
                    _billItem('Airtel Postpaid', 'Wed, 7 Jun', '₹999'),
                    const SizedBox(height: 4),
                    _billItem('LIC Premium', 'Sat, 10 Jun', '₹3,200'),
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
                            'TOTAL',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          Text(
                            '₹9,199',
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
                      'Protection',
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
                                'All Clear',
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
                      '₹96K',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    Text(
                      'of ₹1.5L limit',
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
class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius - 3);

    // Percentages: MF 40%, Stocks 30%, Cash 20%, FD 10%
    final slices = [
      _Slice(0.40, const Color(0xFF0B2545)),
      _Slice(0.30, const Color(0xFF2E75B6)),
      _Slice(0.20, const Color(0xFF16A34A)),
      _Slice(0.10, const Color(0xFFC8A951)),
    ];

    double startAngle = -math.pi / 2; // start from top
    
    for (var slice in slices) {
      final sweepAngle = slice.percentage * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      // Draw a gap between slices using slightly reduced angle
      canvas.drawArc(rect, startAngle + 0.05, sweepAngle - 0.1, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Slice {
  final double percentage;
  final Color color;
  _Slice(this.percentage, this.color);
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
  const _AiInsightCard();

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
                    'FINIX INSIGHT',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF2E75B6),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.54,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF0A1628),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Your '),
                      TextSpan(
                        text: 'Europe Trip',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0B2545)),
                      ),
                      const TextSpan(text: ' goal is 8 weeks ahead of schedule. Consider redirecting '),
                      TextSpan(
                        text: '₹2,000/month',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0B2545)),
                      ),
                      const TextSpan(text: ' toward retirement to compound faster.'),
                    ],
                  ),
                ),
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
                        'Run simulation',
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
  const _MarketSnapshot();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Market Snapshot',
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
                    'See full analysis',
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
                        'LIVE',
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
                  _marketStat('Sensex', '72,840', '+0.42%', true),
                  _marketStat('Nifty 50', '22,104', '+0.38%', true),
                  _marketStat('Gold/10g', '62,180', '-0.21%', false),
                  _marketStat('Repo', '6.50%', 'Hold', null),
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
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.fraunces(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w400,
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
              'Recent Activity',
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
                    'See all',
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
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
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
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive ? const Color(0xFF16A34A) : const Color(0xFF0A1628),
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
  const _EmergencyFreezeBanner();

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
                      text: 'Emergency Freeze — ',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: 'Long-press the shield icon in Security to halt all outgoing transactions instantly.',
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
