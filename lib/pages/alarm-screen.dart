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
        margin: EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: Theme.of(context).backgroundColor,
              shape: CircleBorder(),
              child: Container(

                child: Text(alarm.time.format(context),
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Text(alarm.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );  }
}