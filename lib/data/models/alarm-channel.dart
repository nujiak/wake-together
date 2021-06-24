import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Stores the information to be displayed in each list item in the Shared
/// Alarms page.
class AlarmChannelOverview {
  AlarmChannelOverview({
    required this.channelName,
    required this.channelId,
    required this.currentAlarmTimestamp,
    this.isActivated = false}) {
    this.currentAlarm = currentAlarmTimestamp == null
        ? null
        : TimeOfDay.fromDateTime(currentAlarmTimestamp!.toDate());
  }

  /// Name of the alarm channel.
  final String? channelName;

  /// Unique id for the alarm channel.
  final String channelId;

  /// Timestamp for the current highest voted alarm time.
  final Timestamp? currentAlarmTimestamp;

  /// TimeOfDay for the current highest voted alarm time.
  late final TimeOfDay? currentAlarm;

  /// Whether the user has voted and the alarm is activated for the user.
  final bool isActivated;
}

/// A single voting option in an alarm channel.
class AlarmOption {
  AlarmOption(this.timestamp, this.votes) {
    dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    time = TimeOfDay.fromDateTime(dateTime);
  }

  /// Timestamp of the options.
  ///
  /// For firestore operations.
  late final Timestamp timestamp;

  /// DateTime representation of timestamp.
  ///
  /// For displaying date.
  late final DateTime dateTime;

  /// timeOfDay representation of timestamp.
  ///
  /// For formatting and displaying time.
  late final TimeOfDay time;

  /// The vote count of this option.
  final int votes;

  @override
  bool operator ==(Object other) {
    return other is AlarmOption && other.dateTime == this.dateTime;
  }

  @override
  int get hashCode => dateTime.hashCode;
}