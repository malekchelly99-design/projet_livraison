import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationCenterModal extends StatelessWidget {
  final String userId;
  final NotificationService _notificationService;
  final void Function(String? orderId)? onOrderSelected;

  NotificationCenterModal({
    super.key,
    required this.userId,
    NotificationService? notificationService,
    this.onOrderSelected,
  }) : _notificationService = notificationService ?? NotificationService();

  static void show(
    BuildContext context, {
    required String userId,
    void Function(String? orderId)? onOrderSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationCenterModal(
        userId: userId,
        onOrderSelected: onOrderSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée de glissement
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.deepOrange, size: 18),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add_alert_outlined, size: 18),
                    tooltip: 'Test notification',
                    onPressed: () async {
                      await _notificationService.sendNotification(
                        userId: userId,
                        title: '🔔 Test en direct',
                        message: 'La notification temps réel fonctionne ! (${DateTime.now().hour}h${DateTime.now().minute.toString().padLeft(2, '0')})',
                        type: NotificationType.info,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 2),
                TextButton(
                  onPressed: () => _notificationService.markAllAsRead(userId),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    visualDensity: VisualDensity.compact,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('✓ Lu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste des notifications
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              initialData: const <NotificationModel>[],
              stream: _notificationService.watchUserNotifications(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 48, color: Colors.deepOrange),
                          const SizedBox(height: 12),
                          const Text(
                            'Synchronisation des notifications',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Réessayer'),
                            onPressed: () {
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 14),
                          const Text(
                            'Aucune notification pour le moment',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Les mises à jour de commandes et alertes apparaîtront ici en temps réel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.add_alert, size: 18),
                            label: const Text('Envoyer une notification test'),
                            onPressed: () async {
                              await _notificationService.sendNotification(
                                userId: userId,
                                title: '🔔 Test en direct',
                                message: 'Félicitations ! Les notifications en temps réel sont actives.',
                                type: NotificationType.info,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _buildNotificationTile(context, notif);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel notif) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (notif.type) {
      case NotificationType.orderNew:
        iconColor = Colors.orange.shade800;
        bgColor = Colors.orange.shade50;
        icon = Icons.restaurant;
        break;
      case NotificationType.orderDelivering:
        iconColor = Colors.indigo;
        bgColor = Colors.indigo.shade50;
        icon = Icons.delivery_dining;
        break;
      case NotificationType.orderDelivered:
        iconColor = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        icon = Icons.check_circle_outline;
        break;
      case NotificationType.orderCancelled:
        iconColor = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        icon = Icons.cancel_outlined;
        break;
      case NotificationType.orderStatus:
        iconColor = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        icon = Icons.inventory_2_outlined;
        break;
      case NotificationType.info:
        iconColor = Colors.deepOrange;
        bgColor = Colors.deepOrange.shade50;
        icon = Icons.info_outline;
        break;
    }

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) {
        _notificationService.deleteNotification(notif.id);
      },
      child: InkWell(
        onTap: () {
          if (!notif.isRead) {
            _notificationService.markAsRead(notif.id);
          }
          if (notif.orderId != null && onOrderSelected != null) {
            Navigator.pop(context);
            onOrderSelected!(notif.orderId);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? Colors.grey.shade200 : Colors.deepOrange.withValues(alpha: 0.3),
              width: notif.isRead ? 1 : 1.5,
            ),
            boxShadow: notif.isRead
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.deepOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRelativeTime(notif.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
