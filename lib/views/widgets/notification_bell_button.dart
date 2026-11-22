import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'notification_center_modal.dart';

class NotificationBellButton extends StatelessWidget {
  final String userId;
  final NotificationService _notificationService;
  final void Function(String? orderId)? onOrderSelected;
  final Color? color;

  NotificationBellButton({
    super.key,
    required this.userId,
    NotificationService? notificationService,
    this.onOrderSelected,
    this.color,
  }) : _notificationService = notificationService ?? NotificationService();

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<int>(
      initialData: 0,
      stream: _notificationService.watchUnreadCount(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                unreadCount > 0 ? Icons.notifications_active_outlined : Icons.notifications_outlined,
                color: color,
              ),
              tooltip: 'Notifications ($unreadCount non lues)',
              onPressed: () {
                NotificationCenterModal.show(
                  context,
                  userId: userId,
                  onOrderSelected: onOrderSelected,
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
