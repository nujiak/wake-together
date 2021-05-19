import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wake_together/main.dart';

import '../alarm.dart';

class LocalAlarmsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LocalAlarmsPage();
}

class _LocalAlarmsPage extends State<LocalAlarmsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const double _cardRadius = 32;
  List localAlarms = <Alarm>[];
  final _alarmListKey = GlobalKey<AnimatedListState>();

  void addAlarm(Alarm alarm) {
    _alarmListKey.currentState?.insertItem(localAlarms.length);
    localAlarms.add(alarm);
  }

  void newAlarm() async {
    Future<TimeOfDay?> selectedTimeFuture = showTimePicker(context: context, initialTime: TimeOfDay.now());
    TimeOfDay? selectedTime = await selectedTimeFuture;
    if (selectedTime != null) {
      addAlarm(Alarm(id: 0, time: selectedTime, description: '', days: Set()));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        body: AnimatedList(
          key: _alarmListKey,
          initialItemCount: localAlarms.length + 1,
            itemBuilder: (context, index, animation) =>
                SlideTransition(
                position: animation.drive(Tween<Offset>(begin: const Offset(-1, 0), end: Offset(0, 0))),
                child: index < localAlarms.length
                    ? _getListItem(index)
                    : _getAlarmAdder())));
  }

  Widget _getListItem(int index) {
    Alarm alarm = localAlarms[index];
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      padding: EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 48),
      decoration: BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(-0.8, -0.5),
              radius: 3,
              colors: [
                Colors.blue[500] ?? Colors.blue,
                Colors.blue[900] ?? Colors.blue]),
          borderRadius: BorderRadius.all(Radius.circular(_cardRadius)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
            )
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(alarm.time.format(context),
                style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.white))
          ]),
    );
  }

  Widget _getAlarmAdder() {
    return Container(
        margin: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
        child: InkWell(
            borderRadius: BorderRadius.circular(_cardRadius),
            onTap: newAlarm,
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
