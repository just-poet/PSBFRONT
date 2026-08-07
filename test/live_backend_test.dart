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

  test('screens that were hardcoded per-customer now resolve from the session',
      () async {
    await api.loginWithCkyc('2000000001', '123456');

    // Personal Details: name, DOB, masked PAN and Aadhaar were literals
    // ("Venkat Avva", 18/09/2002). They have to come off the KYC record.
    final kyc = await api.getKycProfile();
    expect(kyc['fullName'].toString(), isNotEmpty);
    expect(kyc['panMasked'].toString(), isNotEmpty);
    expect(kyc['aadhaarMaskedOrHash'].toString(), isNotEmpty);
    expect(kyc['kycStatus'].toString(), isNotEmpty);
    // A full Aadhaar or PAN must never reach the client.
    expect(kyc['aadhaarMaskedOrHash'].toString(), contains('XXXX'));

    // Loans: the two cards were a fixed PSB home loan and an HDFC vehicle loan.
    final loans = await api.getLoans();
    for (final loan in loans) {
      expect(loan['outstandingPaise'], isA<int>());
      expect(loan['emiPaise'], isA<int>());
      expect(loan['interestRate'], isA<num>());
      expect(loan['remainingMonths'], isA<int>());
    }

    // Insurance: cards were an LIC term plan and a Star Health floater.
    final insurance = await api.getInsurance();
    final policies = (insurance['policies'] as List?) ?? const [];
    expect(insurance['totalCoverPaise'], isA<int>());
    for (final raw in policies) {
      final policy = Map<String, dynamic>.from(raw as Map);
      expect(policy['insurer'].toString(), isNotEmpty);
      expect(policy['sumAssuredPaise'], isA<int>());
      expect(policy['premiumPaise'], isA<int>());
    }

    // Health score: seven pillars with fixed scores (85, 92, 78...) and fixed
    // prose. The screen now renders whatever the API returns, so each pillar
    // needs a name, a score and a weight.
    final health = await api.getHealthScore();
    final pillars = (health['pillars'] as List).cast<Map<String, dynamic>>();
    expect(pillars, isNotEmpty);
    for (final pillar in pillars) {
      expect(pillar['name'].toString(), isNotEmpty);
      expect(pillar['score'], isA<num>());
      expect(pillar['weight'], isA<num>());
    }
    expect(health['band'].toString(), isNotEmpty);

    // Tax centre: four deduction cards with fixed amounts against fixed limits.
    final deductions = await api.getTaxDeductions();
    expect(deductions, isNotEmpty);
    for (final deduction in deductions) {
      expect(deduction['section'].toString(), isNotEmpty);
      expect(deduction['usedPaise'], isA<int>());
      expect(deduction['limitPaise'], isA<int>());
      // The screen divides by the limit for the progress bar.
      expect(deduction['limitPaise'] as int, greaterThan(0));
    }

    // Pay Anyone: recents and contacts were a fixed roster of six people, so
    // any user could tap through to a stranger's UPI ID.
    final beneficiaries = await api.getBeneficiaries();
    for (final beneficiary in beneficiaries) {
      final name =
          (beneficiary['beneficiaryName'] ?? beneficiary['name'] ?? '').toString();
      final upi =
          (beneficiary['upiIdOrBankDetails'] ?? beneficiary['upiId'] ?? '')
              .toString();
      expect(name.isNotEmpty || upi.isNotEmpty, isTrue,
          reason: 'a payee with neither a name nor a handle cannot be rendered');
    }

    // To-Self transfer names two of the customer's own accounts.
    final accounts = await api.getAccounts();
    for (final account in accounts) {
      expect(account['bankName'].toString(), isNotEmpty);
      expect(account['balancePaise'], isA<int>());
    }
  });

  test('a dead token is cleared instead of silently returning mock data',
      () async {
    // This is what stranded a tester: the backend rotates its JWT signing
    // secret on restart and access tokens expire after 15 minutes, so a
    // persisted token is very often invalid. Every call 401'd, each fell into
    // its mock-data branch, and the app sat on a broken dashboard with no route
    // back to sign-in.
    await api.loginWithCkyc('2000000001', '123456');
    expect(api.sessionToken, isNotNull);

    api.sessionExpired.value = false;
    // A structurally valid but wrongly-signed token, i.e. what a token issued
    // by a previous backend run looks like.
    api.sessionToken = '${api.sessionToken}tampered';

    await api.getNetWorth();

    expect(api.sessionExpired.value, isTrue,
        reason: 'a 401 must be surfaced, not swallowed');
    expect(api.sessionToken, isNull,
        reason: 'the dead token must be cleared so the app returns to sign-in');
  });

  test('a build-time base URL wins over one stored by an earlier install',
      () async {
    // Handing out a new APK pointing at a new tunnel used to change nothing:
    // init() preferred the stored URL, so the app kept calling the dead host
    // from the previous build.
    if (ApiService.compiledBaseUrl.isEmpty) {
      markTestSkipped('needs --dart-define=FINIX_BASE_URL');
      return;
    }
    await api.setBaseUrl('https://stale-host-from-a-previous-build.invalid');
    await api.init();
    expect(api.baseUrl, ApiService.compiledBaseUrl);
  });

  test('health score is computed per customer, not a shared constant',
      () async {
    // Six of the seven pillar inputs were literals in the backend
    // (emergencyFundMonths 4.5, savingsRate 0.24, diversification 72,
    // protection 68, behaviour 74, and a fixed six-month history), so every
    // customer scored within a point or two of 744.
    final scores = <String, int>{};
    final originalDevice = api.deviceIdFingerprint;
    for (final ckyc in ['2000000001', '2000000002', '2000000003']) {
      // Each customer signs in from their own handset. Cycling several
      // accounts through one fingerprint trips the backend's device binding,
      // which then refuses subsequent logins on that device — correct
      // behaviour, but it would make this test poison the ones after it.
      api.deviceIdFingerprint = 'healthscore-$ckyc';
      await api.loginWithCkyc(ckyc, '123456');
      final health = await api.getHealthScore();

      final score = (health['score300To900'] as num).toInt();
      expect(score, inInclusiveRange(300, 900));
      scores[ckyc] = score;

      final pillars = (health['pillars'] as List).cast<Map<String, dynamic>>();
      expect(pillars.length, 7);
      for (final pillar in pillars) {
        final value = (pillar['score'] as num).toDouble();
        expect(value.isNaN, isFalse, reason: '${pillar['name']} is NaN');
        expect(value, inInclusiveRange(0, 100));
      }
    }

    api.deviceIdFingerprint = originalDevice;

    expect(scores.values.toSet().length, greaterThan(1),
        reason: 'different customers must not all score the same: $scores');
  });

  test('market snapshot carries live index levels', () async {
    await api.loginWithCkyc('2000000001', '123456');
    final market = await api.getMarketSnapshot();

    expect(market['sensex'], isA<num>());
    expect(market['nifty'], isA<num>());

    // Sensex and Nifty were pinned at 75180.42 and 22831.11 for everyone. The
    // exact level cannot be asserted, but a plausible range can, and the
    // backend now reports whether the figures came from upstream.
    expect((market['sensex'] as num).toDouble(), greaterThan(10000));
    expect((market['nifty'] as num).toDouble(), greaterThan(5000));
    expect(market['live'], isA<bool>(),
        reason: 'the app must be able to tell live data from the fallback');

    if (market['live'] == true) {
      // A real feed moves; the hardcoded one never did.
      expect(market['sensexChangePercent'], isA<num>());
      expect(market['niftyChangePercent'], isA<num>());
    }
  });

  test('notifications and audit log reflect real activity', () async {
    await api.loginWithCkyc('2000000001', '123456');

    // The audit trail was already real; the screen just never called it.
    final audit = await api.getAuditLogs();
    expect(audit, isNotEmpty);
    expect(audit.first['eventType'].toString(), isNotEmpty);
    expect(DateTime.tryParse(audit.first['timestamp'].toString()), isNotNull);

    // The feed used to be a fixed list in the app; the backend's notification
    // centre existed but nothing ever wrote to it, so it always returned [].
    final notifications = await api.getNotifications();
    expect(notifications, isNotEmpty,
        reason: 'a seeded customer with payments and goals should have notices');
    for (final n in notifications) {
      expect(n['title'].toString(), isNotEmpty);
      expect(n['category'].toString(), isNotEmpty);
      expect(DateTime.tryParse(n['createdAt'].toString()), isNotNull);
      expect(['info', 'warning', 'critical'], contains(n['severity']));
    }

    // Ordinary low-risk payments must not all be flagged: RiskScore is 0-100,
    // and comparing it against 0.7 marked every payment as suspicious.
    final payments =
        notifications.where((n) => n['category'] == 'transactions').toList();
    if (payments.isNotEmpty) {
      expect(payments.every((n) => n['severity'] == 'warning'), isFalse,
          reason: 'not every payment is risky');
    }
  });

  test('SMS scanner returns a real verdict', () async {
    await api.loginWithCkyc('2000000001', '123456');

    final phishing = await api.scanSms(
      sender: 'VM-HDFCBK',
      message: 'Your account is blocked. Click http://bit.ly/x to reactivate now',
    );
    expect(phishing['badge'], 'red');
    expect(phishing['reason'].toString(), isNotEmpty);
    expect(phishing['phishingIndicators'], isA<List>());

    // A benign message must not be flagged, or the scanner is worthless.
    final benign = await api.scanSms(
      sender: 'AX-AXISBK',
      message: 'OTP for txn of INR 10,000.00 is 482910. Do not share with anyone.',
    );
    expect(benign['badge'], isNot('red'));
  });
}
