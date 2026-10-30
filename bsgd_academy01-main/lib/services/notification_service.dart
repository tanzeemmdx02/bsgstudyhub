import 'package:flutter/foundation.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime createdAt;

  AppNotification({
    required this.title,
    required this.body,
    required this.createdAt,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [
    AppNotification(
      title: 'Welcome Notice',
      body: 'Check out the new regional suggestion features!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void addNotification({required String filename, required String uploaderName, String type = 'suggestion'}) {
    _notifications.insert(
      0,
      AppNotification(
        title: 'New ${type[0].toUpperCase()}${type.substring(1)} Uploaded!',
        body: '$filename has been uploaded by $uploaderName',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}