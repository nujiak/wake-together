import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../alarm.dart';

class AlarmScreen extends StatelessWidget {

  /// Alarm to be displayed in this screen.
  late final Alarm alarm;

  /// Constructor from payload.
  AlarmScreen(String payload) {
    this.alarm = Alarm.fromJsonEncoding(payload);
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
    );
  }
}
