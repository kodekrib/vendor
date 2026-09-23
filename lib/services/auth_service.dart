import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: '${json['id']}',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  String get firstName {
    final trimmed = name.trim();
    final space = trimmed.indexOf(' ');
    return space == -1 ? trimmed : trimmed.substring(0, space);
  }
}

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}

/// Result of requesting an OTP code, including the delivery channels used,
/// how long the code stays valid, and (when developer preview is enabled) the
/// code itself.
class SendOtpResult {
  const SendOtpResult({
    required this.expiresIn,
    required this.channels,
    this.devCode,
  });

  final int expiresIn;
  final List<String> channels;
  final String? devCode;

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 600,
      channels: (json['channels'] as List?)?.map((e) => '$e').toList() ??
          const <String>[],
      devCode: json['dev_code'] as String?,
    );
  }
}

/// Calls the marketgo-api auth endpoints (same shared API as the other apps).
class AuthService {
  AuthService({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  Future<TokenPair> signIn(String email, String password) async {
    final data = await api.post(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );
    return TokenPair.fromJson(data);
  }

  /// Requests a one-time code delivered over WhatsApp and/or email. The phone
  /// is sent as typed; the backend normalises it to international format.
  Future<SendOtpResult> sendOtp({
    required String phone,
    String? email,
    String? name,
    String role = 'onboarder',
  }) async {
    final data = await api.post(
      '/api/v1/auth/otp/send',
      body: <String, dynamic>{
        'phone': phone,
        'role': role,
        if (email != null && email.isNotEmpty) 'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    return SendOtpResult.fromJson(data);
  }

  /// Exchanges the received code for a token pair, creating the account on
  /// first sign-in for the given role.
  Future<TokenPair> verifyOtp({
    required String phone,
    required String code,
    String? name,
    String role = 'onboarder',
  }) async {
    final data = await api.post(
      '/api/v1/auth/otp/verify',
      body: <String, dynamic>{
        'phone': phone,
        'code': code,
        'role': role,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    return TokenPair.fromJson(data);
  }

  Future<AuthUser> me(String accessToken) async {
    final data = await api.get(
      '/api/v1/auth/me',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final user = data['user'];
    if (user is Map<String, dynamic>) return AuthUser.fromJson(user);
    throw const ApiException('Unexpected profile payload');
  }

  Future<void> signOut(String accessToken, String refreshToken) async {
    await api.post(
      '/api/v1/auth/logout',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {'refresh_token': refreshToken},
    );
  }
}

/// Singleton session that keeps the onboarder's token + profile in memory.
class OnboarderSession extends ChangeNotifier {
  OnboarderSession._();

  static final OnboarderSession instance = OnboarderSession._();

  final AuthService service = AuthService();
  AuthUser? _user;
  String? _accessToken;
  String? _refreshToken;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get accessToken => _accessToken;

  Future<bool> signIn(String email, String password) async {
    try {
      final tokens = await service.signIn(email.trim(), password);
      final user = await service.me(tokens.accessToken);
      _accessToken = tokens.accessToken;
      _refreshToken = tokens.refreshToken;
      _user = user;
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Requests an OTP code for the given phone. State for the request itself
  /// lives on the OTP screen.
  Future<SendOtpResult> sendOtp(String phone, {String? email}) {
    return service.sendOtp(phone: phone, email: email, role: 'onboarder');
  }

  /// Completes phone sign-in: verifies the code, loads the profile and enters
  /// an authenticated session.
  Future<bool> signInWithOtp(String phone, String code) async {
    try {
      final tokens = await service.verifyOtp(phone: phone, code: code);
      final user = await service.me(tokens.accessToken);
      _accessToken = tokens.accessToken;
      _refreshToken = tokens.refreshToken;
      _user = user;
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Server-less login so the app can be explored before the backend (or its
  /// database) is up. Enters an authenticated demo session immediately.
  void enterDemo() {
    _user = const AuthUser(
      id: 'demo-onboarder',
      email: 'onboarder@test.marketgo',
      name: 'Demo Onboarder',
      role: 'onboarder',
    );
    _accessToken = 'demo.access';
    _refreshToken = 'demo.refresh';
    notifyListeners();
  }

  Future<void> logOut() async {
    final token = _accessToken;
    final refresh = _refreshToken;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
    if (token != null && refresh != null) {
      try {
        await service.signOut(token, refresh);
      } catch (_) {}
    }
  }
}