import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor/screens/bank_account_screen.dart';
import 'package:vendor/services/payment_service.dart';

class PayoutService extends PaymentService {
  final resolution = Completer<Map<String, String>?>();
  final saving = Completer<Map<String, dynamic>>();
  int saves = 0, removals = 0;
  bool failLoad = false;
  List<Map<String, dynamic>> wallets = [];
  @override
  Future<List<Map<String, dynamic>>> listWallets(String token) async {
    if (failLoad) throw Exception('offline');
    return wallets;
  }

  @override
  Future<List<Map<String, dynamic>>> listBanks() async => [
        {'name': 'Test Bank', 'code': '001'},
        {'name': 'Other Bank', 'code': '002'}
      ];
  @override
  Future<Map<String, String>?> resolveAccount(
          {required String bankCode, required String accountNumber}) =>
      resolution.future;
  @override
  Future<Map<String, dynamic>> addWallet(String token,
      {required String bankName,
      required String bankCode,
      required String accountNumber,
      required String accountName}) {
    saves++;
    return saving.future;
  }

  @override
  Future<void> deleteWallet(String token, int id) async {
    removals++;
  }
}

Future<void> open(WidgetTester tester, PayoutService service) async {
  await tester.pumpWidget(MaterialApp(
      home: BankAccountScreen(service: service, token: () => 'test-token')));
  await tester.pumpAndSettle();
}

Future<void> enterAccount(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Choose your bank'));
  await tester.tap(find.text('Choose your bank'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, 'Test');
  await tester.pump();
  expect(find.text('Other Bank'), findsNothing);
  await tester.tap(find.text('Test Bank'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(TextField));
  await tester.enterText(find.byType(TextField), '0123456789');
  await tester.pump();
  await tester.ensureVisible(find.text('Verify account name'));
  await tester.tap(find.text('Verify account name'));
  await tester.pump();
}

void main() {
  testWidgets('changing details invalidates an outstanding verification',
      (tester) async {
    final service = PayoutService();
    await open(tester, service);
    await enterAccount(tester);
    await tester.enterText(find.byType(TextField), '9876543210');
    service.resolution.complete({'account_name': 'Old Account'});
    await tester.pumpAndSettle();
    expect(find.text('Old Account'), findsNothing);
    expect(find.text('Save payout account'), findsNothing);
    expect(service.saves, 0);
  });

  testWidgets(
      'verified name is required and saving prevents duplicate requests',
      (tester) async {
    final service = PayoutService();
    await open(tester, service);
    expect(find.text('Save payout account'), findsNothing);
    await enterAccount(tester);
    service.resolution.complete({'account_name': 'Test Account'});
    await tester.pumpAndSettle();
    expect(find.text('Test Account'), findsOneWidget);
    await tester.ensureVisible(find.text('Save payout account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save payout account'));
    await tester.pump();
    expect(service.saves, 1);
    final saving = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Saving account…'));
    expect(saving.onPressed, isNull);
    service.saving.complete({});
    await tester.pumpAndSettle();
    expect(find.text('Save payout account'), findsNothing);
  });

  testWidgets('saved accounts are masked and removal needs confirmation',
      (tester) async {
    final service = PayoutService()
      ..wallets = [
        {
          'id': 1,
          'bank_name': 'Test Bank',
          'account_name': 'Test Account',
          'account_number': '0123456789'
        }
      ];
    await open(tester, service);
    expect(find.text('•••• 6789'), findsOneWidget);
    expect(find.text('0123456789'), findsNothing);
    await tester.tap(find.byTooltip('Remove Test Bank account'));
    await tester.pumpAndSettle();
    expect(service.removals, 0);
    await tester.tap(find.text('Keep account'));
    await tester.pumpAndSettle();
    expect(service.removals, 0);
  });

  testWidgets('loading failures show retry rather than an empty account list',
      (tester) async {
    final service = PayoutService()..failLoad = true;
    await open(tester, service);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('No payout account yet. Add your first account below.'),
        findsNothing);
    service.failLoad = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No payout account yet. Add your first account below.'),
        findsOneWidget);
  });
}
