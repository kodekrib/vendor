import 'package:flutter_test/flutter_test.dart';
import 'package:vendor/services/api_client.dart';
import 'package:vendor/services/auth_service.dart';

class LoginService extends AuthService {
  LoginService({this.failure, this.role = 'onboarder'});
  final ApiException? failure;
  final String role;

  @override
  Future<LoginResult> signIn(String email, String password) async {
    if (failure != null) throw failure!;
    return LoginResult.success(
        const TokenPair(accessToken: 'access', refreshToken: 'refresh'));
  }

  @override
  Future<AuthUser> me(String token) async =>
      AuthUser(id: '7', email: 'agent@example.test', name: 'Agent', role: role);
}

void main() {
  test('password login preserves the API error for the login screen', () async {
    const failure = ApiException('Your account is disabled.', statusCode: 403);
    final session = OnboarderSession(service: LoginService(failure: failure));
    await expectLater(session.signIn('agent@example.test', 'password'),
        throwsA(same(failure)));
    expect(session.isAuthenticated, isFalse);
    session.dispose();
  });

  test('existing vendor account can sign in', () async {
    final session = OnboarderSession(service: LoginService(role: 'vendor'));
    expect(await session.signIn('merchant@example.test', 'password'), isTrue);
    expect(session.isAuthenticated, isTrue);
    expect(session.user?.role, 'vendor');
    expect(session.accessToken, 'access');
    session.dispose();
  });

  test('unrelated account roles remain blocked', () async {
    final session = OnboarderSession(service: LoginService(role: 'customer'));
    await expectLater(
        session.signIn('customer@example.test', 'password'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message',
            contains('vendor, field onboarder or admin'))));
    expect(session.isAuthenticated, isFalse);
    expect(session.accessToken, isNull);
    session.dispose();
  });

  test('admin can sign in without changing their role', () async {
    final session = OnboarderSession(service: LoginService(role: 'admin'));
    expect(await session.signIn('admin@example.test', 'password'), isTrue);
    expect(session.user?.role, 'admin');
    expect(session.accessToken, 'access');
    session.dispose();
  });

  test('valid field onboarder signs in', () async {
    final session = OnboarderSession(service: LoginService());
    expect(await session.signIn('agent@example.test', 'password'), isTrue);
    expect(session.isAuthenticated, isTrue);
    session.dispose();
  });
}
