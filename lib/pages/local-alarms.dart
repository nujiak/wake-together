import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wake_together/alarm-helper.dart';
import 'package:wake_together/database.dart';

import '../alarm.dart';
import '../constants.dart';

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

  /// Adds an alarm to the database.
  Future<void> addAlarm(Alarm alarm) async {
    DatabaseProvider().insertAlarm(alarm).then((_) => setState(() {}));
  }

  /// Removes an alarm from the database.
  void deleteAlarm(Alarm alarm) {
    DatabaseProvider().deleteAlarm(alarm.id!).then((_) => setState(() {}));
  }

  /// Updates an alarm in the database.
  void updateAlarm(Alarm alarm) {
    DatabaseProvider().updateAlarm(alarm);
  }

  /// Searches for the appropriate insertion index for an alarm.
  ///
  /// Uses binary search to find the position to insert a new alarm such that
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
                registerAllAlarms(context, alarms);

                return ListView.builder(
                  itemCount: alarms.length + 1,
                  itemBuilder: (context, index) => index < alarms.length
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
    Color _textColor = Theme.of(context).colorScheme.onSurface;
    Color _textColorDisabled = Theme.of(context).colorScheme.onSurface.withAlpha(100);

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 24),
      decoration: BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(-0.8, -0.5),
              radius: 3,
              colors: [Colors.grey[800]!, Colors.grey[900]!]),
          borderRadius: BorderRadius.all(Radius.circular(_cardRadius)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(2, 2))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(alarm.time.format(context),
                style: Theme.of(context)
                    .textTheme
                    .headline3!
                    .copyWith(color: _textColor)),
            Container(
              height: 36,
              margin: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: Days.allList
                      .map((day) => _getDayCheckbox(alarm, day))
                      .toList()),
            ),
            Container(
              child: TextFormField(
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Note",
                  labelStyle: TextStyle(color: _textColorDisabled),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _textColorDisabled)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _textColorDisabled)),
                ),
                cursorColor: _textColorDisabled,
                initialValue: alarm.description,
                onChanged: (newDescription) {
                  alarm.description = newDescription;
                  updateAlarm(
                      alarm); // Update database without refreshing state
                },
              ),
            ),
            Container(
                margin: EdgeInsets.only(top: 8),
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteAlarm(alarm);
                  },
                ))
          ]),
    );
  }

  /// Provides the dashed Alarm Adder to place at the end of the list.
  Widget _getAlarmAdder(List<Alarm> alarms) {
    Color _color = Theme.of(context).colorScheme.onSurface.withAlpha(127);
    return Container(
        margin: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
        child: InkWell(
            borderRadius: BorderRadius.circular(_cardRadius),
            onTap: () => newAlarm(alarms),
            child: DottedBorder(
                strokeWidth: 4,
                dashPattern: [10, 5],
                radius: Radius.circular(_cardRadius),
                color: _color,
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
                      EdgeInsets.only(left: 24, right: 24, top: 36, bottom: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: 32,
                        color: _color,
                      ),
                      Text("Add Alarm",
                          style: TextStyle(fontSize: 24, color: _color))
                    ],
                  ),
                ))));
  }

  /// Provides a single day checkbox for a given alarm and day.
  ///
  /// Used in _getListItem.
  Widget _getDayCheckbox(Alarm alarm, Days day) {
    bool _selected = alarm.days.contains(day);

    return
        InkWell(
            onTap: () {
              alarm.days.contains(day)
                  ? alarm.days.remove(day)
                  : alarm.days.add(day);
              updateAlarm(alarm);
              setState(() {});
            },
            child: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                border: Border.all(
                    width: .5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(_selected ? 0 : 100)),
                shape: BoxShape.circle,
                color: _selected
                    ? Theme.of(context).colorScheme.onSurface.withAlpha(100)
                    : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  Days.shortStrings[day]!,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(_selected ? 255 : 100)),
                ),
              ),
            ));
  }
}
