import 'package:flutter/material.dart';

import 'constants.dart';

/// A simple alarm object.
class Alarm {

  /// Unique id for the alarm.
  final int? id;

  /// Description of the alarm to be shown when ringing.
  String description;

  /// Time for the alarm to ring.
  TimeOfDay time;

  /// The days on which the alarm will be activated.
  Set<Days> days;

  bool activated;

  Alarm({
    this.id,
    required this.description,
    required this.time,
    required this.days,
    this.activated = true,
  });

  /// Converts the Alarm to a map for inserting into the database.
  Map<String, dynamic> toMap() {
    int daysInt = 1;
    this.days.forEach((Days day) => daysInt *= day.value);

    Map<String, dynamic> map = {
      'id': id,
      'description': description,
      'hour': time.hour,
      'minute': time.minute,
      'days': daysInt,
      'activated': activated ? 1 : 0,
    };

    if (this.id != null) {
      map['id'] = this.id;
    }

    return map;
  }

  /// Creates an Alarm from a map taken from the database.
  static Alarm fromMap(Map<String, dynamic> map) {
    int id = map['id'];
    String description = map['description'];
    int hour = map['hour'];
    int minute = map['minute'];
    bool activated = map['activated'] == 1;

    Alarm alarm = Alarm(
        id: id,
        description: description,
        time: TimeOfDay(hour: hour, minute: minute),
        days: _getDays(map['days']),
        activated: activated,
    );
    return alarm;
  }

  /// Get the set of days for which the alarm is activated.
  static Set<Days> _getDays(int days) {
    Set<Days> set = Set();
    for (Days day in Days.all) {
      if (days % day.value == 0) {
        set.add(day);
      }
    }
    return set;
  }

  /// Serializes the set of days for which the alarm is activated.
  static int getDaysInt(Set<Days> days) {
    int daysInt = 1;
    days.forEach((Days day) => daysInt *= day.value);
    return daysInt;
  }

  @override
  String toString() {
    return "id: $id, description: $description, hour: ${this.time.hour}, minute: ${this.time.minute}, daysInt: ${getDaysInt(days)}";
  }
}
