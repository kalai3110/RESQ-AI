class NotificationItem {
  final int id;
  final int? userId;
  final String title;
  final String message;
  final String notificationType;
  final int? reportId;
  final bool isRead;
  final String? createdAt;

  NotificationItem({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.reportId,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'],
      title: json['title'] ?? 'Alert',
      message: json['message'] ?? '',
      notificationType: json['notification_type'] ?? 'general',
      reportId: json['report_id'],
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'],
    );
  }
}
