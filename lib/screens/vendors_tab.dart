import 'package:flutter/material.dart';

import '../app.dart';
import '../models/onboarding.dart';
import '../services/onboard_service.dart';
import '../widgets/common.dart';
import 'onboard_vendor_screen.dart';
import 'vendor_commission_detail_screen.dart';

class VendorsTab extends StatelessWidget {
  const VendorsTab({super.key});

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
                        'Vendors',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OnboardVendorScreen(),
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
                  'You are the account officer for every vendor below.',
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
                  final v = repo.vendors[i];
                  return _VendorCard(vendor: v, last: i == repo.vendors.length - 1);
                },
                childCount: repo.vendors.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor, required this.last});

  final VendorRecord vendor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VendorCommissionDetailScreen(
              vendorId: int.tryParse(vendor.id) ?? 0,
              vendorName: vendor.ownerName,
              storeName: vendor.storeName,
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
                AccountAvatar(icon: vendor.icon, color: vendor.color, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor.storeName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        '${vendor.ownerName} · ${vendor.category}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                StatusPill(vendor.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _VendorFact(
                    icon: Icons.location_on_outlined,
                    text: '${vendor.city} · ${vendor.address}',
                  ),
                ),
                const SizedBox(width: 12),
                _VendorFact(
                  icon: Icons.percent_rounded,
                  text: '${vendor.commissionRate}%',
                ),
              ],
            ),
            if (vendor.monthlyCommissions > 0) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text(
                    '${formatPrice(vendor.monthlyCommissions)} app commission this month '
                    '→ ${formatPrice((vendor.monthlyCommissions * vendor.commissionRate / 100).round())} your cut',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VendorFact extends StatelessWidget {
  const _VendorFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: OnboarderApp.brandTealDark),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}