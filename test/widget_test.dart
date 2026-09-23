import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vendor/app.dart';
import 'package:vendor/screens/home_screen.dart';
import 'package:vendor/services/auth_service.dart';
import 'package:vendor/widgets/route_animation.dart';

void main() {
  setUpAll(() {
    kRouteAnimationEnabled = false;
  });

  testWidgets('login screen renders with test-mode entry', (tester) async {
    await tester.pumpWidget(const OnboarderApp());

    expect(find.text('Test mode'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Sign in'),
      findsOneWidget,
    );

    await tester.tap(find.text('Test mode'));
    await tester.pumpAndSettle();

    expect(OnboarderSession.instance.isAuthenticated, isTrue);
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('can navigate to onboarding screens from tabs', (tester) async {
    OnboarderSession.instance.enterDemo();
    await tester.pumpWidget(const MaterialApp(home: OnboarderHome()));

    expect(find.text('Quick actions'), findsOneWidget);

    Finder navTab(String label) => find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        );

    await tester.tap(navTab('Vendors'));
    await tester.pumpAndSettle();
    expect(find.text('Onboard'), findsOneWidget);

    await tester.tap(find.text('Onboard'));
    await tester.pumpAndSettle();
    expect(find.text('Store name'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Onboard vendor'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(navTab('Riders'));
    await tester.pumpAndSettle();
    expect(find.text('Adewale Johnson'), findsOneWidget);

    await tester.tap(navTab('Earnings'));
    await tester.pumpAndSettle();
    expect(find.text('Request payout'), findsOneWidget);
  });
}