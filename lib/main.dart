import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wake_together/alarm-helper.dart' as AlarmHelper;
import 'package:wake_together/pages/alarm-screen.dart';
import 'package:wake_together/pages/local-alarms.dart';

void main() {
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
          home: Pages(),
        ),
      ),
    );
  }
}

class Pages extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PagesState();
}

class _PagesState extends State<Pages> {
  int _currentPageIndex = 0;

  /// Future used to initialize AlarmHelper
  late final Future<void> _alarmHelperInitialized;

  @override
  void initState() {
    super.initState();

    _alarmHelperInitialized = AlarmHelper.initialize((payload) async {
      if (payload == null) {
        return;
      }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AlarmScreen(payload)));
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
      body: FutureBuilder( // Used to ensure AlarmHelper is initialized first
        future: _alarmHelperInitialized,
        builder: (context, AsyncSnapshot<void> snapshot) {
          if (snapshot.hasData) {
            return PageView(
              onPageChanged: (index) => _currentPageIndex = index,
              scrollDirection: Axis.horizontal,
              controller: controller,
              children: <Widget>[
                LocalAlarmsPage(),
                Center(
                  child: Text("Coming soon..."),
                )
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
