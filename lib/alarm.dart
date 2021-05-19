import 'package:flutter/material.dart';

import 'constants.dart';

class Alarm {
  final int id;
  String description;
  TimeOfDay time;
  Set<Days> days;

  Alarm({
    required this.id,
    required this.description,
    required this.time,
    required this.days});

  Map<String, dynamic> toMap() {
    int daysInt = 1;
    this.days.forEach((Days day) => daysInt *= day.value);

    return {
      'id': id,
      'description': description,
      'hour': time.hour,
      'minute': time.minute,
      'days': daysInt,
    };
  }

  static Alarm fromMap(Map<String, dynamic> map) {
    return Alarm(
        id: map['id'],
        description: map['description'],
        time: TimeOfDay(hour: map['hour'], minute: map['minute']),
        days: getDays(map['days'])
    );
  }

  static Set<Days> getDays(int days) {
    Set<Days> set = Set();
    for (Days day in Days.all) {
      if (days % day.value == 0) {
        set.add(day);
      }
    }
    return set;
  }

  static int getDaysInt(Set<Days> days) {
    int daysInt = 1;
    days.forEach((Days day) => daysInt *= day.value);
    return daysInt;
  }
}
