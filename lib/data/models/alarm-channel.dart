import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Stores the information to be displayed in each list item in the Shared
/// Alarms page.
class AlarmChannelOverview {
  AlarmChannelOverview(this.channelName, this.alarmChannel, this.channelId,
      this.currentAlarmTimestamp, this.isActivated) {
    this.currentAlarm = currentAlarmTimestamp == null
        ? null
        : TimeOfDay.fromDateTime(currentAlarmTimestamp!.toDate());
  }

  final String? channelName;
  final Future<Stream<AlarmChannel>> alarmChannel;
  final String channelId;
  final Timestamp? currentAlarmTimestamp;
  late final TimeOfDay? currentAlarm;
  final bool isActivated;
}

/// Stores the detailed information of each alarm channel.
class AlarmChannel {
  AlarmChannel(this.channelId, this.channelName, this.ownerId, this.subscribers,
      this.alarmOptions, this.currentVote);

  final String channelId;
  final String? channelName;
  final String? ownerId;
  final Stream<List<String?>> subscribers;
  final Stream<List<AlarmOption>> alarmOptions;
  final Stream<Timestamp?> currentVote;
}

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