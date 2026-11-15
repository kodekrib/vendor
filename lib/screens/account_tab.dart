import '../widgets/profile_photo.dart';
import 'app_info_screen.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../services/onboard_service.dart';
import '../widgets/common.dart';
import 'bank_account_screen.dart';
import 'info_screen.dart';
import 'kyc_status_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'withdrawal_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = OnboardService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([repo, OnboarderSession.instance]),
      builder: (context, child) {
        final profile = repo.profile;
        return AppScrollTab(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text('Your onboarding profile and tools.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: OnboarderApp.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFEAF0EE)),
                  ),
                  child: Row(
                    children: [
                      ProfilePhoto(
                          api: OnboarderSession.instance.api,
                          tokenProvider: () =>
                              OnboarderSession.instance.accessToken,
                          avatarUrl:
                              OnboarderSession.instance.user?.avatarUrl ?? '',
                          name:
                              OnboarderSession.instance.user?.name ?? 'Account',
                          onUpdated: OnboarderSession.instance.refreshProfile,
                          radius: 34),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                OnboarderSession.instance.user?.name ??
                                    profile?.name ??
                                    '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 17)),
                            const SizedBox(height: 2),
                            Text(
                                OnboarderSession.instance.user?.email ??
                                    profile?.email ??
                                    '',
                                style: const TextStyle(
                                    fontSize: 12.5, color: Color(0xFF6B7280))),
                            const SizedBox(height: 2),
                            Material(
                              color: OnboarderApp.brandTealLight,
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                child: Text(
                                  'Field Onboarder',
                                  style: TextStyle(
                                    color: OnboarderApp.brandTealDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatsTile(
                        icon: Icons.storefront_rounded,
                        color: OnboarderApp.brandTeal,
                        value: '${repo.vendors.length}',
                        label: 'You onboarded',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatsTile(
                        icon: Icons.two_wheeler_rounded,
                        color: const Color(0xFF2563EB),
                        value: '${repo.riders.length}',
                        label: 'Riders recruited',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatsTile(
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFFEA580C),
                        value: '${repo.movers.length}',
                        label: 'Movers recruited',
                      ),
                    ),
                    Expanded(
                      child: _StatsTile(
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFFD97706),
                        value: formatPrice(repo.totalEarned),
                        label: 'Total earned',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _MenuCard(
                  entries: [
                    _MenuEntry(Icons.person_outline_rounded, 'Profile',
                        'Manage your personal details and social profiles.',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const ProfileScreen()))),
                    _MenuEntry(Icons.info_outline_rounded, 'App Info',
                        'App identity and release details.',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const AppInfoScreen()))),
                    _MenuEntry(
                      Icons.document_scanner_outlined,
                      'KYC verification',
                      'Verify your documents once to unlock payouts.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const KYCStatusScreen(),
                        ),
                      ),
                    ),
                    _MenuEntry(
                      Icons.payments_outlined,
                      'Payout account',
                      'Bank account your commission is paid into.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InfoScreen(
                            title: 'Payout account',
                            icon: Icons.payments_outlined,
                            description:
                                'Where your commission lands each cycle.',
                            bullets: [
                              'A Nigerian naira account is required.',
                              'Payouts run every Friday.',
                              'Minimum payout: ${OnboarderApp.currencySymbol}2,000.',
                            ],
                          ),
                        ),
                      ),
                    ),
                    _MenuEntry(
                      Icons.account_balance_rounded,
                      'Bank Accounts',
                      'Manage your bank details for withdrawals',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BankAccountScreen(),
                        ),
                      ),
                    ),
                    _MenuEntry(
                      Icons.payments_rounded,
                      'Withdraw Earnings',
                      'Request a payout to your bank account',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WithdrawalScreen(),
                        ),
                      ),
                    ),
                    _MenuEntry(
                      Icons.help_outline,
                      'Help & support',
                      'Reach the field team any time.',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const InfoScreen(
                            title: 'Help & support',
                            icon: Icons.help_outline,
                            description: 'Support is available day and night.',
                            bullets: [
                              'Live chat with the operations desk.',
                              'Email field@marketgo.com.',
                              'Average response time under 5 minutes.',
                            ],
                          ),
                        ),
                      ),
                    ),
                    _MenuEntry(
                      Icons.logout,
                      'Sign out',
                      'End this session.',
                      onTap: () => _confirmLogout(context),
                      danger: true,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  OnboarderApp.appName,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF9AA1AA)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E5EA),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.logout_rounded,
                size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 14),
            Text('Sign out of ${OnboarderApp.appName}?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'You will need to sign in again to keep onboarding.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444)),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  OnboarderSession.instance.logOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Sign out'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OnboarderApp.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.entries});

  final List<_MenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OnboarderApp.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAF0EE)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            InkWell(
              onTap: entries[i].onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : const Border(
                          top: BorderSide(color: Color(0xFFEAF0EE)),
                        ),
                ),
                child: Row(
                  children: [
                    Icon(entries[i].icon,
                        color: entries[i].danger
                            ? const Color(0xFFEF4444)
                            : OnboarderApp.brandTealDark),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entries[i].title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: entries[i].danger
                                    ? const Color(0xFFEF4444)
                                    : OnboarderApp.ink,
                              )),
                          const SizedBox(height: 2),
                          Text(entries[i].subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: Color(0xFF9AA1AA)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuEntry {
  const _MenuEntry(this.icon, this.title, this.subtitle,
      {this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;
}
