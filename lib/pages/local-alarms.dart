import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wake_together/database.dart';

import '../alarm.dart';

/// Widget page for Local Alarms
class LocalAlarmsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LocalAlarmsPageState();
}

class _LocalAlarmsPageState extends State<LocalAlarmsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Radius for rounded cards.
  static const double _cardRadius = 32;

  /// Static Alarm to represent Alarm Adder at the end of list
  static final nullAlarm = Alarm(
      description: "null", time: TimeOfDay(hour: 0, minute: 0), days: Set());

  /// Adds an alarm to the database
  Future<void> addAlarm(Alarm alarm) async {
    await DatabaseProvider().insertAlarm(alarm);
    setState(() {});
  }

  /// Removes an alarm from the database
  Future<void> deleteAlarm(Alarm alarm) async {
    await DatabaseProvider().deleteAlarm(alarm.id!);
    setState(() {});
  }

  /// Searches for the appropriate insertion index for an alarm.
  ///
  /// Uses binary search to find the posiiton to insert a new alarm such that
  /// the list of alarms remains sorted. Used for list animation.
  int _findInsertPosition(TimeOfDay time, List<Alarm> alarms) {
    double _toDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

    int _binarySearch(int start, int end) {
      if (start >= end) {
        return end;
      }
      final int mid = start + (end - start) ~/ 2;
      if (_toDouble(alarms[mid].time) <= _toDouble(time)) {
        return _binarySearch(mid + 1, end);
      } else {
        return _binarySearch(start, mid);
      }
    }

    if (alarms.length == 1) {
      return 0;
    }
    return _binarySearch(0, alarms.length - 2);
  }

  /// Shows a Time Picker for user to select the time for a new alarm.
  Future<void> newAlarm(List<Alarm> alarms) async {
    Future<TimeOfDay?> selectedTimeFuture =
        showTimePicker(context: context, initialTime: TimeOfDay.now());
    TimeOfDay? selectedTime = await selectedTimeFuture;
    if (selectedTime != null) {
      await addAlarm(Alarm(time: selectedTime, description: '', days: Set()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Call build from super for AutomaticKeepAliveClientMixin
    super.build(context);

    return Scaffold(
        body: FutureBuilder<List<Alarm>>(
            future: DatabaseProvider().getAlarms(),
            initialData: <Alarm>[],
            builder: (context, AsyncSnapshot<List<Alarm>> snapshot) {
              if (snapshot.hasData) {

                List<Alarm> alarms = snapshot.data!;

                return ListView.builder(
                  itemCount: alarms.length,
                  itemBuilder: (context, index) => alarms[index] != nullAlarm
                      ? _getListItem(alarms, index)
                      : _getAlarmAdder(alarms),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }));
  }

  /// Provides the list item widget for an alarm.
  Widget _getListItem(List<Alarm> alarms, int index) {
    Alarm alarm = alarms[index];

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      padding: EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 48),
      decoration: BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(-0.8, -0.5),
              radius: 3,
              colors: [
                Colors.blue[500] ?? Colors.blue,
                Colors.blue[900] ?? Colors.blue
              ]),
          borderRadius: BorderRadius.all(Radius.circular(_cardRadius)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
            )
          ]),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(alarm.time.format(context),
                style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.white)),
            Spacer(),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                deleteAlarm(alarm);
              },
            )
          ]),
    );
  }

  /// Provides the dashed Alarm Adder to place at the end of the list.
  Widget _getAlarmAdder(List<Alarm> alarms) {
    return Container(
        margin: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
        child: InkWell(
            borderRadius: BorderRadius.circular(_cardRadius),
            onTap: () => newAlarm(alarms),
            child: DottedBorder(
                strokeWidth: 2,
                dashPattern: [10, 5],
                radius: Radius.circular(_cardRadius),
                customPath: (size) {
                  return Path()
                    ..moveTo(_cardRadius, 0)
                    ..lineTo(size.width - _cardRadius, 0)
                    ..arcToPoint(Offset(size.width, _cardRadius),
                        radius: Radius.circular(_cardRadius))
                    ..lineTo(size.width, size.height - _cardRadius)
                    ..arcToPoint(Offset(size.width - _cardRadius, size.height),
                        radius: Radius.circular(_cardRadius))
                    ..lineTo(_cardRadius, size.height)
                    ..arcToPoint(Offset(0, size.height - _cardRadius),
                        radius: Radius.circular(_cardRadius))
                    ..lineTo(0, _cardRadius)
                    ..arcToPoint(Offset(_cardRadius, 0),
                        radius: Radius.circular(_cardRadius));
                },
                child: Container(
                  padding:
                      EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 32,
                      ),
                      Text("Add Alarm",
                          style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Theme.of(context).colorScheme.onSurface))
                    ],
                  ),
                ))));
  }
}
