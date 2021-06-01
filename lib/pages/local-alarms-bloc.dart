import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wake_together/database.dart';

import '../alarm.dart';

class LocalAlarmsBloc {

  LocalAlarmsBloc() {
    // Fetch alarm from database on initialisation.
    _getAlarms();
  }

  final _alarmsController = StreamController<List<Alarm>>();

  /// Stream to broadcast Alarms when the database is operated on.
  get alarms => _alarmsController.stream;

  /// Disposes sinks.
  ///
  /// To be called in the Widget's dispose method.
  void dispose() {
    _alarmsController.close();
  }

  /// Adds an alarm to the database using a Future.
  void addAlarm({required Future<TimeOfDay?> future}) async {
    TimeOfDay? time = await future;
    if (time != null) {
      DatabaseProvider().insertAlarm(Alarm(time: time, description: '', days: Set()));
    }
    _getAlarms();
  }

  /// Removes an alarm from the database.
  void deleteAlarm(Alarm alarm) {
    DatabaseProvider().deleteAlarm(alarm.id!);
    _getAlarms();
  }

  /// Updates an alarm in the database.
  void updateAlarm(Alarm alarm) {
    DatabaseProvider().updateAlarm(alarm);
    _getAlarms();
  }

  /// Fetches the list of Alarms from the database and adds it to the sink.
  _getAlarms() async {
    _alarmsController.sink.add(await DatabaseProvider().getAlarms());
  }
}