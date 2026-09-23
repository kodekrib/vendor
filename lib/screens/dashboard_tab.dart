import 'package:flutter/material.dart';

import '../app.dart';
import '../models/onboarding.dart';
import '../services/onboard_service.dart';
import '../widgets/common.dart';
import 'onboard_rider_screen.dart';
import 'onboard_vendor_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = OnboardService.instance;
    final name = repo.profile?.firstName ?? 'Onboarder';

    return AnimatedBuilder(
      animation: repo,
      builder: (context, child) {
        return AppScrollTab(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${repo.activeVendors} active vendors · ${repo.activeRiders} active riders',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.storefront_rounded,
                        iconColor: OnboarderApp.brandTeal,
                        label: 'Vendors',
                        value: '${repo.vendors.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.two_wheeler_rounded,
                        iconColor: const Color(0xFF2563EB),
                        label: 'Riders',
                        value: '${repo.riders.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.pending_actions_rounded,
                        iconColor: const Color(0xFFD97706),
                        label: 'Pending',
                        value: '${repo.pendingCount}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F3D3A), Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earned this period',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      DefaultTextStyle(
                        style: const TextStyle(color: Colors.white),
                        child: PriceText(
                          repo.totalEarned,
                          size: 30,
                          weight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your cut of the commissions from vendors, riders and '
                        'movers you\u2019ve onboarded.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: _QuickActions()),
            SliverToBoxAdapter(
              child: SectionHeader('Recent activity', action: 'Earnings',
                  onAction: () {}),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final t = repo.txns[i];
                  return _TxnTile(txn: t, last: i == repo.txns.length - 1);
                },
                childCount: repo.txns.take(4).toList().length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.add_business_rounded,
                  color: OnboarderApp.brandTeal,
                  label: 'Onboard vendor',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const OnboardVendorScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFF2563EB),
                  label: 'Onboard rider',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const OnboardRiderScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OnboarderApp.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAF0EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn, required this.last});

  final CommissionTxn txn;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (txn.kind) {
      CommissionKind.vendor => (OnboarderApp.brandTeal, Icons.storefront_rounded),
      CommissionKind.rider => (const Color(0xFF2563EB), Icons.two_wheeler_rounded),
      CommissionKind.mover => (const Color(0xFFEA580C), Icons.local_shipping_rounded),
      CommissionKind.fee => (const Color(0xFFD97706), Icons.savings_rounded),
    };
    return Container(
      margin: EdgeInsets.fromLTRB(20, last ? 4 : 4, 20, last ? 12 : 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OnboarderApp.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0EE)),
      ),
      child: Row(
        children: [
          AccountAvatar(icon: icon, color: color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(txn.date,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          PriceText(txn.amount, size: 14, weight: FontWeight.w800),
        ],
      ),
    );
  }
}