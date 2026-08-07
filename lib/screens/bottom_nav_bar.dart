import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show navigatorKey;
import 'home_dashboard.dart';
import 'goals.dart';
import 'portfolio_hub.dart';
import 'chat.dart';
import 'security.dart';

// Global ValueNotifier to track active tab across screens
final ValueNotifier<String> activeTabNotifier = ValueNotifier<String>('home');

/// How many screens currently on screen have asked for the bottom bar to go.
///
/// A count rather than a flag: screens can sit on top of one another, and a
/// plain bool would be cleared by the first one to leave even while another
/// was still showing.
final ValueNotifier<int> navBarSuppressors = ValueNotifier<int>(0);

/// Wrap a screen in this to hide the bottom bar while it is on screen.
///
/// The bar lives above the Navigator, so a screen cannot simply leave it out.
/// Used by the payment receipt, which offers its own "Back to home" action and
/// removes the rest of the stack — tabs there would navigate away from a
/// receipt the customer has not finished reading.
class HideBottomNav extends StatefulWidget {
  final Widget child;
  const HideBottomNav({super.key, required this.child});

  @override
  State<HideBottomNav> createState() => _HideBottomNavState();
}

class _HideBottomNavState extends State<HideBottomNav> {
  /// Both edges are deferred to after the current frame: the bar listens to
  /// this notifier, and changing it during a build or during the teardown of a
  /// popped route rebuilds a widget that is mid-flight, which Flutter asserts
  /// on. A post-frame callback lands in the gap between frames instead.
  ///
  /// The frame is requested explicitly because a post-frame callback does not
  /// ask for one. On the way out that matters: the route is disposed on the
  /// last frame of the pop animation, so without this the callback would sit
  /// queued until something else happened to repaint and the bar would stay
  /// hidden on the screen underneath.
  void _shift(int delta) {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      final next = navBarSuppressors.value + delta;
      navBarSuppressors.value = next > 0 ? next : 0;
    });
    binding.scheduleFrame();
  }

  @override
  void initState() {
    super.initState();
    _shift(1);
  }

  @override
  void dispose() {
    _shift(-1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class FinixBottomNavigationBar extends StatelessWidget {
  const FinixBottomNavigationBar({super.key});

  void _onTabTapped(BuildContext context, String tab) {
    if (activeTabNotifier.value == tab) return;

    final navState = navigatorKey.currentState;
    if (navState == null) return;

    // Custom fade transition for a premium feel
    Route createTabRoute(Widget screen, String routeName) {
      return PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      );
    }

    if (tab == 'home') {
      // Pop all the way back to HomeDashboardScreen (root route)
      navState.popUntil((route) => route.isFirst);
      activeTabNotifier.value = 'home';
    } else {
      Widget screen;
      String routeName;

      switch (tab) {
        case 'goals':
          screen = const GoalsScreen();
          routeName = '/goals';
          break;
        case 'portfolio':
          screen = const PortfolioHubScreen();
          routeName = '/portfolio';
          break;
        case 'chat':
          screen = const ChatScreen();
          routeName = '/chat';
          break;
        case 'security':
          screen = const SecurityScreen();
          routeName = '/security';
          break;
        default:
          return;
      }

      // Maintain a shallow stack: [Home, SelectedTab]
      navState.pushAndRemoveUntil(
        createTabRoute(screen, routeName),
        (route) => route.isFirst,
      );
      activeTabNotifier.value = tab;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: activeTabNotifier,
      builder: (context, activeTab, _) {
        if (activeTab == 'ekyc') {
          return const SizedBox.shrink();
        }
        return Container(
          height: 98, // Increased height to match new design
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  tabName: 'home',
                  label: tr('Home'),
                  isActive: activeTab == 'home',
                ),
                _buildNavItem(
                  context: context,
                  tabName: 'goals',
                  label: tr('goals'),
                  isActive: activeTab == 'goals',
                ),
                _buildNavItem(
                  context: context,
                  tabName: 'portfolio',
                  label: tr('portfolio'),
                  isActive: activeTab == 'portfolio',
                ),
                _buildNavItem(
                  context: context,
                  tabName: 'chat',
                  label: tr('chat'),
                  isActive: activeTab == 'chat',
                ),
                _buildNavItem(
                  context: context,
                  tabName: 'security',
                  label: tr('security'),
                  isActive: activeTab == 'security',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String tabName,
    required String label,
    required bool isActive,
  }) {
    final activeColor = const Color(0xFF0B2545); // color/brand/navy
    final inactiveColor = const Color(0xFF475569); // color/text/slate

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(context, tabName),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFEEF4FA)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _getIconForTab(
                  tabName,
                  isActive,
                  isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // The 48px icon plus this label exceeded the bar's inner height by
            // 2px, painting the debug overflow stripes. Scaling the label down
            // to fit also keeps the bar intact when the OS font size is
            // increased, which would otherwise overflow it much further.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                    letterSpacing: -0.11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getIconForTab(String tab, bool isActive, Color color) {
    return CustomPaint(
      size: const Size(48, 48),
      painter: FigmaIconPainter(tab, color),
    );
  }
}

// Custom painter that replicates the exact SVG path vectors from Figma
class FigmaIconPainter extends CustomPainter {
  final String tab;
  final Color color;

  FigmaIconPainter(this.tab, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (tab == 'home') {
      paint.strokeWidth = 2.0;
      paint.strokeJoin = StrokeJoin.round;
      canvas.save();
      // Translate to position the 24x24 house icon inside the 48x48 circular frame
      canvas.translate(12.0, 12.0);
      final path = Path();
      path.moveTo(15.0, 21.0);
      path.lineTo(15.0, 13.0);
      path.cubicTo(15.0, 12.7348, 14.8946, 12.4804, 14.7071, 12.2929);
      path.cubicTo(14.5196, 12.1054, 14.2652, 12.0, 14.0, 12.0);
      path.lineTo(10.0, 12.0);
      path.cubicTo(9.73478, 12.0, 9.48043, 12.1054, 9.29289, 12.2929);
      path.cubicTo(9.10536, 12.4804, 9.0, 12.7348, 9.0, 13.0);
      path.lineTo(9.0, 21.0);
      path.moveTo(3.0, 10.0);
      path.cubicTo(2.99993, 9.70907, 3.06333, 9.42162, 3.18579, 9.15772);
      path.cubicTo(3.30824, 8.89381, 3.4868, 8.6598, 3.709, 8.472);
      path.lineTo(10.709, 2.472);
      path.cubicTo(11.07, 2.16691, 11.5274, 1.99952, 12.0, 1.99952);
      path.cubicTo(12.4726, 1.99952, 12.93, 2.16691, 13.291, 2.472);
      path.lineTo(20.291, 8.472);
      path.cubicTo(20.5132, 8.6598, 20.6918, 8.89381, 20.8142, 9.15772);
      path.cubicTo(20.9367, 9.42162, 21.0001, 9.70907, 21.0, 10.0);
      path.lineTo(21.0, 19.0);
      path.cubicTo(21.0, 19.5304, 20.7893, 20.0391, 20.4142, 20.4142);
      path.cubicTo(20.0391, 20.7893, 19.5304, 21.0, 19.0, 21.0);
      path.lineTo(5.0, 21.0);
      path.cubicTo(4.46957, 21.0, 3.96086, 20.7893, 3.58579, 20.4142);
      path.cubicTo(3.21071, 20.0391, 3.0, 19.5304, 3.0, 19.0);
      path.lineTo(3.0, 10.0);
      path.close();
      canvas.drawPath(path, paint);
      canvas.restore();
    } else if (tab == 'goals') {
      paint.strokeWidth = 1.5;
      paint.strokeJoin = StrokeJoin.round;
      final path = Path();
      path.moveTo(23.8981, 25.5503);
      path.lineTo(23.8981, 22.4002);
      path.moveTo(23.8981, 22.4002);
      path.lineTo(23.8981, 14.0);
      path.lineTo(32.3425, 18.2001);
      path.lineTo(23.8981, 22.4002);
      path.close();
      path.moveTo(32.9347, 22.6333);
      path.cubicTo(33.4964, 24.3555, 33.549, 26.2019, 33.0861, 27.953);
      path.cubicTo(32.6233, 29.704, 31.6645, 31.2859, 30.3239, 32.5105);
      path.cubicTo(28.9832, 33.7351, 27.3172, 34.5508, 25.5239, 34.8606);
      path.cubicTo(23.7306, 35.1704, 21.8857, 34.9613, 20.2085, 34.258);
      path.cubicTo(18.5313, 33.5547, 17.0925, 32.387, 16.0632, 30.8937);
      path.cubicTo(15.034, 29.4004, 14.4576, 27.6445, 14.4028, 25.8347);
      path.cubicTo(14.3479, 24.025, 14.8168, 22.2377, 15.7536, 20.6854);
      path.cubicTo(16.6905, 19.1331, 18.056, 17.8812, 19.6875, 17.0787);
      path.moveTo(19.678, 22.397);
      path.cubicTo(19.1491, 23.0974, 18.8047, 23.9183, 18.6763, 24.785);
      path.cubicTo(18.5479, 25.6516, 18.6396, 26.5365, 18.9429, 27.3589);
      path.cubicTo(19.2462, 28.1813, 19.7516, 28.9151, 20.413, 29.4935);
      path.cubicTo(21.0744, 30.0719, 21.8707, 30.4765, 22.7295, 30.6703);
      path.cubicTo(23.5883, 30.8642, 24.4822, 30.8413, 25.3298, 30.6036);
      path.cubicTo(26.1774, 30.3659, 26.9517, 29.921, 27.5822, 29.3094);
      path.cubicTo(28.2127, 28.6979, 28.6794, 27.9391, 28.9397, 27.1022);
      path.cubicTo(29.2, 26.2653, 29.2456, 25.377, 29.0724, 24.5181);
      canvas.drawPath(path, paint);
    } else if (tab == 'portfolio') {
      paint.strokeWidth = 1.8;
      paint.strokeJoin = StrokeJoin.round;
      final path = Path();
      path.moveTo(32.4071, 27.5363);
      path.cubicTo(31.877, 28.79, 31.0478, 29.8948, 29.992, 30.754);
      path.cubicTo(28.9362, 31.6133, 27.6861, 32.2008, 26.3508, 32.4653);
      path.cubicTo(25.0155, 32.7297, 23.6358, 32.6631, 22.3322, 32.2711);
      path.cubicTo(21.0287, 31.8792, 19.841, 31.1738, 18.873, 30.2168);
      path.cubicTo(17.905, 29.2598, 17.1861, 28.0802, 16.7793, 26.7812);
      path.cubicTo(16.3725, 25.4822, 16.2901, 24.1033, 16.5393, 22.7651);
      path.cubicTo(16.7885, 21.4269, 17.3617, 20.1701, 18.2088, 19.1046);
      path.cubicTo(19.0559, 18.0391, 20.1512, 17.1974, 21.3988, 16.6529);
      path.moveTo(32.2321, 24.2946);
      path.cubicTo(32.6921, 24.2946, 33.0696, 23.9204, 33.0238, 23.4629);
      path.cubicTo(32.8317, 21.5498, 31.9838, 19.7619, 30.624, 18.4024);
      path.cubicTo(29.2643, 17.0429, 27.4762, 16.1955, 25.5629, 16.0038);
      path.cubicTo(25.1046, 15.9579, 24.7313, 16.3354, 24.7313, 16.7954);
      path.lineTo(24.7313, 23.4621);
      path.cubicTo(24.7313, 23.6831, 24.8191, 23.8951, 24.9754, 24.0514);
      path.cubicTo(25.1316, 24.2076, 25.3436, 24.2954, 25.5646, 24.2954);
      path.lineTo(32.2321, 24.2946);
      path.close();
      canvas.drawPath(path, paint);
    } else if (tab == 'chat') {
      paint.strokeWidth = 1.8;
      paint.strokeJoin = StrokeJoin.round;
      final path = Path();
      path.moveTo(15.4298, 29.7331);
      path.cubicTo(15.5113, 29.363, 15.4802, 28.9769, 15.3405, 28.6245);
      path.cubicTo(14.3685, 26.6076, 14.14, 24.3122, 14.6954, 22.1433);
      path.cubicTo(15.2508, 19.9744, 16.5544, 18.0713, 18.3762, 16.7699);
      path.cubicTo(20.198, 15.4684, 22.4209, 14.8522, 24.6528, 15.03);
      path.cubicTo(26.8846, 15.2078, 28.982, 16.1681, 30.5748, 17.7416);
      path.cubicTo(32.1676, 19.315, 33.1535, 21.4005, 33.3585, 23.63);
      path.cubicTo(33.5635, 25.8595, 32.9745, 28.0897, 31.6954, 29.9273);
      path.cubicTo(30.4163, 31.7649, 28.5293, 33.0916, 26.3673, 33.6735);
      path.cubicTo(24.2053, 34.2553, 21.9073, 34.0549, 19.8787, 33.1075);
      path.cubicTo(19.5457, 32.9811, 19.184, 32.9508, 18.8346, 33.0201);
      path.lineTo(15.5923, 33.9682);
      path.cubicTo(15.4359, 34.0097, 15.2715, 34.0106, 15.1146, 33.9707);
      path.cubicTo(14.9578, 33.9309, 14.8137, 33.8516, 14.6961, 33.7405);
      path.cubicTo(14.5785, 33.6293, 14.4912, 33.49, 14.4426, 33.3357);
      path.cubicTo(14.3939, 33.1813, 14.3855, 33.0171, 14.4181, 32.8586);
      path.lineTo(15.4298, 29.7331);
      path.close();
      canvas.drawPath(path, paint);
    } else if (tab == 'security') {
      paint.strokeWidth = 1.8;
      paint.strokeJoin = StrokeJoin.round;
      final path = Path();
      path.moveTo(20.7109, 24.4987);
      path.lineTo(22.8359, 26.5984);
      path.lineTo(27.0859, 22.3991);
      path.moveTo(32.3984, 25.5485);
      path.cubicTo(32.3984, 30.7977, 28.6797, 33.4222, 24.2597, 34.9445);
      path.cubicTo(24.0282, 35.022, 23.7768, 35.0183, 23.5478, 34.934);
      path.cubicTo(19.1172, 33.4222, 15.3984, 30.7977, 15.3984, 25.5485);
      path.lineTo(15.3984, 18.1998);
      path.cubicTo(15.3984, 17.9213, 15.5104, 17.6543, 15.7096, 17.4574);
      path.cubicTo(15.9089, 17.2606, 16.1791, 17.1499, 16.4609, 17.1499);
      path.cubicTo(18.5859, 17.1499, 21.2422, 15.8902, 23.0909, 14.2944);
      path.cubicTo(23.316, 14.1044, 23.6024, 14.0, 23.8984, 14.0);
      path.cubicTo(24.1945, 14.0, 24.4808, 14.1044, 24.7059, 14.2944);
      path.cubicTo(26.5653, 15.9007, 29.2109, 17.1499, 31.3359, 17.1499);
      path.cubicTo(31.6177, 17.1499, 31.888, 17.2606, 32.0872, 17.4574);
      path.cubicTo(32.2865, 17.6543, 32.3984, 17.9213, 32.3984, 18.1998);
      path.lineTo(32.3984, 25.5485);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FigmaIconPainter oldDelegate) {
    return oldDelegate.tab != tab || oldDelegate.color != color;
  }
}
