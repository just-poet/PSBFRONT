@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:finix_dashboard/services/api_service.dart';

/// Drives the app's real ApiService against a running backend.
///
/// This is the Android code path: the Dart VM sends no Origin header, so — like
/// a native app — it is unaffected by CORS. It exercises the actual client
/// (headers, JSON encoding, token handling, response parsing), not a curl
/// approximation of it.
///
/// Skipped unless a base URL is supplied, so `flutter test` stays hermetic:
///
///   flutter test test/live_backend_test.dart --dart-define=FINIX_BASE_URL=http://localhost:8080
///
/// Point FINIX_BASE_URL at the tunnel hostname to verify remote access too.
const _baseUrl = String.fromEnvironment('FINIX_BASE_URL');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (_baseUrl.isEmpty) {
    test('live backend checks (skipped)', () {}, skip: 'pass --dart-define=FINIX_BASE_URL=<url>');
    return;
  }

  // flutter_test installs an HttpOverrides that stubs every HttpClient, so real
  // sockets are refused and the singleton cannot even be constructed at import
  // time. Clearing it restores real networking; the singleton is then touched
  // only from inside setUpAll, i.e. within a test zone.
  late final ApiService api;

  setUpAll(() async {
    HttpOverrides.global = null;
    api = ApiService.instance;
    api.baseUrl = _baseUrl;
    // Device fingerprint normally comes from the native channel; in a test the
    // channel is absent and hardware_service falls back, which is fine — the
    // backend only requires the value to be present and stable.
    api.deviceIdFingerprint = 'flutter-live-test-device';
  });

  test('reaches the backend', () async {
    expect(await api.checkConnection(), isTrue,
        reason: 'no backend at $_baseUrl — start it first');
    expect(api.isConnected.value, isTrue);
  });

  test('signs in with cKYC and stores the session', () async {
    final res = await api.loginWithCkyc('2000000001', '123456');
    expect(res['accessToken'], isA<String>());
    expect(res['userId'], isA<String>());
    expect(api.sessionToken, isNotNull, reason: 'token must be persisted for later calls');
  });

  test('rejects a bad PIN without pretending to be signed in', () async {
    await expectLater(
      api.loginWithCkyc('2000000001', '000000'),
      throwsA(isA<ApiException>()),
      reason: 'a failed sign-in must throw, never fall back to mock data',
    );
  });

  test('dashboard data is live, not the mock fallback', () async {
    // Re-establish a session (the bad-PIN test above does not clear it, but be
    // explicit so this test does not depend on ordering).
    await api.loginWithCkyc('2000000001', '123456');

    final netWorth = await api.getNetWorth();
    expect(api.isConnected.value, isTrue, reason: 'isConnected false => mock fallback was used');
    expect(netWorth['netWorth'], isA<int>());
    // The seeded identity starts at +Rs.85,00,000 and drifts down as the demo
    // spends, so assert a band rather than the exact figure — an exact match
    // fails the moment anyone makes a payment. The mock fallback returns
    // 248765000, which is far outside this band, so this still proves the data
    // came from the server.
    expect(netWorth['netWorth'], greaterThan(840000000));
    expect(netWorth['netWorth'], lessThanOrEqualTo(850000000));

    final accounts = await api.getAccounts();
    expect(accounts, isNotEmpty);
    expect(accounts.first['accountId'], isA<String>());
    expect(accounts.first['balance'], isA<int>());

    final health = await api.getHealthScore();
    expect(health['score300To900'], isA<int>());

    final txns = await api.getTransactionHistory();
    expect(txns, isNotEmpty);
    expect(txns.first['type'], anyOf('debit', 'credit'));
  });

  test('portfolio, goals and tax screens load', () async {
    expect(await api.getInvestments(), isNotEmpty);
    final insurance = await api.getInsurance();
    expect(insurance['policies'], isA<List>());
    expect(insurance['totalLifeCoverPaise'], isA<int>());
    expect(await api.getLoans(), isNotEmpty);
    expect(await api.getGoals(), isNotEmpty);

    final tax = await api.getTaxDashboard();
    expect(tax['taxPayable'], isA<int>());
    final regimes = await api.getTaxRegimeComparison();
    expect(regimes['oldRegime'], isA<Map>());
  });

  test('a QR payment goes through the risk engine', () async {
    final res = await api.initiateTransaction(
      amountPaise: 25000,
      recipient: 'starbucks@okhdfcbank',
      channel: 'upi',
    );
    expect(api.isConnected.value, isTrue);
    expect(res['transactionId'], isA<String>());
    expect(res['riskLevel'], anyOf('low', 'medium', 'high'));
  });

  test('security freeze round-trips', () async {
    await api.emergencyFreeze('live test');
    var health = await api.getSecurityHealth();
    expect(health['is_frozen'], isTrue);

    await api.unfreeze();
    health = await api.getSecurityHealth();
    expect(health['is_frozen'], isFalse);
  });

  test('signed-in identity follows the account, so the UI cannot show a stale name', () async {
    // The dashboard, profile and personal-details screens all render
    // ApiService.userName / userInitials. Previously they hardcoded "Venkat A",
    // so all ten demo logins looked like the same person. Signing in as two
    // different customers must produce two different identities.
    await api.loginWithCkyc('2000000001', '123456');
    expect(api.userName.value, 'Jiyad');
    expect(api.userInitials, 'JI');

    await api.loginWithCkyc('2000000003', '123456');
    expect(api.userName.value, 'RD Shubham');
    expect(api.userInitials, 'RS');

    // Signing out must clear it rather than leave the previous customer's name
    // on screen.
    await api.clearSession();
    expect(api.userName.value, isNull);
    expect(api.userInitials, '--');
  });

  test('dashboard cards that used to be hardcoded now have real data behind them',
      () async {
    await api.loginWithCkyc('2000000001', '123456');

    // Market snapshot: the card showed fixed index levels regardless of the API.
    final market = await api.getMarketSnapshot();
    expect(api.isConnected.value, isTrue);
    expect(market['sensex'], isA<num>());
    expect(market['nifty'], isA<num>());
    expect(market['repoRate'], isA<num>());

    // Insight card: was a fixed "Europe Trip" sentence.
    final feed = await api.getInsightsFeed();
    expect(feed, isNotEmpty);
    expect(feed.first['title'].toString(), isNotEmpty);
    expect(feed.first['body'].toString(), isNotEmpty);

    // Allocation donut is computed from holdings, so categories must be present.
    final investments = await api.getInvestments();
    expect(investments, isNotEmpty);
    expect(investments.first['category'], isA<String>());
    expect(investments.first['currentValuePaise'], isA<int>());

    // Goal card picks the active goal nearest completion.
    final goals = await api.getGoals();
    expect(goals.any((g) => (g['status'] ?? 'active') == 'active'), isTrue);
    expect(goals.first['targetAmountPaise'], isA<int>());
    expect(goals.first['savedAmountPaise'], isA<int>());

    // Spend card sums debits, so transactions need type + timestamp.
    final txns = await api.getTransactionHistory();
    expect(txns, isNotEmpty);
    expect(txns.first['type'], anyOf('debit', 'credit'));
    expect(DateTime.tryParse(txns.first['timestamp'].toString()), isNotNull);

    // Freeze banner reflects real state.
    final security = await api.getSecurityHealth();
    expect(security['is_frozen'], isA<bool>());
  });
}
