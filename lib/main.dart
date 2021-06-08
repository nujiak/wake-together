import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wake_together/blocs/notification-bloc.dart';
import 'package:wake_together/pages/alarm-screen.dart';
import 'package:wake_together/pages/local-alarms.dart';
import 'package:wake_together/pages/shared-alarms/shared-alarms.dart';

import 'blocs/bloc-provider.dart';
import 'data/models/alarm.dart';

/// Payload if app was launched from notification.
String? _payload;

/// Initial route for the app.
///
/// If the app was launched from notification,
/// initial route points to AlarmScreen.
late final String _initialRoute;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationBloc notificationBloc = BlocProvider.notificationBloc;

  // Initialise notifications and pass in setter for _payload as callback.
  await notificationBloc.initialize((payload) => _payload = payload);

  // Handle situation when app is launched by the notification.
  _payload = await notificationBloc.getPayLoad();
  _initialRoute = _payload == null ? Pages.routeName : AlarmScreen.routeName;

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light),
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.focusedChild?.unfocus();
          }
        },
        child: MaterialApp(
          title: 'WakeTogether',
          theme: ThemeData(
              primaryColor: Colors.blue,
              brightness: Brightness.dark,
              fontFamily: GoogleFonts.openSans().fontFamily,
              textTheme: TextTheme(
                headline1: TextStyle(fontWeight: FontWeight.bold),
                headline2: TextStyle(fontWeight: FontWeight.bold),
                headline3: TextStyle(fontWeight: FontWeight.bold),
                headline4: TextStyle(fontWeight: FontWeight.bold),
                headline5: TextStyle(fontWeight: FontWeight.bold),
                headline6: TextStyle(fontWeight: FontWeight.bold),
              ),
              timePickerTheme: TimePickerThemeData(
                dayPeriodBorderSide: BorderSide.none,
                shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(48)),
                hourMinuteShape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24)),
                dayPeriodShape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  backgroundColor: Colors.grey[800]
              )),
          initialRoute: _initialRoute,
          routes: {
            Pages.routeName: (_) => Pages(),
            AlarmScreen.routeName: (_) => AlarmScreen(_payload!),
          },
        ),
      ),
    );
  }
}

class Pages extends StatefulWidget {

  static String routeName = "/home";

  @override
  State<StatefulWidget> createState() => _PagesState();
}

class _PagesState extends State<Pages> {
  int _currentPageIndex = 0;

  /// BLoC for notification.
  final NotificationBloc _bloc = BlocProvider.notificationBloc;

  @override
  void dispose() {
    BlocProvider.disposeNotificationBloc();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Handle situation when notification is selected while app is opened.
    _bloc.selectedAlarms.listen((Alarm alarm) async {
      await Navigator.pushNamed(context, AlarmScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(initialPage: 0);

    void changePage(int index) {
      setState(() {
        _currentPageIndex = index;
        controller.animateToPage(index,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut);
      });
    }

    Widget _getBottomNavigationBarItem(int index, String label, IconData icon) {
      final colour = index == _currentPageIndex
          ? Theme.of(context).primaryColor
          : Theme.of(context).colorScheme.onSurface.withAlpha(100);
      final splashColour = index == _currentPageIndex
          ? Theme.of(context).primaryColor.withAlpha(50)
          : Theme.of(context).colorScheme.onSurface.withAlpha(50);
      return Expanded(
        flex: 20,
        child: InkResponse(
          onTap: () => changePage(index),
          splashFactory: InkRipple.splashFactory,
          radius: 96,
          highlightColor: Colors.transparent,
          splashColor: splashColour,
          child: Container(
            height: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: colour),
                Text(label, style: TextStyle(color: colour),)
              ],
            ),
          ),
        ),
      );
    }

    Widget _getBottomNavigationBar(int indexSelected) {
      return Container(
          width: double.infinity,
          height: 64,
          child: Material(
            child: Row(
              children: [
                _getBottomNavigationBarItem(0, "My Alarms", Icons.alarm),
                _getBottomNavigationBarItem(1, "Shared Alarms", Icons.alarm),
              ],
            ),
          )
      );
    }

    return Scaffold(
      bottomNavigationBar: _getBottomNavigationBar(_currentPageIndex),
      body: PageView(
        onPageChanged: (index) => setState(() => _currentPageIndex = index),
        scrollDirection: Axis.horizontal,
        controller: controller,
        children: <Widget>[
          LocalAlarmsPage(),
          AuthenticationPage()
        ],
      ),
    );
  }
}
