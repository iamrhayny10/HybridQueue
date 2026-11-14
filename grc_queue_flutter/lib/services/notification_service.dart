// lib/services/notification_service.dart
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(settings);

    // Android 13+ (API 33+) requires an explicit runtime permission
    // request for POST_NOTIFICATIONS — declaring it in the manifest
    // alone is not enough, and without this call every notification
    // is silently dropped with no error shown anywhere.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── "Your turn has arrived" — fires once when status becomes Serving ──
  // This is the most important alert, so it uses max urgency, a distinct
  // vibration pattern, and the full-screen-style heads-up alert.
  static Future<void> showYourTurn({
    required String ticketNumber,
    required String windowName,
    required String serviceType,
  }) async {
    await init();
    await _plugin.show(
      1,
      '🔔 Your turn has arrived!',
      'Ticket $ticketNumber ($serviceType) — Go to $windowName now.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'queue_turn',
          'Queue Turn Alerts',
          channelDescription: 'Alerts when your ticket is called',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          vibrationPattern: _urgentVibration,
          playSound: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  // ── "About to be called" — 10-minute and 5-minute heads-up ──────────
  static Future<void> showApproachingAlert({
    required String ticketNumber,
    required String serviceType,
    required int minutesAway,
  }) async {
    await init();
    final id = minutesAway <= 5 ? 3 : 4; // separate IDs so both can show
    await _plugin.show(
      id,
      '⏳ Almost your turn',
      'Ticket $ticketNumber ($serviceType) — about $minutesAway min away. '
      'Please stay nearby.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'queue_approaching',
          'Approaching Turn Alerts',
          channelDescription: 'Warns when your estimated wait is getting short',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Late-arrival warning — fires once, a few minutes after being
  //    called, if the student hasn't been marked Served yet ───────────
  static Future<void> showLateWarning({
    required String ticketNumber,
    required String windowName,
    required int minutesLeft,
  }) async {
    await init();
    await _plugin.show(
      5,
      '⚠️ Your ticket may be cancelled',
      'Ticket $ticketNumber — you have about $minutesLeft min to reach '
      '$windowName before your ticket is cancelled.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'queue_late_warning',
          'Late Arrival Warning',
          channelDescription: 'Warns when a called ticket is about to be cancelled',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          vibrationPattern: _urgentVibration,
          playSound: true,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  static Future<void> showQueueUpdate(String message) async {
    await init();
    await _plugin.show(
      2,
      'GRC Queue Tracker',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'queue_updates',
          'Queue Updates',
          channelDescription: 'General queue updates',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();

  static final Int64List _urgentVibration =
      Int64List.fromList([0, 400, 200, 400, 200, 400]);
}
