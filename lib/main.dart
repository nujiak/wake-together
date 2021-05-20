import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      ),
      child: MaterialApp(
        title: 'WakeTogether',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Pages(),
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

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentPageIndex,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.alarm), label: "My Alarms"),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              label: "Shared Alarms",
            )
          ],
          onTap: changePage),
      body: PageView(
        onPageChanged: (index) => setState(() => _currentPageIndex = index),
        scrollDirection: Axis.horizontal,
        controller: controller,
        children: <Widget>[LocalAlarmsPage(), Center(child: Text("Coming soon..."),)],
      ),
    );
  }
}
