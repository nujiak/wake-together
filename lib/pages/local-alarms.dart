import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/local-alarms-bloc.dart';
import 'package:wake_together/widgets.dart';

import '../constants.dart';
import '../data/models/alarm.dart';

/// Radius for rounded cards.
const double _cardRadius = 32;

/// Widget page for Local Alarms
class LocalAlarmsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LocalAlarmsPageState();
}

class _LocalAlarmsPageState extends State<LocalAlarmsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Call build from super for AutomaticKeepAliveClientMixin
    super.build(context);

    return Provider<LocalAlarmsBloc>(
      create: (context) => LocalAlarmsBloc(),
      dispose: (BuildContext context, LocalAlarmsBloc bloc) => bloc.dispose(),
      child: Scaffold(body: Consumer<LocalAlarmsBloc>(
        builder: (BuildContext context, LocalAlarmsBloc bloc, _) {
          return StreamBuilder<List<Alarm>>(
              stream: bloc.alarms,
              initialData: <Alarm>[],
              builder: (context, AsyncSnapshot<List<Alarm>> snapshot) {
                if (snapshot.hasData) {
                  List<Alarm> alarms = snapshot.data!;
                  bloc.registerAll(context);

                  return ListView.builder(
                    itemCount: alarms.length + 1,
                    itemBuilder: (context, index) => index < alarms.length
                        ? _LocalAlarmListItem(alarm: alarms[index])
                        : _AlarmAdder(),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              });
        },
      )),
    );
  }
}

/// List item widget for a single alarm.
class _LocalAlarmListItem extends StatelessWidget {
  _LocalAlarmListItem({required this.alarm});

  /// Alarm object associated with this widget
  final Alarm alarm;

  /// Radius for rounded cards.
  static const double _cardRadius = 32;

  /// Changes the alarm description accordingly
  TextEditingController textController() {
    return TextEditingController(text: alarm.description);
  }

  @override
  Widget build(BuildContext context) {
    Color _textColor = Theme.of(context).colorScheme.onSurface;

    return Consumer<LocalAlarmsBloc>(
        builder: (BuildContext context, LocalAlarmsBloc bloc, _) {
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
                      TimeOfDay? selectedTimeFuture = await showTimePicker(
                          context: context, initialTime: alarm.time);
                      if (selectedTimeFuture != null) {
                        alarm.time = selectedTimeFuture;
                        bloc.updateAlarm(alarm);
                      }
                    },
                  ),
                  Switch(
                    activeColor: Theme.of(context).primaryColor,
                    value: alarm.activated,
                    onChanged: (bool isAlarmActivated) {
                      alarm.activated = isAlarmActivated;
                      bloc.updateAlarm(alarm);
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
                        .map((day) => _DayCheckBox(alarm: alarm, day: day))
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
                      bloc.updateAlarm(
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
                      bloc.deleteAlarm(alarm);
                    },
                  ))
            ]),
      );
    });
  }
}

/// Single day checkbox for a given alarm and day.
class _DayCheckBox extends StatelessWidget {
  _DayCheckBox({required this.alarm, required this.day});

  /// Alarm which this checkbox modifies.
  final Alarm alarm;

  /// Day which this checkbox modifies.
  final Days day;

  @override
  Widget build(BuildContext context) {
    final bool _selected = alarm.days.contains(day);

    return Consumer<LocalAlarmsBloc>(
        builder: (BuildContext context, LocalAlarmsBloc bloc, _) {
      return InkWell(
          onTap: () {
            alarm.days.contains(day)
                ? alarm.days.remove(day)
                : alarm.days.add(day);
            bloc.updateAlarm(alarm);
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
    });
  }
}

/// Dashed alarm adder, placed at the end of the list, after the last alarm.
class _AlarmAdder extends StatelessWidget {
  const _AlarmAdder({Key? key}) : super(key: key);

  /// Shows a Time Picker for user to select the time for a new alarm.
  void newAlarm(BuildContext context, LocalAlarmsBloc bloc) {
    Future<TimeOfDay?> selectedTimeFuture =
    showTimePicker(context: context, initialTime: TimeOfDay.now());
    bloc.addAlarm(future: selectedTimeFuture);
  }

  @override
  Widget build(BuildContext context) {
    Color _color = Theme.of(context).colorScheme.onSurface.withAlpha(127);
    return Consumer<LocalAlarmsBloc>(
      builder: (BuildContext context, LocalAlarmsBloc bloc, _) => Container(
          margin: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
          child: InkWell(
              borderRadius: BorderRadius.circular(_cardRadius),
              onTap: () => newAlarm(context, bloc),
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
                      ..arcToPoint(
                          Offset(size.width - _cardRadius, size.height),
                          radius: Radius.circular(_cardRadius))
                      ..lineTo(_cardRadius, size.height)
                      ..arcToPoint(Offset(0, size.height - _cardRadius),
                          radius: Radius.circular(_cardRadius))
                      ..lineTo(0, _cardRadius)
                      ..arcToPoint(Offset(_cardRadius, 0),
                          radius: Radius.circular(_cardRadius));
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                        left: 24, right: 24, top: 36, bottom: 36),
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
                  )))),
    );
  }
}