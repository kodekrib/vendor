import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../widgets/onboarder_app_bar.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key, this.service, this.token});
  final PaymentService? service;
  final String? Function()? token;

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  late final _service = widget.service ?? PaymentService();
  final _account = TextEditingController();
  List<Map<String, dynamic>> _wallets = [], _banks = [];
  Map<String, dynamic>? _bank;
  String? _name, _error, _loadError;
  bool _loading = true, _resolving = false, _saving = false;
  int _revision = 0;
  int? _deleting;
  bool get _valid =>
      _bank != null && RegExp(r'^\d{10}$').hasMatch(_account.text);
  String get _token {
    final token = widget.token?.call() ?? OnboarderSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('Sign in to manage payout accounts.');
    }
    return token;
  }

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
    try {
      final results = await Future.wait(
          [_service.listWallets(_token), _service.listBanks()]);
      if (!mounted) return;
      setState(() {
        _wallets = results[0];
        _banks = results[1];
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadError =
            'Could not load payout accounts. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _invalidate() {
    _revision++;
    _name = null;
    _error = null;
    _resolving = false;
  }

  Future<void> _chooseBank() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _BankPicker(banks: _banks, selectedCode: _bank?['code']?.toString()),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _bank = selected;
      _invalidate();
    });
  }

  Future<void> _verify() async {
    if (!_valid || _resolving || _saving) return;
    final revision = ++_revision;
    final number = _account.text, code = '${_bank!['code']}';
    setState(() {
      _resolving = true;
      _name = null;
      _error = null;
    });
    try {
      final result =
          await _service.resolveAccount(bankCode: code, accountNumber: number);
      if (!mounted || revision != _revision) return;
      final name = result?['account_name']?.trim();
      setState(() {
        if (name == null || name.isEmpty) {
          _error = 'Account not found. Check your bank and account number.';
        } else {
          _name = name;
        }
      });
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() => _error =
            'We could not verify this account. Check the details and try again.');
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _resolving = false);
    }
  }

  Future<void> _save() async {
    if (!_valid || _name == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.addWallet(_token,
          bankName: '${_bank!['name']}',
          bankCode: '${_bank!['code']}',
          accountNumber: _account.text,
          accountName: _name!);
      if (!mounted) return;
      setState(() {
        _account.clear();
        _bank = null;
        _invalidate();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Payout account saved. You can select it when withdrawing.')));
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not save your payout account. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> wallet) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Remove payout account?'),
              content: Text(
                  'Remove ${wallet['bank_name']} ending in ${_lastFour(wallet['account_number'])}? You can add it again later.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep account')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove account'))
              ],
            ));
    if (!mounted || confirmed != true) return;
    final id = (wallet['id'] as num).toInt();
    setState(() => _deleting = id);
    try {
      await _service.deleteWallet(_token, id);
      if (mounted) setState(() => _wallets.removeWhere((w) => w['id'] == id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not remove this account. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  String _lastFour(dynamic value) {
    final number = '$value';
    return number.length > 4 ? number.substring(number.length - 4) : number;
  }

  Widget _card({required Widget child}) => Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(20), child: child));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const OnboarderAppBar(title: 'Payout account'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.cloud_off_outlined, size: 40),
                          const SizedBox(height: 12),
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _load, child: const Text('Try again'))
                        ])))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        Text('Where should we send your earnings?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            'Add a Nigerian bank account, then choose it when you withdraw your commission.'),
                        const SizedBox(height: 24),
                        Text('Saved payout accounts',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        if (_wallets.isEmpty)
                          _card(
                              child: const Row(children: [
                            Icon(Icons.account_balance_outlined, size: 32),
                            SizedBox(width: 16),
                            Expanded(
                                child: Text(
                                    'No payout account yet. Add your first account below.'))
                          ])),
                        for (final wallet in _wallets)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _card(
                                  child: Row(children: [
                                CircleAvatar(
                                    backgroundColor:
                                        OnboarderApp.brandTealLight,
                                    child: Icon(Icons.account_balance_outlined,
                                        color: OnboarderApp.brandTealDark)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text('${wallet['bank_name']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('${wallet['account_name']}'),
                                      Text(
                                          '•••• ${_lastFour(wallet['account_number'])}'),
                                    ])),
                                IconButton(
                                    tooltip:
                                        'Remove ${wallet['bank_name']} account',
                                    onPressed: _deleting != null || _saving
                                        ? null
                                        : () => _remove(wallet),
                                    icon: _deleting == wallet['id']
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.delete_outline)),
                              ]))),
                        const SizedBox(height: 24),
                        _card(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              Text('Add payout account',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              const Text(
                                  '1. Enter details   →   2. Verify name   →   3. Save'),
                              const SizedBox(height: 20),
                              OutlinedButton(
                                  onPressed: _saving || _banks.isEmpty
                                      ? null
                                      : _chooseBank,
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.all(16)),
                                  child: Row(children: [
                                    const Icon(Icons.account_balance_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(
                                            _bank?['name']?.toString() ??
                                                'Choose your bank')),
                                    const Icon(Icons.keyboard_arrow_down)
                                  ])),
                              if (_banks.isEmpty)
                                const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                        'No banks available. Pull down to refresh.')),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: _account,
                                  enabled: !_saving,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10)
                                  ],
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                      labelText: 'Account number',
                                      hintText: '10-digit account number',
                                      helperText:
                                          'Enter the account number, not your card number.',
                                      border: OutlineInputBorder()),
                                  onChanged: (_) => setState(_invalidate),
                                  onSubmitted: (_) => _verify()),
                              const SizedBox(height: 16),
                              if (_name == null)
                                FilledButton.icon(
                                    onPressed: _valid && !_resolving && !_saving
                                        ? _verify
                                        : null,
                                    icon: _resolving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(
                                            Icons.person_search_outlined),
                                    label: Text(_resolving
                                        ? 'Verifying account…'
                                        : 'Verify account name')),
                              if (_name != null) ...[
                                Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: OnboarderApp.brandTealLight,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Row(children: [
                                      Icon(Icons.check_circle_outline,
                                          color: OnboarderApp.brandTealDark),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            const Text(
                                                'Account name confirmed'),
                                            Text(_name!,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ]))
                                    ])),
                                const SizedBox(height: 12),
                                const Text(
                                    'Check that this is the person or business you want to receive your payouts.'),
                                const SizedBox(height: 16),
                                FilledButton(
                                    onPressed: _saving ? null : _save,
                                    child: Text(_saving
                                        ? 'Saving account…'
                                        : 'Save payout account')),
                              ],
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Semantics(
                                        liveRegion: true,
                                        child: Text(_error!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error)))),
                            ])),
                      ],
                    )),
      );

  @override
  void dispose() {
    _revision++;
    _account.dispose();
    super.dispose();
  }
}

class _BankPicker extends StatefulWidget {
  const _BankPicker({required this.banks, this.selectedCode});
  final List<Map<String, dynamic>> banks;
  final String? selectedCode;
  @override
  State<_BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends State<_BankPicker> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final banks = widget.banks
        .where((b) =>
            '${b['name']}'.toLowerCase().contains(_search.toLowerCase().trim()))
        .toList();
    return SafeArea(
        child: SizedBox(
      height: MediaQuery.of(context).size.height * .85,
      child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Choose your bank',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Search banks',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _search = v)),
            const SizedBox(height: 8),
            Expanded(
                child: banks.isEmpty
                    ? const Center(
                        child: Text('No banks found. Try another name.'))
                    : ListView.builder(
                        itemCount: banks.length,
                        itemBuilder: (context, i) => ListTile(
                            title: Text('${banks[i]['name']}'),
                            trailing:
                                '${banks[i]['code']}' == widget.selectedCode
                                    ? const Icon(Icons.check)
                                    : null,
                            onTap: () => Navigator.pop(context, banks[i])))),
          ])),
    ));
  }
}
