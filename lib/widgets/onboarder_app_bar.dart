import 'package:flutter/material.dart';
import '../app.dart';
import '../screens/notifications_screen.dart';

/// One app bar language for every screen behind authentication: the screen
/// title on the left and the notifications shortcut on the right.
class OnboarderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OnboarderAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  final String title;

  /// Extra actions shown before the notifications shortcut.
  final List<Widget> actions;

  final PreferredSizeWidget? bottom;

  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(title),
      actions: [...actions, const NotificationsBell()],
      bottom: bottom,
    );
  }
}

/// Round notifications shortcut shared by every authenticated app bar.
class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
        ),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(Icons.notifications_none_rounded,
                    color: OnboarderApp.ink),
              ),
              Positioned(
                right: 8,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
