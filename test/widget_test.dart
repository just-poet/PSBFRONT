import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finix_dashboard/main.dart';
import 'package:finix_dashboard/screens/bottom_nav_bar.dart';
import 'package:finix_dashboard/screens/payment_success.dart';
import 'package:finix_dashboard/screens/splash_screen.dart';

/// Replaces the `flutter create` counter scaffold, which tested a counter app
/// that never existed in this project and had been failing since day one.
/// These assert what actually matters: the app boots to the cKYC sign-in, and
/// the form cannot be submitted half-filled.
void main() {
  /// Pumps past the splash animation to the sign-in screen beneath it.
  ///
  /// The splash runs a 3s timeline before handing off, so a plain pump lands
  /// mid-animation and finds none of the login widgets.
  Future<void> pumpToSignIn(WidgetTester tester) async {
    await tester.pumpWidget(const FinixApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('the splash plays on launch and then hands off to sign-in',
      (WidgetTester tester) async {
    // The splash was written, its assets were precached in main(), and nothing
    // ever mounted it: `home` pointed straight at the login screen, so the
    // animation never played. Asserting the sign-in screen eventually appears
    // is not enough — that passes with no splash at all — so this asserts the
    // splash is actually on screen first.
    await tester.pumpWidget(const FinixApp());
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget,
        reason: 'the app must open on the splash');
    expect(find.text('Sign in to FINIX'), findsNothing,
        reason: 'and must not skip straight past it');

    // The storyboard runs for 3s and then cross-fades.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing,
        reason: 'the splash must not linger once it has handed off');
    expect(find.text('Sign in to FINIX'), findsOneWidget);
  });

  testWidgets('app boots through the splash to the phone sign-in',
      (WidgetTester tester) async {
    await pumpToSignIn(tester);

    expect(find.text('Sign in to FINIX'), findsOneWidget);
    // Customers sign in with the phone number they know, not a CKYC number
    // almost nobody can recite.
    expect(find.text('MOBILE NUMBER'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('6-DIGIT PIN'), findsOneWidget);
  });

  testWidgets('sign-in stays disabled until both fields are complete',
      (WidgetTester tester) async {
    await pumpToSignIn(tester);

    ElevatedButton signInButton() => tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Sign in'),
            matching: find.byType(ElevatedButton),
          ),
        );

    expect(signInButton().onPressed, isNull,
        reason: 'empty form must not submit');

    // A partial number is still not enough.
    await tester.enterText(find.byType(TextField).first, '99836');
    await tester.pump();
    expect(signInButton().onPressed, isNull,
        reason: 'a 5-digit number is incomplete');

    // Full number but no PIN.
    await tester.enterText(find.byType(TextField).first, '9983692606');
    await tester.pump();
    expect(signInButton().onPressed, isNull, reason: 'PIN still missing');

    // Both complete -> enabled.
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    expect(signInButton().onPressed, isNotNull,
        reason: 'complete form must submit');
  });

  testWidgets('bottom nav is hidden on auth screens and shown after sign-in',
      (WidgetTester tester) async {
    // The bar renders nothing while the active tab is 'ekyc', which the
    // navigator observer sets for the initial '/' route so the sign-in screen
    // has no chrome. A push without a route name leaves the tab stuck there and
    // the bar never returns — exactly what happened when the login screen
    // replaced eKYC as the app's entry point, so assert both states.
    await pumpToSignIn(tester);

    activeTabNotifier.value = 'ekyc';
    await tester.pump();
    expect(find.text('Home'), findsNothing,
        reason: 'auth screens must not show navigation chrome');

    activeTabNotifier.value = 'home';
    await tester.pump();
    expect(find.text('Home'), findsOneWidget,
        reason: 'the nav bar must come back once signed in');
  });

  testWidgets('bottom nav hides while the keyboard is open', (tester) async {
    // With the keyboard up the bar floats above the keys and covers the field
    // being typed into, so it is hidden until the keyboard is dismissed.
    await pumpToSignIn(tester);
    activeTabNotifier.value = 'home';
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);

    // viewInsets.bottom is how Flutter reports the keyboard's height.
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNothing,
        reason: 'the bar must not sit on top of the keyboard');

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget,
        reason: 'and it must come back once the keyboard closes');
  });

  testWidgets('bottom nav is hidden on the payment receipt', (tester) async {
    // The receipt ends the payment journey with its own way back to the
    // dashboard; the tab bar used to sit under it and navigate the customer
    // away from a receipt they had not finished reading.
    await pumpToSignIn(tester);
    activeTabNotifier.value = 'home';
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);

    navigatorKey.currentState!.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/payment-success'),
        builder: (_) => const PaymentSuccessScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNothing,
        reason: 'no tab bar on a payment receipt');

    navigatorKey.currentState!.pop();
    // The route underneath here is the app's initial '/', which the navigator
    // observer treats as an auth screen and blanks the bar for on its own. Set
    // the tab back so this assertion is about the receipt's suppression alone.
    activeTabNotifier.value = 'home';
    await tester.pumpAndSettle();
    expect(navBarSuppressors.value, 0,
        reason: 'the receipt must release its hold when it leaves');
    expect(find.text('Home'), findsOneWidget,
        reason: 'and the bar returns once the receipt is gone');
  });
}
