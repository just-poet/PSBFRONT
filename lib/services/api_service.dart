import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'hardware_service.dart';

/// Raised when the backend is reachable but rejects the request, or cannot be
/// reached at all. Used by flows where silently returning mock data would be
/// wrong — sign-in above all.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  /// API address baked in at build time, for APKs handed to other people:
  ///
  ///   flutter build apk --dart-define=FINIX_BASE_URL=https://your-host
  ///
  /// An installed build then works on any network with no configuration. Empty
  /// when not supplied, in which case the per-platform default below is used.
  static const String compiledBaseUrl = String.fromEnvironment('FINIX_BASE_URL');

  /// Default API host, resolved per platform.
  ///
  /// On the Android emulator `localhost` is the emulated device itself, not the
  /// developer machine — the host is reachable at the special alias 10.0.2.2.
  /// Using `localhost` there means every request fails and the app silently
  /// falls back to mock data. Web/desktop keep localhost.
  ///
  /// A build-time FINIX_BASE_URL always wins. Otherwise the address can be
  /// changed at runtime from the sign-in screen (or via [setBaseUrl]); for a
  /// plain-HTTP host on a phone, add it to
  /// android/app/src/main/res/xml/network_security_config.xml — an https URL
  /// (e.g. a tunnel) needs no such exemption.
  static String get defaultBaseUrl {
    if (compiledBaseUrl.isNotEmpty) return compiledBaseUrl;
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  // Configuration
  String baseUrl = defaultBaseUrl;
  String? sessionToken;
  String? userId;
  String? deviceIdFingerprint;

  late final http.Client _client = _AuthAwareClient(this);
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  /// Flips to true when the backend rejects our token, so the UI can send the
  /// customer back to sign-in.
  ///
  /// Without this a stale token was indistinguishable from a working one: the
  /// backend regenerates its JWT signing secret on every restart, and access
  /// tokens only live 15 minutes, so a persisted token is very often dead. Each
  /// call would 401, fall into its `catch`/non-200 branch, and quietly return
  /// mock or empty data — leaving someone stuck on a broken-looking dashboard
  /// with no way to reach the login screen.
  final ValueNotifier<bool> sessionExpired = ValueNotifier<bool>(false);

  /// True while the account is frozen.
  ///
  /// Watched at the app root so the lock screen covers every route: a freeze
  /// that still let the customer browse and tap around would not be a freeze.
  final ValueNotifier<bool> accountFrozen = ValueNotifier<bool>(false);

  /// Bumped whenever anything on the server changed because of something the
  /// customer just did.
  ///
  /// Screens load in initState and never look again, so after a payment the
  /// dashboard kept showing the old net worth, the history kept its old rows
  /// and the balances were stale until the app was killed and reopened. The
  /// backend was right the whole time; the app simply never asked again.
  /// Screens watch this and re-read.
  final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  /// Call after any successful mutation.
  void notifyDataChanged() => dataVersion.value++;

  /// Called by [_AuthAwareClient] on any 401.
  void _handleUnauthorized() {
    if (sessionToken == null && !sessionExpired.value) return;
    expireSession();
  }

  /// Drops the session and sends the app back to sign-in.
  ///
  /// Shared by the 401 interceptor and the idle timeout so both end a session
  /// the same way, rather than each clearing a different subset of state.
  void expireSession() {
    clearSession();
    sessionExpired.value = true;
  }

  // SharedPreferences keys
  static const String _keyToken = 'finix_session_token';
  static const String _keyUserId = 'finix_user_id';
  static const String _keyBaseUrl = 'finix_base_url';
  static const String _keyUserName = 'finix_user_name';

  /// Display name of the signed-in customer.
  ///
  /// The dashboard, profile and personal-details screens previously hardcoded
  /// "Venkat A", so every account looked like the same person — with ten demo
  /// logins that is immediately visible. Nothing called getProfile(), so the
  /// app never knew who was signed in. The login response already carries the
  /// name, so it is captured there and exposed here for widgets to observe.
  final ValueNotifier<String?> userName = ValueNotifier<String?>(null);

  /// Uppercase initials for the avatar, derived from [userName].
  String get userInitials {
    final parts = (userName.value ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      sessionToken = prefs.getString(_keyToken);
      userId = prefs.getString(_keyUserId);
      userName.value = prefs.getString(_keyUserName);

      final stored = prefs.getString(_keyBaseUrl);
      if (compiledBaseUrl.isEmpty && stored != null) {
        baseUrl = stored;
      } else if (compiledBaseUrl.isNotEmpty && stored != compiledBaseUrl) {
        await prefs.setString(_keyBaseUrl, compiledBaseUrl);
      }
    } catch (e) {
      // Graceful fallback if SharedPreferences is not supported (web preview)
    }

    // A build-time FINIX_BASE_URL must beat whatever an earlier install stored.
    // Previously the stored value always won, so handing someone a new APK
    // pointing at a new tunnel changed nothing — the app kept calling the dead
    // URL from the previous build, which is indistinguishable from the backend
    // being down. Only a URL the user typed in themselves survives, and only
    // when this build did not pin one.
    //
    // Deliberately outside the try above: if SharedPreferences is unavailable
    // the compiled address is the only one we can trust, so it must still win.
    if (compiledBaseUrl.isNotEmpty) {
      baseUrl = compiledBaseUrl;
    }

    try {
      deviceIdFingerprint = await FinixHardware.getDeviceIdFingerprint();
    } catch (e) {
      deviceIdFingerprint = 'simulated-fingerprint-uuid';
    }

    // Perform background health check to verify connection
    checkConnection();
  }

  Future<void> setBaseUrl(String newUrl) async {
    baseUrl = newUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, newUrl);
    } catch (e) {}
    checkConnection();
  }

  Future<void> saveSession(String token, String uid, {String? name}) async {
    sessionToken = token;
    userId = uid;
    if (name != null && name.trim().isNotEmpty) {
      userName.value = name.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUserId, uid);
      if (userName.value != null) {
        await prefs.setString(_keyUserName, userName.value!);
      }
    } catch (e) {}
  }

  Future<void> clearSession() async {
    sessionToken = null;
    userId = null;
    userName.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
    } catch (e) {}
  }

  /// How long the health check waits before declaring the backend unreachable.
  ///
  /// This was 2 seconds, which is fine on a LAN but far too short once the API
  /// is reached over a tunnel or mobile data — a first request through a tunnel
  /// measured ~9s here (TLS plus cold relay). The app would report "offline"
  /// and every screen would silently render mock data against a backend that
  /// was working perfectly.
  static const Duration connectionTimeout = Duration(seconds: 15);

  Future<bool> checkConnection() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/healthz'))
          .timeout(connectionTimeout);

      final connected = response.statusCode == 200;
      isConnected.value = connected;
      return connected;
    } catch (_) {
      isConnected.value = false;
      return false;
    }
  }

  // ─── Headers and Helpers ───────────────────────────────────────────

  Map<String, String> _headers({bool requireAuth = true, bool isMutation = false}) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Device-Fingerprint': deviceIdFingerprint ?? '',
      // Free ngrok tunnels serve an HTML interstitial to anything it thinks is
      // a browser. If that ever fires, jsonDecode gets a chunk of HTML and the
      // failure surfaces as a mock-data fallback rather than a clear error, so
      // opt out explicitly instead of relying on the Dart user-agent.
      'ngrok-skip-browser-warning': 'true',
    };

    if (requireAuth && sessionToken != null) {
      headers['Authorization'] = 'Bearer $sessionToken';
    }

    if (isMutation) {
      headers['Idempotency-Key'] = _generateUuid();
    }

    return headers;
  }

  String _generateUuid() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // v4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  // ─── API Methods with Graceful Mock Fallbacks ─────────────────────

  // 1. Authentication
  
  Future<Map<String, dynamic>> register({
    String? name,
    required String mobile,
    String? email,
  }) async {
    final body = {
      if (name != null) 'name': name,
      'mobile': mobile,
      if (email != null) 'email': email,
      'deviceIdFingerprint': deviceIdFingerprint ?? 'simulated-fingerprint-uuid',
      'deviceType': 'Web/Android Simulator',
      'appVersion': '1.0.0',
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/auth/register'),
        headers: _headers(requireAuth: false, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isConnected.value = true;
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'userId': 'usr_mock_123456',
      'ubt': 'ubt_token_mock_abcdef',
    };
  }

  Future<Map<String, dynamic>> verifyEkyc({
    required String uid, // userId
    required String panLast4,
    required String aadhaarLast4,
  }) async {
    final body = {
      'userId': uid,
      'panLast4': panLast4,
      'aadhaarLast4': aadhaarLast4,
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/auth/ekyc/verify'),
        headers: _headers(requireAuth: false, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'id': 'kyc_mock_555',
      'name': 'Aditya Kumar',
      'ekycVerified': true,
      'kin': 'KIN-987654321',
    };
  }

  Future<Map<String, dynamic>> setupBiometric(String uid) async {
    final keyPair = await FinixBiometric.registerKeyPair();
    final body = {
      'userId': uid,
      'publicKeyB64': keyPair.publicKey,
      'keyId': keyPair.keyId,
      'deviceName': 'Chrome Web Attestation Agent',
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/auth/biometric/register'),
        headers: _headers(requireAuth: false, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'id': uid,
      'biometricEnabled': true,
    };
  }

  Future<Map<String, dynamic>> setPin(String pin) async {
    final body = {'pin': pin};
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/auth/login/pin/set'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {'status': 'pin_set'};
  }

  Future<Map<String, dynamic>> loginWithPin(String uid, String pin) async {
    final body = {'userId': uid, 'pin': pin};
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/auth/login/pin'),
        headers: _headers(requireAuth: false, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isConnected.value = true;
        final data = jsonDecode(response.body);
        if (data['accessToken'] != null) {
          await saveSession(data['accessToken'], uid);
        }
        return data;
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    final mockToken = 'swt_mock_token_jwt_${Random().nextInt(1000000)}';
    await saveSession(mockToken, uid);
    return {
      'accessToken': mockToken,
      'expiresInSeconds': 900,
    };
  }

  /// Signs in with the 10-digit Central KYC number and the 6-digit PIN.
  ///
  /// This is the app's primary login: no phone number is involved, so a demo
  /// works without any real mobile. The backend resolves the CKYC to an account
  /// and returns a short-lived JWT, which is stored for subsequent calls.
  ///
  /// Throws [ApiException] on a rejected login so the UI can show the reason —
  /// unlike the read-only getters, a failed sign-in must NOT fall through to
  /// mock data and pretend the user is authenticated.
  /// Signs in with a mobile number.
  ///
  /// The backend already resolved accounts by mobile; it just needed the
  /// number in canonical form, which it now normalises. A customer types ten
  /// digits, not a country code.
  Future<Map<String, dynamic>> loginWithPhone(String phone, String pin) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/v1/auth/login/pin'),
      headers: _headers(requireAuth: false, isMutation: true),
      body: jsonEncode({
        'mobile': phone.trim(),
        'pin': pin,
        'deviceIdFingerprint': deviceIdFingerprint ?? '',
      }),
    );

    if (response.statusCode != 200) {
      isConnected.value = false;
      throw ApiException(
          _errorMessage(response.body, 'Invalid mobile number or PIN.'));
    }

    isConnected.value = true;
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = (decoded['accessToken'] ?? '').toString();
    final uid = (decoded['userId'] ?? '').toString();
    if (token.isEmpty || uid.isEmpty) {
      throw ApiException('Sign-in failed. Please try again.');
    }
    await saveSession(token, uid, name: decoded['name'] as String?);
    return decoded;
  }

  Future<Map<String, dynamic>> loginWithCkyc(String ckyc, String pin) async {
    final body = {
      'ckyc': ckyc.trim(),
      'pin': pin.trim(),
      'deviceIdFingerprint': deviceIdFingerprint ?? '',
      'deviceType': 'Android',
      'appVersion': '1.0.0',
    };

    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/v1/auth/login/pin'),
            headers: _headers(requireAuth: false, isMutation: true),
            body: jsonEncode(body),
          )
          .timeout(connectionTimeout);
    } catch (_) {
      isConnected.value = false;
      throw ApiException(
        'Cannot reach the FINIX server. Check that the backend is running '
        'and the API address is correct.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      isConnected.value = true;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['accessToken'];
      final uid = data['userId'];
      if (token is String && uid is String) {
        await saveSession(token, uid, name: data['name']?.toString());
      }
      return data;
    }

    isConnected.value = true; // reachable, just rejected
    throw ApiException(_errorMessage(response.body, 'Invalid CKYC number or PIN.'));
  }

  /// Pulls a human-readable message out of the backend's {"error": "..."} body.
  String _errorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        final msg = (decoded['error'] as String).trim();
        if (msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return fallback;
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/auth/profile'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'userId': userId ?? 'usr_mock_123456',
      'fullName': 'Aditya Kumar',
      'mobileNumber': '9876543210',
      'email': 'aditya.kumar@example.com',
      'kycVerified': true,
      'biometricEnabled': true,
    };
  }

  // 2. Portfolio & Net Worth
  
  /// KYC-locked identity: legal name, DOB, masked PAN/Aadhaar, KYC status and
  /// date, occupation and declared income. Feeds the Personal Details screen,
  /// which previously hardcoded a name, DOB, PAN and address.
  /// The tamper-evident audit trail: real sign-ins, freezes, payment decisions.
  /// The screen previously rendered a fixed list of invented events.
  /// Scans one message for phishing signals.
  ///
  /// Returns the backend verdict: badge (green/amber/red), a plain-English
  /// reason, the phishing indicators found and any URL scan result. Returns an
  /// empty map when the scan cannot be performed, so callers show "not scanned"
  /// rather than a false all-clear.
  Future<Map<String, dynamic>> scanSms({
    required String sender,
    required String message,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/security/sms/scan'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode({'sender': sender, 'message': message}),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return const {};
  }

  /// Asks the backend to issue a one-time code for a step-up.
  ///
  /// In a demo build the response carries the code itself, because there is no
  /// SMS gateway; in production it only confirms that an SMS was sent.
  /// Verifies the customer's PIN.
  ///
  /// The PIN entry screen accepted any six digits — it never checked them — so
  /// the app's own PIN gate was decorative and an unfreeze or a payment could
  /// be authorised by anyone holding the phone. There is no dedicated verify
  /// endpoint, so this re-authenticates with the signed-in customer's cKYC:
  /// the backend hashes and compares the PIN, and a wrong one fails.
  ///
  /// A success also refreshes the session token, which is harmless and keeps a
  /// long-running session alive.
  Future<bool> verifyPin(String pin) async {
    try {
      final profile = await getProfile();
      final ckyc = (profile['ckyc'] ?? '').toString();
      if (ckyc.isEmpty) return false;

      final response = await _client.post(
        Uri.parse('$baseUrl/v1/auth/login/pin'),
        headers: _headers(requireAuth: false, isMutation: true),
        body: jsonEncode({'ckyc': ckyc, 'pin': pin}),
      );
      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final token = (decoded['accessToken'] ?? '').toString();
      final uid = (decoded['userId'] ?? '').toString();
      if (token.isNotEmpty && uid.isNotEmpty) {
        await saveSession(token, uid, name: decoded['name'] as String?);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Records the tax regime the customer chose.
  ///
  /// The screen said "applied" but nothing was stored, so reopening it showed
  /// the old regime and the old liability.
  Future<bool> setTaxRegime(String regime) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/tax/regime'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode({'regime': regime}),
      );
      if (response.statusCode == 200) {
        notifyDataChanged();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Records an accepted what-if simulation.
  Future<bool> applySimulation({
    required String scenario,
    String summary = '',
    int deltaPaise = 0,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/simulations/apply'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode({
          'scenario': scenario,
          'summary': summary,
          'deltaPaise': deltaPaise,
        }),
      );
      if (response.statusCode == 200) {
        notifyDataChanged();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> generateOtp() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/auth/otp/generate'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return const {};
  }

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/audit/logs'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    isConnected.value = false;
    return const [];
  }

  /// The notification feed, derived by the backend from this customer's own
  /// activity. Genuinely empty for an account that has done nothing.
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/notifications'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    isConnected.value = false;
    return const [];
  }

  Future<Map<String, dynamic>> getKycProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/kyc/profile'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    isConnected.value = false;
    return const {};
  }

  Future<Map<String, dynamic>> getNetWorth() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/portfolio/net-worth'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'totalAssets': 255265000,      // in paise (₹2,552,650)
      'totalLiabilities': 6500000,    // in paise (₹65,000)
      'netWorth': 248765000,         // in paise (₹2,487,650)
      'assets': [
        {'name': 'Mutual Funds', 'valuePaise': 125000000},
        {'name': 'Direct Stocks', 'valuePaise': 80000000},
        {'name': 'Bank Accounts', 'valuePaise': 45265000},
        {'name': 'Gold (Digital)', 'valuePaise': 5000000},
      ],
      'liabilities': [
        {'name': 'Car Loan', 'valuePaise': 4500000},
        {'name': 'Credit Cards', 'valuePaise': 2000000},
      ]
    };
  }

  Future<Map<String, dynamic>> getHealthScore() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/health-score'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'score300To900': 785,
      'band': 'Excellent',
      'pillars': [
        {'name': 'Emergency Fund', 'score': 90, 'status': 'Optimal', 'metric': '4.5 months'},
        {'name': 'Debt-to-Income', 'score': 85, 'status': 'Healthy', 'metric': '12.4%'},
        {'name': 'Savings Rate', 'score': 78, 'status': 'Moderate', 'metric': '24%'},
        {'name': 'Diversification', 'score': 72, 'status': 'Healthy', 'metric': '72/100'},
        {'name': 'Insurance Coverage', 'score': 68, 'status': 'Under-insured', 'metric': '68/100'},
        {'name': 'Goals Alignment', 'score': 88, 'status': 'On Track', 'metric': '70%'},
      ],
      'recommendations': [
        'Increase insurance coverage to cover at least 10x your annual income.',
        'Diversify stock portfolio by adding international or commodity ETFs.',
        'Establish automated micro-saves to boost savings rate to 30%.'
      ]
    };
  }

  /// Market snapshot shown on the dashboard: index levels, gold, repo rate and
  /// the modelled impact on this customer's portfolio.
  Future<Map<String, dynamic>> getMarketSnapshot() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/v1/dashboard/market-snapshot'), headers: _headers())
          .timeout(connectionTimeout);
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Mock fallback keeps the card populated when offline.
    isConnected.value = false;
    return {
      'sensex': 75180.42,
      'nifty': 22831.11,
      'goldPer10g': 74250,
      'repoRate': 6.5,
      'portfolioImpactPaise': 0,
      'xai': 'Market data unavailable while offline.',
    };
  }

  /// Personalised insight feed. The dashboard shows the highest-priority entry.
  Future<List<Map<String, dynamic>>> getInsightsFeed() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/v1/insights/feed'), headers: _headers())
          .timeout(connectionTimeout);
      if (response.statusCode == 200) {
        isConnected.value = true;
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    isConnected.value = false;
    return [
      {
        'title': 'Insights unavailable',
        'body': 'Connect to the FINIX server to see personalised insights.',
        'reason': 'Offline',
      }
    ];
  }

  // 3. Bank Accounts & Aggregator
  
  Future<List<Map<String, dynamic>>> getAccounts() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/accounts'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final List<dynamic> list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return [
      {
        'accountId': 'acc_sbi_01',
        'bankName': 'State Bank of India',
        'balance': 28745000, // paise (₹2,87,450)
        'accountType': 'Savings',
        'upiId': 'aditya@sbi',
        'accountNumber': '*******5421',
        'ifscCode': 'SBIN0001234'
      },
      {
        'accountId': 'acc_hdfc_01',
        'bankName': 'HDFC Bank',
        'balance': 18472000, // paise (₹1,84,720)
        'accountType': 'Savings',
        'upiId': 'aditya@hdfc',
        'accountNumber': '*******9088',
        'ifscCode': 'HDFC0000123'
      },
      {
        'accountId': 'acc_icici_01',
        'bankName': 'ICICI Bank',
        'balance': 8425000, // paise (₹84,250)
        'accountType': 'Savings',
        'upiId': 'aditya@icici',
        'accountNumber': '*******2211',
        'ifscCode': 'ICIC0000456'
      },
      {
        'accountId': 'acc_axis_01',
        'bankName': 'Axis Bank',
        'balance': 2850000, // paise (₹28,500)
        'accountType': 'Current',
        'upiId': 'aditya@axis',
        'accountNumber': '*******8765',
        'ifscCode': 'UTIB0000789'
      }
    ];
  }

  Future<Map<String, dynamic>> linkAccount({
    required String bankName,
    required String upiId,
    required String accountNumber,
    required String ifscCode,
    required String accountType,
    required String holderName,
  }) async {
    final body = {
      'accountHolderName': holderName,
      'bankName': bankName,
      'upiId': upiId,
      'maskedAccount': accountNumber.length > 4 
          ? '*******${accountNumber.substring(accountNumber.length - 4)}' 
          : accountNumber,
      'ifscCode': ifscCode,
      'accountType': accountType,
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/accounts/link'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Something changed server-side; tell every screen to re-read.
        notifyDataChanged();
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'accountId': 'acc_${bankName.toLowerCase().replaceAll(' ', '_')}_${Random().nextInt(100)}',
      'bankName': bankName,
      'balance': 5000000, // default ₹50,000 in paise
      'accountType': accountType,
      'upiId': upiId,
      'accountNumber': body['maskedAccount'],
      'ifscCode': ifscCode,
    };
  }

  Future<List<Map<String, dynamic>>> getBeneficiaries() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/beneficiaries'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final List<dynamic> list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return [
      {'beneficiaryId': 'ben_1', 'name': 'Akash Patel', 'upiId': 'akash@ybl', 'trustScore': 98},
      {'beneficiaryId': 'ben_2', 'name': 'Pooja Roy', 'upiId': 'pooja@okhdfc', 'trustScore': 95},
      {'beneficiaryId': 'ben_3', 'name': 'Venkat Raman', 'upiId': 'venkat@icici', 'trustScore': 87},
      {'beneficiaryId': 'ben_4', 'name': 'Jiyad', 'upiId': 'jiyad@sbi', 'trustScore': 99},
    ];
  }

  Future<Map<String, dynamic>> addBeneficiary({
    required String name,
    required String upiId,
    String relationship = 'Friend',
  }) async {
    final body = {
      'beneficiaryName': name,
      'upiIdOrBankDetails': upiId,
      'relationshipDescription': relationship,
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/beneficiaries'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'beneficiaryId': 'ben_${Random().nextInt(1000)}',
      'name': name,
      'upiId': upiId,
      'trustScore': 92,
      'relationship': relationship,
      'verificationStatus': 'verified'
    };
  }

  // 4. Transactions & Payments
  
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/transactions/history'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final List<dynamic> list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return [
      {
        'id': 'txn_01',
        'merchantName': 'Zomato Food Delivery',
        'category': 'Food & Dining',
        'amountPaise': 74500, // ₹745.00
        'type': 'debit',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'txn_02',
        'merchantName': 'Salary Credited',
        'category': 'Income',
        'amountPaise': 18000000, // ₹1,80,000.00
        'type': 'credit',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'txn_03',
        'merchantName': 'Airtel Broadband Payment',
        'category': 'Utilities',
        'amountPaise': 117900, // ₹1,179.00
        'type': 'debit',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 'txn_04',
        'merchantName': 'Gold SIP Contribution',
        'category': 'Investment',
        'amountPaise': 500000, // ₹5,000.00
        'type': 'debit',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      }
    ];
  }

  Future<Map<String, dynamic>> initiateTransaction({
    required int amountPaise,
    required String recipient,
    required String channel,
  }) async {
    final body = {
      'amountPaise': amountPaise,
      'recipient': recipient,
      'channel': channel,
      // Client-side heuristics mapping to backend risk signals (see ref)
      'sessionTrustScore': 95,
      'behaviourDrift': 2,
      'failedPinAttempts': 0,
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/transactions/initiate'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Something changed server-side; tell every screen to re-read.
        notifyDataChanged();
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback: Trigger stepUpRequired for large amounts (> ₹10,000)
    isConnected.value = false;
    final isLargeTxn = amountPaise > 1000000;
    return {
      'transactionId': 'txn_${Random().nextInt(100000)}',
      'status': isLargeTxn ? 'warning_ack_required' : 'success',
      'riskLevel': isLargeTxn ? 'high' : 'low',
      'stepUpRequired': isLargeTxn,
      'xaiReason': isLargeTxn ? 'Amount is 4x your daily average; new recipient detected.' : 'Transaction normal.',
    };
  }

  Future<Map<String, dynamic>> overrideTransaction({
    required String transactionId,
    required String otp,
    required bool biometricOk,
  }) async {
    final body = {
      'transactionId': transactionId,
      'otp': otp,
      'biometricOk': biometricOk,
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/transactions/override'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Something changed server-side; tell every screen to re-read.
        notifyDataChanged();
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'status': 'success',
      'message': 'Transaction verified and approved via secure step-up.'
    };
  }

  // 5. Goals
  
  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/goals'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final List<dynamic> list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return [
      {
        'goalId': 'goal_01',
        'name': 'Emergency Reserve Fund',
        'description': 'Keep 6 months of living expenses secure.',
        'targetAmountPaise': 30000000, // ₹3,00,000
        'savedAmountPaise': 22500000,  // ₹2,25,000
        'targetDate': DateTime.now().add(const Duration(days: 120)).toIso8601String(),
        'monthlyContributionPaise': 1500000,
        'frequency': 'monthly',
        'priority': 'high',
        'status': 'active',
        'progressPercent': 75.0,
      },
      {
        'goalId': 'goal_02',
        'name': 'Down Payment - Electric Car',
        'description': 'Targeting ₹5L by mid next year.',
        'targetAmountPaise': 50000000, // ₹5,00,000
        'savedAmountPaise': 15000000,  // ₹1,50,000
        'targetDate': DateTime.now().add(const Duration(days: 300)).toIso8601String(),
        'monthlyContributionPaise': 2500000,
        'frequency': 'monthly',
        'priority': 'medium',
        'status': 'active',
        'progressPercent': 30.0,
      }
    ];
  }

  Future<Map<String, dynamic>> createGoal({
    required String name,
    required String description,
    required int targetAmountPaise,
    required String targetDate,
    required int monthlyContributionPaise,
    required String priority,
  }) async {
    final body = {
      'name': name,
      'description': description,
      'targetAmountPaise': targetAmountPaise,
      'targetDate': targetDate,
      'monthlyContributionPaise': monthlyContributionPaise,
      'frequency': 'monthly',
      'priority': priority,
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/goals'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Something changed server-side; tell every screen to re-read.
        notifyDataChanged();
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'goalId': 'goal_${Random().nextInt(10000)}',
      'name': name,
      'description': description,
      'targetAmountPaise': targetAmountPaise,
      'savedAmountPaise': 0,
      'targetDate': targetDate,
      'monthlyContributionPaise': monthlyContributionPaise,
      'frequency': 'monthly',
      'priority': priority,
      'status': 'active',
      'progressPercent': 0.0,
    };
  }

  Future<Map<String, dynamic>> contributeToGoal(String goalId, int amountPaise) async {
    final body = {'amountPaise': amountPaise};
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/goals/$goalId/contribute'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Something changed server-side; tell every screen to re-read.
        notifyDataChanged();
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {'status': 'success'};
  }

  Future<Map<String, dynamic>> pauseGoal(String goalId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/goals/$goalId/pause'),
        headers: _headers(requireAuth: true, isMutation: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}
    isConnected.value = false;
    return {'status': 'paused'};
  }

  Future<Map<String, dynamic>> resumeGoal(String goalId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/goals/$goalId/resume'),
        headers: _headers(requireAuth: true, isMutation: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}
    isConnected.value = false;
    return {'status': 'active'};
  }

  Future<Map<String, dynamic>> dissolveGoal(String goalId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/goals/$goalId/dissolve'),
        headers: _headers(requireAuth: true, isMutation: true),
      );
      if (response.statusCode == 200) {
        // Something changed server-side; tell every screen to re-read.
        notifyDataChanged();
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}
    isConnected.value = false;
    return {'status': 'dissolved'};
  }

  // 6. AI Chatbot
  
  Future<Map<String, dynamic>> chatbotQuery({
    required String prompt,
    String? chatId,
  }) async {
    final body = {
      'chatId': chatId ?? 'default_chat_id_63e9615c',
      'prompt': prompt,
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/chatbot/query'),
        headers: _headers(requireAuth: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    String reply = "I am processing your request. It looks like the FINIX AI RAG Service is currently offline. As a fallback: ";
    List<String> suggestions = [];
    
    final pLower = prompt.toLowerCase();
    if (pLower.contains('npa') || pLower.contains('sbi')) {
      reply += "As of the latest reports, State Bank of India (SBI) reported a Gross NPA ratio of 2.42%, indicating strong asset quality and robust risk management controls.";
      suggestions = ["Compare with HDFC", "What are NPAs?", "View Risk Graph"];
    } else if (pLower.contains('tax') || pLower.contains('regime')) {
      reply += "Under the new tax regime (FY 2026-27), tax slabs are structured to benefit middle-income earners. The rebate limit under section 87A has been enhanced, making income up to ₹7,00,000 completely tax-free.";
      suggestions = ["Old vs New Slabs", "Calculate my tax", "List 80C options"];
    } else {
      reply += "I'm your secure AI financial assistant. I can help you analyze your portfolio, calculate tax under the Old vs New regime, track security logs, or optimize loans. Please let me know how I can guide you today.";
      suggestions = ["Optimize Loans", "Tax Dashboard", "Security Health"];
    }

    return {
      'messageId': 'msg_${Random().nextInt(100000)}',
      'content': reply,
      'suggestions': suggestions,
      'confidenceScore': 0.90,
    };
  }

  // 7. Security Controls
  
  /// Refreshes [accountFrozen] from the backend's own state.
  Future<void> refreshFreezeState() async {
    final health = await getSecurityHealth();
    if (health['is_frozen'] is bool) {
      accountFrozen.value = health['is_frozen'] as bool;
    }
  }

  Future<Map<String, dynamic>> getSecurityHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/security/health'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'account_frozen': false,
      'compliance_status': 'Compliant',
      'last_security_scan_at': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> emergencyFreeze(String reason) async {
    final body = {
      'reason': reason,
      'verificationMethod': 'biometric'
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/security/emergency-freeze'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Something changed server-side; tell every screen to re-read.
        notifyDataChanged();
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {'status': 'frozen'};
  }

  Future<Map<String, dynamic>> unfreeze() async {
    final body = {'verificationMethod': 'biometric'};
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/v1/security/unfreeze'),
        headers: _headers(requireAuth: true, isMutation: true),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Something changed server-side; tell every screen to re-read.
        notifyDataChanged();
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {'status': 'active'};
  }

  // 8. Tax Centre
  
  Future<Map<String, dynamic>> getTaxDashboard() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/tax/dashboard'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'taxableIncome': 240000000, // ₹24,00,000 in paise
      'taxPayable': 32000000,    // ₹3,20,000 in paise
      'deductions': 45000000,     // ₹4,50,000 in paise
      'regime': 'new',
    };
  }

  /// Section-wise 80C/80D/24(b)/etc. usage against each limit. The tax screen
  /// used to hardcode four sections with fixed amounts.
  Future<List<Map<String, dynamic>>> getTaxDeductions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/tax/deductions'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
        final list = decoded['deductions'];
        if (list is List) return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    isConnected.value = false;
    return const [];
  }

  Future<Map<String, dynamic>> getTaxRegimeComparison() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/tax/regime-compare'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'oldRegime': {
        'taxableIncome': 195000000,
        'taxPayable': 40500000,
        'deductions': 45000000,
      },
      'newRegime': {
        'taxableIncome': 240000000,
        'taxPayable': 32000000,
        'deductions': 0,
      },
      'recommended': 'new'
    };
  }

  // 9. Portfolio Subcomponents
  
  Future<List<Map<String, dynamic>>> getInvestments() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/portfolio/investments'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return [
      {
        'id': 'inv_01',
        'name': 'HDFC Bluechip Fund Growth',
        'category': 'Mutual Fund',
        'units': 2450.45,
        'currentValuePaise': 24870000,
        'avgPurchasePricePaise': 8150,
        'SIPAmountPaise': 500000,
      },
      {
        'id': 'inv_02',
        'name': 'Nippon India Small Cap',
        'category': 'Mutual Fund',
        'units': 1120.12,
        'currentValuePaise': 18450000,
        'avgPurchasePricePaise': 12000,
        'SIPAmountPaise': 300000,
      },
    ];
  }

  Future<Map<String, dynamic>> getInsurance() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/portfolio/insurance'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return {
      'totalLifeCoverPaise': 10000000000, // 1 Crore in paise
      'totalHealthCoverPaise': 100000000,  // 10 Lakhs in paise
      'policies': [
        {
          'id': 'pol_01',
          'provider': 'HDFC Ergo',
          'type': 'Health Insurance',
          'coverAmountPaise': 100000000,
          'premiumPaise': 1850000,
          'dueDate': '2026-12-15T12:00:00Z',
        },
        {
          'id': 'pol_02',
          'provider': 'LIC of India',
          'type': 'Term Life Insurance',
          'coverAmountPaise': 10000000000,
          'premiumPaise': 2400000,
          'dueDate': '2026-11-20T12:00:00Z',
        }
      ]
    };
  }

  Future<List<Map<String, dynamic>>> getLoans() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/portfolio/loans'),
        headers: _headers(requireAuth: true),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Mock Fallback
    isConnected.value = false;
    return [
      {
        'loanId': 'loan_01',
        'lender': 'SBI Home Finance',
        'outstandingPaise': 452485000, // ₹45,24,850 in paise
        'emiPaise': 3850000,           // ₹38,500 in paise
        'interestRate': 8.4,
        'tenureRemainingMonths': 144,
      },
      {
        'loanId': 'loan_02',
        'lender': 'HDFC Auto Loan',
        'outstandingPaise': 68500000,  // ₹6,85,000 in paise
        'emiPaise': 1420000,           // ₹14,200 in paise
        'interestRate': 9.2,
        'tenureRemainingMonths': 36,
      }
    ];
  }
}

/// Wraps every HTTP call so a rejected token is noticed once, centrally.
///
/// The alternative was checking `statusCode == 401` at ~30 call sites, each of
/// which already had a `catch`/non-200 branch that returned mock data. Sitting
/// under all of them means no future call site can forget.
class _AuthAwareClient extends http.BaseClient {
  _AuthAwareClient(this._api);

  final ApiService _api;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401) {
      // The refresh endpoint 401ing means the refresh token is dead too, so
      // there is nothing left to recover with.
      _api._handleUnauthorized();
    }
    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
