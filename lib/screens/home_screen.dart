import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../services/auth_service.dart';
import 'account_tab.dart';
import 'dashboard_tab.dart';
import 'earnings_tab.dart';
import 'movers_tab.dart';
import 'notifications_screen.dart';
import 'riders_tab.dart';
import 'vendors_tab.dart';

/// Root shell for the onboarding officer. Bottom navigation with six tabs:
/// Dashboard, Vendors, Riders, Movers, Earnings, Account.
class OnboarderHome extends StatefulWidget {
  const OnboarderHome({super.key});

  @override
  State<OnboarderHome> createState() => _OnboarderHomeState();
}

class _OnboarderHomeState extends State<OnboarderHome> {
  int _index = 0;

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
    final user = OnboarderSession.instance.user;
    final isDemo =
        user == null || (user.email.startsWith('demo') && user.email.contains('test'));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(_titles[_index]),
            if (isDemo)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: OnboarderApp.brandTealLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'TEST',
                  style: TextStyle(
                    color: OnboarderApp.brandTealDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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