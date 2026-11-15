import 'package:flutter/material.dart';

import '../app.dart';
import '../models/onboarding.dart';
import '../services/onboard_service.dart';
import '../widgets/common.dart';
import 'onboard_rider_screen.dart';
import 'rider_commission_detail_screen.dart';

class RidersTab extends StatelessWidget {
  const RidersTab({super.key});

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
                        'Riders',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OnboardRiderScreen(),
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
                  'Riders you recruited earn you a share of delivery commissions.',
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
                  final r = repo.riders[i];
                  return _RiderCard(
                      rider: r, last: i == repo.riders.length - 1);
                },
                childCount: repo.riders.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.rider, required this.last});

  final RiderRecord rider;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RiderCommissionDetailScreen(
              riderId: int.tryParse(rider.id) ?? 0,
              riderName: rider.name,
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
                AccountAvatar(icon: rider.icon, color: rider.color, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rider.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        '${rider.vehicle} · ${rider.city}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                StatusPill(rider.status),
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
                        child: Text(rider.phone,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600)),
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
                      rider.monthlyFareShare > 0
                          ? '${OnboarderApp.currencySymbol}${rider.monthlyFareShare} your share'
                          : 'Awaiting activation',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: rider.monthlyFareShare > 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
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
