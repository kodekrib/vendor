import 'package:flutter/material.dart';

import '../app.dart';

/// Notifications for the onboarder app. Static data for now — the same shape
/// the customer and rider apps ship with.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = _items;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: OnboarderApp.surfaceMuted,
        appBar: AppBar(
          backgroundColor: OnboarderApp.surfaceMuted,
          surfaceTintColor: Colors.transparent,
          title: const Text('Notifications'),
          bottom: TabBar(
            indicatorColor: OnboarderApp.brandTealDark,
            labelColor: OnboarderApp.brandTealDark,
            unselectedLabelColor: Color(0xFF9AA1AA),
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Unread (2)'),
            ],
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          itemCount: items.length,
          itemBuilder: (context, i) => _NotificationCard(notification: items[i]),
        ),
      ),
    );
  }
}

class _Notification {
  const _Notification(this.icon, this.iconColor, this.title, this.body, this.time);

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
}

const _items = <_Notification>[
  _Notification(
    Icons.savings_rounded,
    Color(0xFFD97706),
    'Commission credited',
    'You earned ₦1,205 from FreshCart orders.',
    'Today · 09:41',
  ),
  _Notification(
    Icons.pending_actions_rounded,
    Color(0xFFD97706),
    'BeautyStack awaits review',
    'The vendor you onboarded is pending ops approval.',
    'Today · 08:12',
  ),
  _Notification(
    Icons.two_wheeler_rounded,
    Color(0xFF2563EB),
    'Rider earnings updated',
    'You earned ₦465 from Adewale Johnson deliveries.',
    'Yesterday · 20:04',
  ),
  _Notification(
    Icons.storefront_rounded,
    Color(0xFF0D9488),
    'Warm onboarding tip',
    'Onboard 10 vendors this month and earn a bonus.',
    'Yesterday · 10:00',
  ),
  _Notification(
    Icons.account_balance_wallet_rounded,
    Color(0xFF0D9488),
    'Payout scheduled',
    '₦31,730 will be sent to your account on Friday.',
    'Mon · 09:00',
  ),
];

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final _Notification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0EE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: notification.iconColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(notification.icon,
                size: 21, color: notification.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notification.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                    Text(notification.time,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9AA1AA))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.body,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF4B5563))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}