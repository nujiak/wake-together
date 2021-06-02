import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/models/alarm.dart';

class AlarmScreen extends StatefulWidget {

  static String routeName = "/alarmScreen";
  late final String payload;

  AlarmScreen(this.payload);

  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {

  /// Alarm to be displayed in this screen.
  late final Alarm alarm;

  @override
  void initState() {
    super.initState();
    alarm = Alarm.fromJsonEncoding(widget.payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(alarm.time.format(context)),
            Text(alarm.description),
          ],
        ),
      ),
    );  }
}