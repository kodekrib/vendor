import 'package:flutter/material.dart';
import '../app.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'bank_account_screen.dart';
import '../services/payment_service.dart';
import '../widgets/onboarder_app_bar.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _paymentService = PaymentService();
  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _withdrawals = [];
  bool _loading = true;
  double? _available;
  String? _loadError;
  bool _submitting = false;

  final _amountController = TextEditingController();
  Map<String, dynamic>? _selectedWallet;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final token = OnboarderSession.instance.accessToken ?? '';
    try {
      final balance = await _paymentService.balance(token);
      final results = await Future.wait([
        _paymentService.listWallets(token),
        _paymentService.listWithdrawals(token),
      ]);
      if (mounted) {
        setState(() {
          _available = (balance['available_minor'] as num).toDouble() / 100;
          _loadError = null;
          _wallets = results[0];
          _selectedWallet = null;
          _withdrawals = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _available = null;
          _loadError = e is ApiException
              ? e.message
              : 'Could not load withdrawal details. Please try again.';
        });
      }
    }
  }

  Future<void> _submitWithdrawal() async {
    if (_submitting) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (!amount.isFinite ||
        amount < 100 ||
        (amount * 100 - (amount * 100).round()).abs() > 0.000001 ||
        _selectedWallet == null ||
        _available == null ||
        amount > _available!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Choose a bank account and an amount between ${OnboarderApp.currencySymbol}100 and your available balance')),
      );
      return;
    }
    setState(() => _submitting = true);
    final token = OnboarderSession.instance.accessToken ?? '';
    try {
      await _paymentService.withdraw(
        token,
        amount: amount,
        walletId: int.parse('${_selectedWallet!['id']}'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal request submitted')),
        );
        _amountController.clear();
        setState(() => _selectedWallet = null);
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OnboarderAppBar(title: 'Withdraw Earnings'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_available != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                            'Available: ${OnboarderApp.currencySymbol}${_available!.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold))),
                  if (_loadError != null)
                    Column(children: [
                      Text(_loadError!),
                      TextButton(onPressed: _load, child: const Text('Retry'))
                    ]),
                  _buildWithdrawForm(),
                  if (_withdrawals.any((w) =>
                      w['status'] == 'pending' || w['status'] == 'processing'))
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                          'Your previous withdrawal is still being processed. You can request another once it is resolved.'),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Withdrawal History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_withdrawals.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('No withdrawals yet.',
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                    )
                  else
                    ..._withdrawals.map((w) {
                      final status = w['status'] ?? 'pending';
                      final color = switch (status) {
                        'completed' => Colors.green,
                        'processing' => Colors.orange,
                        'failed' => Colors.red,
                        _ => Colors.grey,
                      };
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                              '${OnboarderApp.currencySymbol}${(num.tryParse('${w['amount']}') ?? 0).toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${w['bank_name']} • ${w['account_number']}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(status.toUpperCase(),
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildWithdrawForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_wallets.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'Add a bank account first in Account > Bank Accounts.')),
                    ],
                  ),
                  TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const BankAccountScreen()));
                        if (mounted) await _load();
                      },
                      child: const Text('Add bank account'))
                ]),
              )
            else ...[
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedWallet,
                decoration: const InputDecoration(
                    labelText: 'Withdraw to', border: OutlineInputBorder()),
                items: _wallets
                    .map((w) => DropdownMenuItem(
                        value: w,
                        child:
                            Text('${w['bank_name']} - ${w['account_number']}')))
                    .toList(),
                onChanged: (w) => setState(() => _selectedWallet = w),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Amount (${OnboarderApp.currencySymbol})',
                    border: const OutlineInputBorder(),
                    prefixText: '${OnboarderApp.currencySymbol} '),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ||
                          _available == null ||
                          _available! < 100 ||
                          _withdrawals.any((w) =>
                              w['status'] == 'pending' ||
                              w['status'] == 'processing')
                      ? null
                      : _submitWithdrawal,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Request Withdrawal'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
