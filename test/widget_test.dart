import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finix_dashboard/main.dart';

/// Replaces the `flutter create` counter scaffold, which tested a counter app
/// that never existed in this project and had been failing since day one.
/// These assert what actually matters: the app boots to the cKYC sign-in, and
/// the form cannot be submitted half-filled.
void main() {
  testWidgets('app boots to the cKYC login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FinixApp());
    await tester.pump();

    expect(find.text('Sign in to FINIX'), findsOneWidget);
    expect(find.text('CKYC NUMBER'), findsOneWidget);
    expect(find.text('6-DIGIT PIN'), findsOneWidget);
  });

  testWidgets('sign-in stays disabled until both fields are complete',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FinixApp());
    await tester.pump();

    ElevatedButton signInButton() => tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Sign in'),
            matching: find.byType(ElevatedButton),
          ),
        );

    expect(signInButton().onPressed, isNull, reason: 'empty form must not submit');

    // A partial CKYC is still not enough.
    await tester.enterText(find.byType(TextField).first, '20000000');
    await tester.pump();
    expect(signInButton().onPressed, isNull, reason: '8-digit CKYC is incomplete');

    // Full CKYC but no PIN.
    await tester.enterText(find.byType(TextField).first, '2000000001');
    await tester.pump();
    expect(signInButton().onPressed, isNull, reason: 'PIN still missing');

    // Both complete -> enabled.
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    expect(signInButton().onPressed, isNotNull, reason: 'complete form must submit');
  });
}
