import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wake_together/blocs/bloc-provider.dart';
import 'package:wake_together/blocs/local-alarms-bloc.dart';
import 'package:wake_together/widgets.dart';

import '../constants.dart';
import '../data/models/alarm.dart';

/// Widget page for Local Alarms
class LocalAlarmsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LocalAlarmsPageState();
}

class LocalAlarmListItem extends StatelessWidget {
  LocalAlarmListItem({
    required this.alarm,
  });

  /// Alarm object associated with this widget
  final Alarm alarm;
  /// BLoC for local alarms.
  final LocalAlarmsBloc _bloc = BlocProvider.localAlarmsBlock;
  /// Radius for rounded cards.
  static const double _cardRadius = 32;
  /// Changes the alarm description accordingly
  TextEditingController textController() {
    return TextEditingController(text: alarm.description);
  }

  @override
  Widget build(BuildContext context) {
    Color _textColor = Theme.of(context).colorScheme.onSurface;

    /// Provides a single day checkbox for a given alarm and day.
    Widget _getDayCheckbox(Alarm alarm, Days day) {
      bool _selected = alarm.days.contains(day);

      return
        InkWell(
            onTap: () {
              alarm.days.contains(day)
                  ? alarm.days.remove(day)
                  : alarm.days.add(day);
              _bloc.updateAlarm(alarm);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  child: Text(alarm.time.format(context),
                      style: Theme.of(context)
                          .textTheme
                          .headline3!
                          .copyWith(color: _textColor)),
                  onTap: () async {
                    TimeOfDay? selectedTimeFuture =
                    await showTimePicker(context: context, initialTime: alarm.time);
                    if (selectedTimeFuture != null) {
                      alarm.time = selectedTimeFuture;
                      _bloc.updateAlarm(alarm);
                    }},
                ),
                Switch(
                  activeColor: Theme.of(context).primaryColor,
                  value: alarm.activated,
                  onChanged: (bool isAlarmActivated) {
                    alarm.activated = isAlarmActivated;
                    _bloc.updateAlarm(alarm);
                    //setState(() {});
                  },
                )
              ],
            ),
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
              child: TextField(
                controller: textController(),
                readOnly: true,
                onTap: () async {
                  String? newDescription = await showInputDialog(
                      context: context,
                      title: "New Note",
                      labelText: "Note",
                      doneAction: "Confirm",
                      cancelAction: "Cancel");

                  if (newDescription != null) {
                    alarm.description = newDescription;
                    _bloc.updateAlarm(
                        alarm); // Update database without refreshing state
                  }
                },
              ),
            ),
            Container(
                margin: EdgeInsets.only(top: 8),
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _bloc.deleteAlarm(alarm);
                  },
                ))
          ]),
    );
  }
}

class _LocalAlarmsPageState extends State<LocalAlarmsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// BLoC for local alarms.
  LocalAlarmsBloc _bloc = BlocProvider.localAlarmsBlock;

  @override
  void dispose() {
    BlocProvider.disposeLocalAlarmsBloc();
    super.dispose();
  }

  /// Radius for rounded cards.
  static const double _cardRadius = 32;

  /// Shows a Time Picker for user to select the time for a new alarm.
  void newAlarm(List<Alarm> alarms) {
    Future<TimeOfDay?> selectedTimeFuture =
        showTimePicker(context: context, initialTime: TimeOfDay.now());
    _bloc.addAlarm(future: selectedTimeFuture);
  }

  @override
  Widget build(BuildContext context) {
    // Call build from super for AutomaticKeepAliveClientMixin
    super.build(context);

    return Scaffold(
        body: StreamBuilder<List<Alarm>>(
            stream: _bloc.alarms,
            initialData: <Alarm>[],
            builder: (context, AsyncSnapshot<List<Alarm>> snapshot) {
              if (snapshot.hasData) {
                List<Alarm> alarms = snapshot.data!;
                _bloc.registerAll(context);

                return ListView.builder(
                  itemCount: alarms.length + 1,
                  itemBuilder: (context, index) => index < alarms.length
                      ? LocalAlarmListItem(alarm: alarms[index])
                      : _getAlarmAdder(alarms),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }));
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
}
