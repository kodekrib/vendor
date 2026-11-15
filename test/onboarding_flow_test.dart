import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendor/app.dart';
import 'package:vendor/screens/onboard_vendor_screen.dart';
import 'package:vendor/services/api_client.dart';
import 'package:vendor/services/merchant_group_service.dart';
import 'package:vendor/widgets/onboard_driver_form.dart';
import 'package:vendor/widgets/onboarding_form.dart';

final _captureKey = GlobalKey();
Widget shell(Widget child) => RepaintBoundary(
    key: _captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          fontFamily: const bool.fromEnvironment('ONBOARDING_PREVIEWS')
              ? 'PreviewSans'
              : null,
          colorScheme: ColorScheme.fromSeed(seedColor: OnboarderApp.brandTeal)),
      home: child,
    ));
Future<void> snapshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('ONBOARDING_PREVIEWS')) return;
  await tester.pumpAndSettle();
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('/tmp/onboarding_$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Finder input(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);
Future<void> fill(WidgetTester tester, String label, String value) async {
  final finder = input(label);
  await tester.ensureVisible(finder);
  // Setting the controller also avoids starting live address searches in a UI test.
  tester.widget<TextField>(finder).controller!.text = value;
  await tester.pump();
}

ApiClient catalogApi() => ApiClient(
    baseUrl: 'https://example.test',
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/merchant-groups')) {
        return http.Response(
            jsonEncode({
              'groups': [
                {'slug': 'shops', 'name': 'Shops', 'service_only': false},
                {
                  'slug': 'restaurants',
                  'name': 'Restaurants',
                  'service_only': false
                },
              ]
            }),
            200);
      }
      return http.Response(
          jsonEncode({
            'vehicle_types': [
              {'id': 3, 'name': 'van', 'label': 'Van', 'is_active': true},
            ]
          }),
          200);
    }));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('ONBOARDING_PREVIEWS')) return;
    final fontFile = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (await fontFile.exists()) {
      final loader = FontLoader('PreviewSans')
        ..addFont(fontFile
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets(
      'Steps validate, retain entries, and recheck before final submission',
      (tester) async {
    final key = GlobalKey<OnboardingFlowState>();
    final name = TextEditingController();
    var submitted = 0;
    await tester.pumpWidget(shell(OnboardingFlow(
        key: key,
        title: 'Onboard vendor',
        icon: Icons.storefront,
        submitLabel: 'Onboard vendor',
        onSubmit: () => submitted++,
        steps: [
          OnboardingStep(
              label: 'Account',
              title: 'Owner account',
              description: 'Enter owner details.',
              builder: (_) =>
                  OnboardingField(controller: name, label: 'Owner name')),
          OnboardingStep(
              label: 'Review',
              title: 'Review',
              description: 'Check before submitting.',
              builder: (_) => Text(name.text)),
        ])));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter owner name.'), findsOneWidget);
    await fill(tester, 'Owner name *', 'Amina Bello');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Amina Bello'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input('Owner name *')).controller!.text,
        'Amina Bello');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    name.clear();
    await tester.tap(find.ancestor(
        of: find.text('Onboard vendor'),
        matching:
            find.byWidgetPredicate((widget) => widget is ElevatedButton)));
    await tester.pumpAndSettle();
    expect(submitted, 0);
    expect(find.text('Enter owner name.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    name.dispose();
  });

  testWidgets('Merchant flow reviews details without exposing the password',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(shell(OnboardVendorScreen(
        groupService: MerchantGroupService(api: catalogApi()),
        tokenProvider: () => 'test')));
    await tester.pumpAndSettle();
    await snapshot(tester, 'vendor_business');
    await fill(tester, 'Store name *', 'FreshCart');
    await fill(tester, 'Store address *', 'Ikeja, Lagos');
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shops').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await fill(tester, 'Owner name *', 'Amina Bello');
    await fill(tester, 'Business email *', 'amina@example.test');
    await fill(tester, 'Phone number *', '0803 123 4567');
    await fill(tester, 'Password *', 'secret123');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(
        tester
            .getBottomRight(find.ancestor(
                of: find.text('Continue'),
                matching: find
                    .byWidgetPredicate((widget) => widget is ElevatedButton)))
            .dy,
        lessThanOrEqualTo(564));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Operating hours'), findsOneWidget);
    expect(find.textContaining('image URL'), findsNothing);
    await snapshot(tester, 'vendor_storefront');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Ready to welcome this vendor?'), findsOneWidget);
    expect(find.text('FreshCart'), findsOneWidget);
    expect(find.text('secret123'), findsNothing);
    await snapshot(tester, 'vendor_review');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final mover in [false, true]) {
    testWidgets(
        '${mover ? 'Mover' : 'Rider'} flow fits a narrow screen and retains vehicle details',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(shell(OnboardDriverForm(
          mover: mover, api: catalogApi(), tokenProvider: () => 'test')));
      await tester.pumpAndSettle();
      await snapshot(tester, mover ? 'mover_account' : 'rider_account');
      await fill(
          tester, mover ? 'Mover name *' : 'Rider name *', 'Tunde Adebayo');
      await fill(tester, 'Email address *', 'tunde@example.test');
      await fill(tester, 'Phone number *', '0803 123 4567');
      await fill(tester, 'Password *', 'secret123');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Van').last);
      await tester.pumpAndSettle();
      await fill(tester, 'Vehicle brand *', 'Toyota');
      await fill(tester, 'Registration number *', 'LAG-560-JKK');
      await snapshot(tester, mover ? 'mover_vehicle' : 'rider_vehicle');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Help them get verified'), findsOneWidget);
      await snapshot(tester, mover ? 'mover_documents' : 'rider_documents');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Help them get verified'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(
          tester.widget<TextField>(input('Vehicle brand *')).controller!.text,
          'Toyota');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
