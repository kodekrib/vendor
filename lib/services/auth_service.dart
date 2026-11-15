import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Formats the delivery channels reported by the OTP API for display, e.g.
/// "SMS", "WhatsApp" or "email and SMS". Returns an empty string when the
/// server did not report any channel.
String describeOtpChannels(List<String> channels) {
  const order = ['email', 'whatsapp', 'sms'];
  const labels = {'email': 'email', 'whatsapp': 'WhatsApp', 'sms': 'SMS'};
  final parts = [
    for (final key in order)
      if (channels.contains(key)) labels[key]!,
  ];
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first;
  return '${parts.take(parts.length - 1).join(', ')} and ${parts.last}';
}

class AuthUser {
  const AuthUser({
    this.avatarUrl = '',
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String avatarUrl;
  final String id;
  final String email;
  final String name;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      avatarUrl: json['avatar_url'] as String? ?? '',
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

class MfaChallenge {
  const MfaChallenge({
    required this.mfaToken,
    required this.expiresIn,
    this.codeLength = 6,
    required this.channels,
    this.devCode,
  });

  final String mfaToken;
  final int expiresIn;
  final int codeLength;
  final List<String> channels;
  final String? devCode;

  factory MfaChallenge.fromJson(Map<String, dynamic> json) {
    return MfaChallenge(
      mfaToken: json['mfa_token'] as String? ?? '',
      codeLength:
          ((json['code_length'] as num?)?.toInt() ?? 6).clamp(4, 8).toInt(),
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      channels: (json['channels'] as List?)?.map((e) => '$e').toList() ??
          const <String>[],
      devCode: json['dev_code'] as String?,
    );
  }
}

class LoginResult {
  const LoginResult._({this.tokens, this.mfa});

  factory LoginResult.success(TokenPair tokens) =>
      LoginResult._(tokens: tokens);

  factory LoginResult.mfaRequired(MfaChallenge mfa) => LoginResult._(mfa: mfa);

  final TokenPair? tokens;
  final MfaChallenge? mfa;
}

/// Result of requesting an OTP code, including the delivery channels used,
/// how long the code stays valid, and (when developer preview is enabled) the
/// code itself.
class SendOtpResult {
  const SendOtpResult({
    required this.expiresIn,
    this.codeLength = 6,
    required this.channels,
    this.devCode,
  });

  final int expiresIn;
  final int codeLength;
  final List<String> channels;
  final String? devCode;

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 600,
      codeLength:
          ((json['code_length'] as num?)?.toInt() ?? 6).clamp(4, 8).toInt(),
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

  Future<LoginResult> signIn(String email, String password) async {
    final data = await api.post(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );
    if (data['mfa_required'] == true) {
      return LoginResult.mfaRequired(MfaChallenge.fromJson(data));
    }
    return LoginResult.success(TokenPair.fromJson(data));
  }

  Future<TokenPair> verifyMfa(
      {required String mfaToken, required String code}) async {
    final data = await api.post(
      '/api/v1/auth/mfa/verify',
      body: {'mfa_token': mfaToken, 'code': code},
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

  /// Creates a new onboarder account via the public registration endpoint.
  /// Registration does not issue tokens, so the account must sign in afterwards.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String role = 'onboarder',
  }) async {
    await api.post(
      '/api/v1/auth/register',
      body: <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );
  }

  /// Starts a password reset by delivering a one-time code to the account's
  /// email (falling back to WhatsApp or SMS when email is unavailable).
  Future<SendOtpResult> forgotPassword(String email) async {
    final data = await api.post(
      '/api/v1/auth/forgot-password',
      body: {'email': email},
    );
    return SendOtpResult.fromJson(data);
  }

  /// Completes a password reset with the code delivered by [forgotPassword].
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await api.post(
      '/api/v1/auth/reset-password',
      body: {'email': email, 'code': code, 'new_password': newPassword},
    );
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
  OnboarderSession({AuthService? service}) : service = service ?? AuthService();

  static final OnboarderSession instance = OnboarderSession();

  final AuthService service;
  ApiClient get api => service.api;
  AuthUser? _user;
  String? _accessToken;
  String? _refreshToken;
  MfaChallenge? _pendingMfa;

  AuthUser? get user => _user;
  Future<void> refreshProfile() async {
    final token = accessToken;
    if (token == null) return;
    final data = await api
        .get('/api/v1/auth/me', headers: {'Authorization': 'Bearer $token'});
    _user = AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    notifyListeners();
  }

  bool get isAuthenticated => _user != null;
  String? get accessToken => _accessToken;
  MfaChallenge? get pendingMfa => _pendingMfa;

  Future<void> _completeSession(TokenPair tokens) async {
    final user = await service.me(tokens.accessToken);
    if (user.role != 'onboarder' && user.role != 'vendor') {
      throw const ApiException(
          'Sign in with a vendor or field onboarder account.');
    }
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    _user = user;
    notifyListeners();
  }

  void cancelMfa() {
    _pendingMfa = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final result = await service.signIn(email.trim(), password);
      if (result.mfa != null) {
        _pendingMfa = result.mfa;
        notifyListeners();
        return false;
      }
      if (result.tokens != null) {
        await _completeSession(result.tokens!);
        _pendingMfa = null;
        return true;
      }
      return false;
    } on ApiException {
      rethrow;
    }
  }

  Future<bool> verifyMfaCode(String code) async {
    final mfa = _pendingMfa;
    if (mfa == null) return false;
    try {
      final tokens =
          await service.verifyMfa(mfaToken: mfa.mfaToken, code: code);
      await _completeSession(tokens);
      _pendingMfa = null;
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
      await _completeSession(tokens);
      return true;
    } on ApiException {
      return false;
    }
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
