import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:wake_together/data/alarm-helper.dart' as AlarmHelper;

import '../data/models/alarm.dart';

class NotificationBloc {

  NotificationBloc() {
    _selectedPayloads.stream.listen((String payload) {
      Alarm alarm = Alarm.fromJsonEncoding(payload);
      _selectedAlarms.add(alarm);
    });
  }

  final StreamController<String> _selectedPayloads = StreamController();

  /// Sink for adding payloads from selected notifications.
  Sink<String> get selectedPayloads => _selectedPayloads.sink;

  final BehaviorSubject<Alarm> _selectedAlarms = BehaviorSubject();

  /// Stream for broadcasting alarms from selected notifications.
  Stream<Alarm> get selectedAlarms => _selectedAlarms.stream;

  Future<bool> initialize() async {
    await AlarmHelper.initialize((String? payload) async {
      if (payload != null) {
        selectedPayloads.add(payload);
      }
    });
    return true;
  }

  void dispose() {
    _selectedPayloads.close();
    _selectedAlarms.close();
  }
}