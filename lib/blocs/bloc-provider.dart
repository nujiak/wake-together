import 'package:wake_together/blocs/local-alarms-bloc.dart';
import 'package:wake_together/blocs/notification-bloc.dart';

class BlocProvider {

  /// Private constructor to prevent instantiation outside.
  BlocProvider._();

  /// Singleton instance of BlockProvider.
  static final BlocProvider _instance = BlocProvider._();

  LocalAlarmsBloc? _localAlarmsBloc;
  NotificationBloc? _notificationBloc;

  factory BlocProvider() {
    return _instance;
  }

  static LocalAlarmsBloc get localAlarmsBlock {
    if (_instance._localAlarmsBloc == null) {
      _instance._localAlarmsBloc = LocalAlarmsBloc();
    }
    return _instance._localAlarmsBloc!;
  }

  static disposeLocalAlarmsBloc() {
    _instance._localAlarmsBloc?.dispose();
  }

  static NotificationBloc get notificationBloc {
    if (_instance._notificationBloc == null) {
      _instance._notificationBloc = NotificationBloc();
    }
    return _instance._notificationBloc!;
  }

  static disposeNotificationBloc() {
    _instance._notificationBloc?.dispose();
  }
}