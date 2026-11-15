import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vendor/app.dart';
import 'package:vendor/screens/dashboard_tab.dart';
import 'package:vendor/screens/home_screen.dart';
import 'package:vendor/screens/onboard_mover_screen.dart';
import 'package:vendor/screens/kyc_status_screen.dart';
import 'package:vendor/services/auth_service.dart';
import 'package:vendor/widgets/animated_3d.dart';
import 'package:vendor/widgets/route_animation.dart';
import 'package:vendor/widgets/skeuo.dart';

class AdminSession extends OnboarderSession {
  @override
  String? get accessToken => 'admin-token';
  @override
  AuthUser? get user => const AuthUser(
      id: '7', email: 'admin@example.test', name: 'Admin', role: 'admin');
}

void main() {
  setUpAll(() {
    kRouteAnimationEnabled = false;
    kHeroAnimationsEnabled = false;
  });

  testWidgets('login screen renders with moving bike', (tester) async {
    await tester.pumpWidget(const OnboarderApp());
    expect(find.text('Create account'), findsOneWidget);
    expect(find.widgetWithText(SkeuoButton, 'Sign in'), findsOneWidget);
    final backdrop = tester
        .widget<AnimatedRouteBackdrop>(find.byType(AnimatedRouteBackdrop));
    expect(backdrop.showMarker, isTrue);
    expect(backdrop.markIcon, Icons.moped_rounded);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('home blocks dashboard access without a session', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboarderHome()));
    await tester.pump();
    expect(find.text('Sign in to continue.'), findsOneWidget);
    expect(find.text('Quick actions'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('admin opens dashboard without KYC or provider checks',
      (tester) async {
    final session = AdminSession();
    String? connectedToken;
    await tester.pumpWidget(MaterialApp(
        home: OnboarderHome(
      session: session,
      connect: (token) async {
        connectedToken = token;
      },
    )));
    await tester.pump();
    expect(connectedToken, 'admin-token');
    expect(find.byType(KYCStatusScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  testWidgets('dashboard mover CTA opens mover onboarding', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: DashboardTab())));
    await tester.scrollUntilVisible(find.text('Onboard mover'), 180);
    await tester.ensureVisible(find.text('Onboard mover'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onboard mover'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(OnboardMoverScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
