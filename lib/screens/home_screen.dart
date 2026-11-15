import 'package:flutter/material.dart';

import '../widgets/onboarder_app_bar.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/onboard_service.dart';
import 'kyc_status_screen.dart';
import 'login_screen.dart';
import 'account_tab.dart';
import 'dashboard_tab.dart';
import 'earnings_tab.dart';
import 'movers_tab.dart';
import 'riders_tab.dart';
import 'vendors_tab.dart';

/// Root shell for the onboarding officer. Bottom navigation with six tabs:
/// Dashboard, Vendors, Riders, Movers, Earnings, Account.
class OnboarderHome extends StatefulWidget {
  const OnboarderHome({super.key, this.session, this.connect});

  final OnboarderSession? session;
  final Future<void> Function(String token)? connect;

  @override
  State<OnboarderHome> createState() => _OnboarderHomeState();
}

class _OnboarderHomeState extends State<OnboarderHome> {
  int _index = 0;
  bool _checking = true;
  bool _submitted = false;
  String? _error;
  OnboarderSession get _session => widget.session ?? OnboarderSession.instance;

  Future<void> _connect(String token) =>
      (widget.connect ?? OnboardService.instance.connect)(token);

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final token = _session.accessToken;
      if (token == null) throw const ApiException('Sign in to continue.');
      if (_session.user?.role == 'admin') {
        await _connect(token);
        if (mounted) setState(() => _submitted = true);
        return;
      }
      final data = await ApiClient().get('/api/v1/onboarder/profile',
          headers: {'Authorization': 'Bearer $token'});
      final verification = await ApiClient().get('/api/v1/verification/status',
          headers: {'Authorization': 'Bearer $token'});
      final checks = verification['checks'] as List;
      final submitted = data['profile']['kyc'] is Map &&
          checks
              .every((c) => c['required'] != true || c['status'] == 'verified');
      if (submitted) await _connect(token);
      if (mounted) setState(() => _submitted = submitted);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  static const _titles = [
    'Dashboard',
    'Vendors',
    'Riders',
    'Movers',
    'Earnings',
    'Account',
  ];

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
          body: SafeArea(
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!),
        TextButton(onPressed: _checkVerification, child: const Text('Retry')),
        TextButton(
            onPressed: () async {
              await _session.logOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (_) => false);
            },
            child: const Text('Sign out')),
      ]))));
    }
    if (!_submitted) return KYCStatusScreen(onSubmitted: _checkVerification);
    return Scaffold(
      appBar: OnboarderAppBar(
        automaticallyImplyLeading: false,
        title: _titles[_index],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardTab(),
          VendorsTab(),
          RidersTab(),
          MoversTab(),
          EarningsTab(),
          AccountTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Vendors',
          ),
          NavigationDestination(
            icon: Icon(Icons.two_wheeler_outlined),
            selectedIcon: Icon(Icons.two_wheeler_rounded),
            label: 'Riders',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping_rounded),
            label: 'Movers',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
