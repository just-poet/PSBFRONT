import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_dashboard.dart';
import 'screens/bottom_nav_bar.dart';
import 'screens/ekyc.dart';
import 'services/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FinixNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _updateTab(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateTab(previousRoute);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateTab(newRoute);
    }
  }

  void _updateTab(Route route) {
    final routeName = route.settings.name;
    if (routeName != null) {
      if (routeName == '/ekyc') {
        activeTabNotifier.value = 'ekyc';
      } else if (routeName == '/' || routeName == '/home') {
        if (routeName == '/home') {
          activeTabNotifier.value = 'home';
        } else {
          activeTabNotifier.value = 'ekyc';
        }
      } else if (routeName == '/goals') {
        activeTabNotifier.value = 'goals';
      } else if (routeName == '/portfolio') {
        activeTabNotifier.value = 'portfolio';
      } else if (routeName == '/chat') {
        activeTabNotifier.value = 'chat';
      } else if (routeName == '/security') {
        activeTabNotifier.value = 'security';
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  runApp(const FinixApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  const MyCustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class FinixApp extends StatelessWidget {
  const FinixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FINIX',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [FinixNavigatorObserver()],
      scrollBehavior: const MyCustomScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B2545), // color/brand/navy
          primary: const Color(0xFF0B2545),
          secondary: const Color(0xFF2E75B6), // color/brand/action
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          // For headings or serif values, we will configure Fraunces in-place
          bodyLarge: GoogleFonts.inter(
            color: const Color(0xFF0A1628), // color/text/ink
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: GoogleFonts.inter(
            color: const Color(0xFF475569), // color/text/slate
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      builder: (context, child) {
        return MobileDeviceFrame(child: child!);
      },
      home: const EkycScreen(),
    );
  }
}

class MobileDeviceFrame extends StatelessWidget {
  final Widget child;
  const MobileDeviceFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // If this MobileDeviceFrame is nested (i.e. already has an ancestor MobileDeviceFrame),
    // we bypass rendering the bezel/borders and the bottom navigation bar.
    final bool isNested = context.findAncestorWidgetOfExactType<MobileDeviceFrame>() != null;
    if (isNested) {
      return child;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    
    final Widget mainAppContent = Column(
      children: [
        Expanded(
          child: child,
        ),
        const FinixBottomNavigationBar(),
      ],
    );

    // If the device screen width is small (real mobile), render the app directly
    if (screenWidth <= 480) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: mainAppContent,
      );
    }

    // On wide desktop/web browsers, render a high-fidelity mobile device mockup
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Sleek Slate 900 canvas
      body: Center(
        child: Container(
          width: 412, // standard mobile screen width
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40), // Premium rounded device corners
            border: Border.all(
              color: const Color(0xFF1E293B), // Sleek Slate 800 phone bezel
              width: 12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: mainAppContent,
        ),
      ),
    );
  }
}
