import 'package:wake_together/blocs/notification-bloc.dart';

class BlocProvider {

  /// Private constructor to prevent instantiation outside.
  BlocProvider._();

  /// Singleton instance of BlockProvider.
  static final BlocProvider _instance = BlocProvider._();

  NotificationBloc? _notificationBloc;

  factory BlocProvider() {
    return _instance;
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