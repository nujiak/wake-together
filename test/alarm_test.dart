import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wake_together/data/models/alarm.dart';
import 'package:wake_together/constants.dart';

void main() {
  group('Testing the alarm', () {
    // Creating an alarm object to test
    TimeOfDay current = TimeOfDay.now();
    Set<Days> days = Set();
    days.add(Days.TUESDAY);
    Alarm alarm = Alarm(id: 0, time: current, description: 'test', days: days);

    test('Testing alarm creation', () {
      expect(alarm.id, 0);
      expect(alarm.time, current);
      expect(alarm.description, 'test');
      expect(alarm.days, days);
    });

    test('Testing mapping function', () {
      Alarm test = Alarm.fromMap(alarm.toMap());
      expect(test.id, 0);
      expect(test.time, current);
      expect(test.description, 'test');
      expect(test.days, days);
    });

    test('Testing JsonEncoding', () {
      Alarm test = Alarm.fromJsonEncoding(alarm.toJsonEncoding());
      expect(test.id, 0);
      expect(test.time, current);
      expect(test.description, 'test');
      expect(test.days, days);
    });

    test('Testing getDaysInt', () {
      Set<Days> test = Set();
      test.add(Days.MONDAY);
      test.add(Days.THURSDAY);
      test.add(Days.SUNDAY);
      expect(Alarm.getDaysInt(test), 3 * 11 * 19);
    });

    test('Testing toString function', () {
      expect(alarm.toString(), 'id: 0, description: test, hour: ${current.hour}, minute: ${current.minute}, daysInt: ${Alarm.getDaysInt(days)}');
    });
  });
}