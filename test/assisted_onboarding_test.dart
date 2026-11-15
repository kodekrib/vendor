import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendor/screens/onboard_vendor_screen.dart';
import 'package:vendor/screens/onboard_mover_screen.dart';
import 'package:vendor/screens/onboard_rider_screen.dart';
import 'package:vendor/services/api_client.dart';
import 'package:vendor/widgets/assisted_driver_documents.dart';

void main() {
  test('Driver document uploads do not change the onboarder avatar', () async {
    final calls = <String>[];
    final api = ApiClient(
        baseUrl: 'http://localhost',
        httpClient: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          expect(request.headers['Authorization'], 'Bearer agent-token');
          return http.Response(
              jsonEncode({'url': 'https://example.test/license.png'}), 200);
        }));
    expect(
        await api.uploadDocumentBytes([1, 2, 3], 'license.png', 'agent-token'),
        'https://example.test/license.png');
    expect(calls, ['POST /api/v1/uploads']);
  });

  testWidgets('Merchant onboarding excludes private identity inputs',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardVendorScreen()));
    final labels = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.decoration?.labelText ?? '')
        .join(' ');
    expect(labels, isNot(contains('NIN')));
    expect(labels, isNot(contains('Identity Card')));
    expect(labels, isNot(contains('CAC')));
    expect(labels, contains('Store name'));
    expect(find.textContaining('Delivery fee'), findsNothing);
    expect(find.text('Retry merchant groups'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Mover onboarding does not collect commission', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardMoverScreen()));
    final labels = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.decoration?.labelText ?? '')
        .join(' ');
    expect(labels.toLowerCase(), isNot(contains('commission')));
    expect(
        find.text('Your onboarding commission is determined by the admin.',
            skipOffstage: false),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Rider onboarding offers assisted uploads without NIN',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardRiderScreen()));
    final labels = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.decoration?.labelText ?? '')
        .join(' ');
    expect(labels, isNot(contains('NIN')));
    expect(find.byType(AssistedDriverDocuments, skipOffstage: false),
        findsOneWidget);
    expect(
        find.text('Vehicle registration', skipOffstage: false), findsOneWidget);
    expect(find.text('Read & acknowledge NDPR notice', skipOffstage: false),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
