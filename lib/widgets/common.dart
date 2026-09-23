import 'package:flutter/material.dart';

import '../app.dart';
import '../models/onboarding.dart';

/// Formats an amount in whole currency units, e.g. 82000 -> "₦82,000".
String formatPrice(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return '${OnboarderApp.currencySymbol}$buffer';
}

/// A formatted price label.
class PriceText extends StatelessWidget {
  const PriceText(this.value, {super.key, this.size, this.weight});

  final int value;
  final double? size;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPrice(value),
      style: TextStyle(
        fontSize: size ?? 14,
        fontWeight: weight ?? FontWeight.w800,
        color: OnboarderApp.ink,
      ),
    );
  }
}

/// Coloured status pill for pending / active / suspended accounts.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final OnboardStatus status;

  @override
  Widget build(BuildContext context) {
    final c = onboardStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        onboardStatusName(status),
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Section heading with an optional trailing action label.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
          if (action != null)
            InkWell(
              onTap: onAction ?? () {},
              child: Text(
                action!,
                style: TextStyle(
                  color: OnboarderApp.brandTealDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Page title used on tab root screens.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Standard scroll container for tab bodies (safe-area + bottom padding).
class AppScrollTab extends StatelessWidget {
  const AppScrollTab({super.key, required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
        ),
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

/// Shows the KYC-voucher style header used at the top of list accounts.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}