import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'alarm.dart';
import 'constants.dart';

/// Registers all alarms
void registerAllAlarms(BuildContext context, List<Alarm> alarms) async {
  _flutterLocalNotificationsPlugin.cancelAll();
  for (Alarm alarm in alarms) {
    if (alarm.activated) {
      _registerAlarm(context, alarm);
    }
  }
}

/// Registers and alarm with Flutter Local Notifications
void _registerAlarm(BuildContext context, Alarm alarm) async {
  if (alarm.id == null) {
    return;
  }
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
      "WakeTogether",
      "Alarm",
      "WakeTogether Alarm",
      priority: Priority.high,
      importance: Importance.max,
      showWhen: true,
      fullScreenIntent: true,
  );
  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);
  if (alarm.days.isEmpty) {
    _flutterLocalNotificationsPlugin.zonedSchedule(
        alarm.id!,
        alarm.time.format(context),
        alarm.description,
        await _findNextAlarmDateTime(alarm.time), platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: alarm.toJsonEncoding(),
    );
  } else {
    for (Days day in alarm.days) {
      _flutterLocalNotificationsPlugin.zonedSchedule(
      _getAlarmId(alarm.id!, Days.DATETIME_WEEKDAY[day]),
          alarm.time.format(context),
          alarm.description,
          await _findNextAlarmDateTime(alarm.time), platformChannelSpecifics,
          androidAllowWhileIdle: true,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: alarm.toJsonEncoding(),
      );
    }
  }
}

/// Calculates the DateTime for the next instance an alarm should ring.
Future<tz.TZDateTime> _findNextAlarmDateTime(TimeOfDay time, [Days? day]) async {
  assert(_initialized);

  DateTime now = tz.TZDateTime.now(tz.local);

  DateTime next =
    DateTime(now.year, now.month, now.day, time.hour, time.minute);

  if (next.isBefore(DateTime.now())) {
    next = next.add(const Duration(days: 1));
  }
  if (day != null) {
    while (next.weekday != Days.DATETIME_WEEKDAY[day]) {
      next = next.add(const Duration(days: 1));
    }
  }
  tz.TZDateTime nextTZ = tz.TZDateTime.from(next, tz.local);
  return nextTZ;
}

/// Gives a "unique" id for a periodic alarm on each weekday.
int _getAlarmId(int id, int? weekday) {
  const int d = 0x10000000;
  return id + d * (weekday ?? 0);
}

/// Gives the actual alarm id for an id obtained from _getAlarmId.
int getAlarmId(int id) {
  const int d = 0x10000000;
  return id % d;
}

/// Whether the required libraries have been initialized.
bool _initialized = false;

/// Initializes flutter_local_notification and timezone.
Future<void> initialize(Future<void> Function(String?)? onSelectNotification) async {
  if (_initialized) {
    return;
  }
   __flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('alarm_white_24');
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);
  await __flutterLocalNotificationsPlugin!.initialize(
      initializationSettings,
      onSelectNotification: onSelectNotification);

  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
  _initialized = true;
}

/// FlutterLocalNotificationsPlugin for setting notifications.
FlutterLocalNotificationsPlugin? __flutterLocalNotificationsPlugin;
FlutterLocalNotificationsPlugin get _flutterLocalNotificationsPlugin {
  assert(_initialized);
  return __flutterLocalNotificationsPlugin!;
}