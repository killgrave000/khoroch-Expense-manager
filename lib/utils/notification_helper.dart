import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:khoroch/main.dart'; // ✅ Uses the initialized plugin from main.dart

class NotificationHelper {
  static Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_channel',
      'Budget Alerts',
      channelDescription: 'Notifications for budget limits and overspending',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }
}
