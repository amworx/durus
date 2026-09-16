// Durus (دروس) — local system notifications.
//
// Lightweight wrapper around flutter_local_notifications. Used to display
// real Android system notifications (banner + sound) when new rows arrive
// via Supabase Realtime — no FCM required, works entirely offline once
// the app is running.
//
// Web: silently no-ops (flutter_local_notifications has no web support).
import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channel created by the plugin on first show.
const _kChannelId = 'durus_notifications';

/// Brand teal matching the launcher icon.
const _kTealAndroid = Color(0xFF0E7C66);

/// Lightweight wrapper around [FlutterLocalNotificationsPlugin].
///
/// Call [init] once in `main()` before `runApp()`. Then call [show] from
/// the Realtime callbacks whenever a new row arrives.
class LocalNotifications {
  LocalNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set by the app to navigate when a notification is tapped.
  static void Function(NotificationResponse response)? onTapped;

  // ---------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------

  /// Initialize the plugin and request notification permission (Android 13+).
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  static Future<void> init() async {
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        onTapped?.call(response);
      },
    );

    // Android 13+ requires runtime permission.
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
  }

  // ---------------------------------------------------------------
  // Show
  // ---------------------------------------------------------------

  /// Display a system notification. No-op on web.
  ///
  /// [id] should be deterministic per logical notification (e.g.
  /// `uuid.hashCode & 0x7FFFFFFF`) so the same row overwrites rather
  /// than stacks.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        'الإشعارات',
        channelDescription: 'إشعارات دروس — تحديثات، حضور، إعلانات',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: _kTealAndroid,
        ticker: 'دروس',
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------
  // Launch details (for terminated-state taps)
  // ---------------------------------------------------------------

  /// Check whether the app was launched by a notification tap.
  ///
  /// Returns `null` on web. Call once in `main()` after [init] and
  /// before `runApp()` to route the user to the notifications screen.
  static Future<NotificationAppLaunchDetails?> launchDetails() async {
    if (kIsWeb) return null;
    return _plugin.getNotificationAppLaunchDetails();
  }
}
