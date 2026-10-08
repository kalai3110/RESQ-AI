import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../disaster/disaster_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notif = Provider.of<NotificationProvider>(context, listen: false);
    notif.fetchNotifications(userId: auth.currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {
    final notif = Provider.of<NotificationProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Operational Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.secondary,
        actions: [
          if (notif.unreadCount > 0)
            TextButton(
              onPressed: () => notif.markAllRead(userId: auth.currentUser?.id),
              child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: notif.isLoading && notif.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notif.notifications.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.notifications_none_outlined,
                  title: 'No Notifications',
                  message: 'You have no pending emergency alerts or updates at this time.',
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notif.notifications.length,
                    itemBuilder: (ctx, i) {
                      final item = notif.notifications[i];
                      return _buildNotificationCard(context, item);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationItem item) {
    IconData iconData;
    Color iconColor;

    switch (item.notificationType) {
      case 'disaster_report':
        iconData = Icons.emergency_rounded;
        iconColor = AppColors.primary;
        break;
      case 'ai_severity':
        iconData = Icons.psychology_rounded;
        iconColor = AppColors.severityCritical;
        break;
      case 'rescue_assigned':
      case 'rescue_status':
        iconData = Icons.directions_boat_rounded;
        iconColor = AppColors.statusInfo;
        break;
      case 'medical_assigned':
      case 'medical_status':
        iconData = Icons.local_hospital_rounded;
        iconColor = AppColors.severityCritical;
        break;
      case 'shelter_update':
        iconData = Icons.night_shelter_rounded;
        iconColor = AppColors.statusSuccess;
        break;
      case 'resource_update':
        iconData = Icons.inventory_2_rounded;
        iconColor = AppColors.statusWarning;
        break;
      default:
        iconData = Icons.info_outline_rounded;
        iconColor = AppColors.accent;
    }

    final formattedDate = item.createdAt != null
        ? DateFormat('MMM d, hh:mm a').format(DateTime.parse(item.createdAt!))
        : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
          width: item.isRead ? 1 : 1.3,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () {
          final notif = Provider.of<NotificationProvider>(context, listen: false);
          notif.markRead(item.id);
          if (item.reportId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DisasterDetailsScreen(reportId: item.reportId!)),
            );
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (!item.isRead)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.message,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
