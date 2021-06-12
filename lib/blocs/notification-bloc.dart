import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:wake_together/data/alarm-helper.dart' as AlarmHelper;

import '../data/models/alarm.dart';

class NotificationBloc {

  /// Singleton instance of NotificationBloc.
  static NotificationBloc? _instance;

  /// Lazily provides the singleton instance.
  static NotificationBloc get instance {
    if (_instance == null) {
      _instance = NotificationBloc._();
    }
    return _instance!;
  }

  /// Private constructor for initialising the bloc.
  NotificationBloc._() {
    // Observe the selectedPayloads sink to add alarm to selectedAlarms
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
  ValueStream<Alarm> get selectedAlarms => _selectedAlarms.stream;

  /// Initializes alarm-helper.
  Future<bool> initialize(void Function(String) onReceivePayload) async {
    await AlarmHelper.initialize((String? payload) async {
      if (payload != null) {
        onReceivePayload(payload);
        selectedPayloads.add(payload);
      }
    });
    return true;
  }

  /// Returns a payload if app was launched from notifications.
  ///
  /// Wrapper for getPayload() in alarm-helper
  Future<String?> getPayLoad() async {
    return AlarmHelper.getPayLoad();
  }

  /// Disposes all StreamControllers.
  void dispose() {
    _selectedPayloads.close();
    _selectedAlarms.close();
  }
}