import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/bottom_nav_bar.dart';
import 'screens/frozen_lock.dart';
import 'screens/login_ckyc.dart';
import 'screens/splash/splash_assets.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/idle_timeout.dart';
import 'services/locale_service.dart';
import 'services/notification_service.dart';

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
  // Loaded before the first frame so the app opens in the chosen language
  // rather than flashing English and swapping.
  await LocaleService.instance.load();
  // Channels are registered up front; the permission itself is only
  // asked for when the customer taps Turn on.
  await FinixNotifications.instance.init();
  // Vectors parsed before the first frame so the mark does not pop in
  // mid-assembly on a cold start.
  await SplashAssets.precache();
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

class FinixApp extends StatefulWidget {
  const FinixApp({super.key});

  @override
  State<FinixApp> createState() => _FinixAppState();
}

class _FinixAppState extends State<FinixApp> {
  @override
  void initState() {
    super.initState();
    // When any request comes back 401 the token is dead — the backend rotates
    // its JWT signing secret on restart and access tokens last 15 minutes.
    // Until this listener existed the app stayed on whatever screen it was on,
    // silently rendering mock or empty data, with no route back to sign-in.
    ApiService.instance.sessionExpired.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    ApiService.instance.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() {
    if (!ApiService.instance.sessionExpired.value) return;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    ApiService.instance.sessionExpired.value = false;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const LoginCkycScreen(),
      ),
      (route) => false,
    );
    final messenger = ScaffoldMessenger.maybeOf(navigator.context);
    messenger?.showSnackBar(
      const SnackBar(
          content: Text('Your session expired. Please sign in again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt on language change: every screen reads its strings through tr()
    // at build time, so a rebuild is all that is needed to switch language
    // where the native close-and-relaunch is not available.
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocaleService.instance.language,
      builder: (context, language, _) => _buildApp(context, language),
    );
  }

  Widget _buildApp(BuildContext context, AppLanguage language) {
    return MaterialApp(
      title: 'Finix',
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
        // Clamp the OS font scale.
        //
        // Every screen is laid out with fixed heights, pills and fixed-width
        // chrome; at Android's largest accessibility setting (2.0x) those
        // labels wrap, clip and overflow. Devanagari, Gurmukhi and Telugu are
        // taller than Latin at the same size, which compounds it. Capping at
        // 1.3x keeps text meaningfully scalable without breaking the layout;
        // the floor stops a very small setting making figures unreadable.
        final media = MediaQuery.of(context);
        final scale = media.textScaler.scale(14) / 14;
        final clamped = MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(scale.clamp(0.85, 1.3)),
          ),
          child: _FrozenAwareApp(child: child!),
        );
        return clamped;
      },
      // The splash runs its 3s storyboard on every cold start and then hands
      // off to sign-in. It was built and its assets precached in main(), but
      // nothing ever mounted it — `home` went straight to the login screen, so
      // the animation never played.
      home: SplashScreen(nextScreen: (_) => const LoginCkycScreen()),
    );
  }
}

/// Lays the freeze lock over the app while the account is frozen.
class _FrozenAwareApp extends StatelessWidget {
  const _FrozenAwareApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.instance.accountFrozen,
      builder: (context, frozen, _) {
        // Idle timeout wraps the app so a tap anywhere counts as activity.
        final app = IdleTimeout(child: MobileDeviceFrame(child: child));
        if (!frozen) return app;
        // While frozen the lock covers every route, which is what makes a
        // freeze meaningful on a phone somebody else is holding.
        return Stack(
          children: [
            app,
            const Positioned.fill(child: FrozenLockScreen()),
          ],
        );
      },
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
    final bool isNested =
        context.findAncestorWidgetOfExactType<MobileDeviceFrame>() != null;
    if (isNested) {
      return child;
    }

    final MediaQueryData media = MediaQuery.of(context);
    final double screenWidth = media.size.width;

    // The soft keyboard pushes the bar up so it floats above the keys, covering
    // the field being typed into. Hide it while the keyboard is open; it
    // returns as soon as the keyboard is dismissed.
    //
    // Checked here rather than inside the bar: the bar renders inside the
    // Scaffold below, and Scaffold strips viewInsets from its body's MediaQuery
    // once it has resized for the keyboard, so the bar itself always sees
    // viewInsets.bottom == 0. This context is above that Scaffold, and reading
    // MediaQuery here also registers the dependency that rebuilds on change.
    final bool keyboardOpen = media.viewInsets.bottom > 0;

    final Widget mainAppContent = ValueListenableBuilder<int>(
      // Screens that must not show the bar — the payment receipt, which gives
      // its own way back to the dashboard — register here rather than being
      // listed by route name, because they are pushed from five call sites
      // without route settings.
      valueListenable: navBarSuppressors,
      builder: (context, suppressors, _) {
        return Column(
          children: [
            Expanded(
              child: child,
            ),
            if (!keyboardOpen && suppressors == 0)
              const FinixBottomNavigationBar(),
          ],
        );
      },
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
            borderRadius:
                BorderRadius.circular(40), // Premium rounded device corners
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
