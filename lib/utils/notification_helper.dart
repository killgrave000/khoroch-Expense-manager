import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String budgetChannelId = 'khoroch_budget';
  static const String budgetChannelName = 'Budget & Overspend Alerts';
  static const String budgetChannelDesc = 'Alerts when a category crosses its budget or approaches it';

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(init);

    const channel = AndroidNotificationChannel(
      budgetChannelId,
      budgetChannelName,
      description: budgetChannelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        budgetChannelId,
        budgetChannelName,
        channelDescription: budgetChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.recommendation,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
