import 'package:flutter/material.dart';

import '../app.dart';
import '../models/onboarding.dart';
import '../services/onboard_service.dart';
import '../widgets/common.dart';
import 'withdrawal_screen.dart';

class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = OnboardService.instance;

    return AnimatedBuilder(
      animation: repo,
      builder: (context, child) {
        return AppScrollTab(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Earnings',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Commission computed from vendor & rider activity.',
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                  decoration: BoxDecoration(
                    color: OnboarderApp.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFEAF0EE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available balance',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  )),
                      const SizedBox(height: 4),
                      PriceText(repo.totalEarned, size: 32),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceFact(
                              label: 'Vendors',
                              value: repo.totalVendorCommission,
                              color: OnboarderApp.brandTeal,
                            ),
                          ),
                          Expanded(
                            child: _BalanceFact(
                              label: 'Riders',
                              value: repo.totalRiderCommission,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          Expanded(
                            child: _BalanceFact(
                              label: 'Movers',
                              value: repo.totalMoverCommission,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const WithdrawalScreen(),
                            ),
                          ),
                          child: const Text('Request payout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _HowItWorks()),
            const SliverToBoxAdapter(
                child: SectionHeader('Recent transactions')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final t = repo.txns[i];
                  return _TxnRow(
                    txn: t,
                    first: i == 0,
                    last: i == repo.txns.length - 1,
                  );
                },
                childCount: repo.txns.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BalanceFact extends StatelessWidget {
  const _BalanceFact({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final num value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(height: 6),
        PriceText(value, size: 14),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OnboarderApp.brandTealLight.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How you earn',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          SizedBox(height: 10),
          _HowRow(
            icon: Icons.storefront_rounded,
            text: 'A % of every commission the app earns from the vendors '
                'you onboarded.',
          ),
          _HowRow(
            icon: Icons.two_wheeler_rounded,
            text: 'A share of the delivery commissions driven by riders you '
                'recruited.',
          ),
          _HowRow(
            icon: Icons.local_shipping_rounded,
            text: 'A share of moving-job commissions driven by the movers '
                'you recruited.',
          ),
        ],
      ),
    );
  }
}

class _HowRow extends StatelessWidget {
  const _HowRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: OnboarderApp.brandTealDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.45, color: Color(0xFF1F3A37))),
          ),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn, required this.first, required this.last});

  final CommissionTxn txn;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (txn.kind) {
      CommissionKind.vendor => (
          OnboarderApp.brandTeal,
          Icons.storefront_rounded
        ),
      CommissionKind.rider => (
          const Color(0xFF2563EB),
          Icons.two_wheeler_rounded
        ),
      CommissionKind.mover => (
          const Color(0xFFEA580C),
          Icons.local_shipping_rounded
        ),
      CommissionKind.fee => (const Color(0xFFD97706), Icons.savings_rounded),
    };
    return Container(
      margin: EdgeInsets.fromLTRB(20, first ? 4 : 4, 20, last ? 12 : 0),
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
          PriceText(txn.amount, size: 14),
        ],
      ),
    );
  }
}
