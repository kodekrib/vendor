import 'package:flutter/material.dart';

import '../app.dart';
import '../models/onboarding.dart';
import '../services/onboard_service.dart';
import '../widgets/common.dart';
import 'mover_commission_detail_screen.dart';
import 'onboard_mover_screen.dart';

class MoversTab extends StatelessWidget {
  const MoversTab({super.key});

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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Movers',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OnboardMoverScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Onboard'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Movers you recruit earn you a share of moving-job commissions.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFF6B7280)),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final m = repo.movers[i];
                  return _MoverCard(mover: m, last: i == repo.movers.length - 1);
                },
                childCount: repo.movers.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({required this.mover, required this.last});

  final MoverRecord mover;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MoverCommissionDetailScreen(
              riderId: int.tryParse(mover.id) ?? 0,
              riderName: mover.name,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(20, last ? 4 : 4, 20, last ? 12 : 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OnboarderApp.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAF0EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AccountAvatar(icon: mover.icon, color: mover.color, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mover.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        mover.vehicleType.isNotEmpty
                            ? '${mover.vehicleType} · ${mover.plateNumber}'
                            : 'No vehicles registered yet',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                StatusPill(mover.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.phone_iphone_rounded,
                          size: 15, color: OnboarderApp.brandTealDark),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          mover.email,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 18, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Text(
                      '${mover.commissionRate}% your share',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}