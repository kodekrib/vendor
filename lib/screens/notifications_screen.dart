import '../widgets/swipe_notification.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/onboarder_app_bar.dart';

/// Notifications for the onboarder app, loaded from the shared
/// `/api/v1/notifications` endpoints.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();

  List<AppNotification> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _token => OnboarderSession.instance.accessToken ?? '';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.list(_token);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    _toggleRead(n, true);
    try {
      await _service.markRead(_token, n.id);
    } catch (_) {
      _toggleRead(n, false);
    }
  }

  void _toggleRead(AppNotification n, bool isRead) {
    if (!mounted) return;
    setState(() {
      _items = _items
          .map((e) => e.id == n.id ? e.copyWith(isRead: isRead) : e)
          .toList();
    });
  }

  Future<void> _markAllRead() async {
    final previous = _items;
    setState(
        () => _items = _items.map((e) => e.copyWith(isRead: true)).toList());
    try {
      await _service.markAllRead(_token);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((e) => !e.isRead).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: OnboarderApp.surfaceMuted,
        appBar: OnboarderAppBar(
          title: 'Notifications',
          actions: [
            if (unread.isNotEmpty)
              TextButton(
                onPressed: _markAllRead,
                child: const Text('Mark all read'),
              ),
          ],
          bottom: TabBar(
            indicatorColor: OnboarderApp.brandTealDark,
            labelColor: OnboarderApp.brandTealDark,
            unselectedLabelColor: const Color(0xFF9AA1AA),
            tabs: [
              const Tab(text: 'All'),
              Tab(text: 'Unread (${unread.length})'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : TabBarView(
                    children: [
                      _buildList(
                        _items,
                        emptyMessage: "You don't have any notifications yet.",
                      ),
                      _buildList(
                        unread,
                        emptyMessage: "You're all caught up.",
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildList(
    List<AppNotification> items, {
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return _EmptyState(message: emptyMessage);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: items.length,
        itemBuilder: (context, i) => SwipeNotification(
            id: items[i].id,
            onDelete: () => _service.delete(_token, items[i].id),
            onDeleted: () {
              if (mounted) {
                setState(() =>
                    _items = _items.where((e) => e.id != items[i].id).toList());
              }
            },
            child: _NotificationCard(
              notification: items[i],
              onTap: () => _markRead(items[i]),
            )),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.notifications_off_rounded,
            size: 46, color: Color(0xFF9AA1AA)),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 46, color: Color(0xFFD97706)),
            const SizedBox(height: 12),
            Text(
              "Couldn't load notifications.\n$message",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static (IconData, Color) _visualFor(String type) {
    switch (type) {
      case 'commission':
      case 'payout':
      case 'earning':
        return (Icons.savings_rounded, const Color(0xFFD97706));
      case 'rider':
      case 'delivery':
        return (Icons.two_wheeler_rounded, const Color(0xFF2563EB));
      case 'mover':
      case 'moving':
        return (Icons.local_shipping_rounded, const Color(0xFFEA580C));
      case 'vendor':
      case 'onboarding':
        return (Icons.storefront_rounded, const Color(0xFF0D9488));
      default:
        return (Icons.notifications_none_rounded, OnboarderApp.brandTealDark);
    }
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today · $hh:$mm';
    if (diff == 1) return 'Yesterday · $hh:$mm';
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visualFor(notification.type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: OnboarderApp.ink,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9AA1AA)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                        fontSize: 13, height: 1.4, color: Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D9488),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
