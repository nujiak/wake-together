import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Stores the information to be displayed in each list item in the Shared
/// Alarms page.
class AlarmChannelOverview {
  AlarmChannelOverview(this.channelName, this.alarmChannel, this.channelId);

  final String? channelName;
  final Future<Stream<AlarmChannel>> alarmChannel;
  final String channelId;
}

/// Stores the detailed information of each alarm channel.
class AlarmChannel {
  AlarmChannel(this.channelId, this.channelName, this.ownerId, this.subscribers,
      this.alarmOptions, this.currentVote);

  final String channelId;
  final String? channelName;
  final String? ownerId;
  final Future<Stream<List<String?>>> subscribers;
  final Stream<List<AlarmOption>> alarmOptions;
  final Stream<AlarmOption?> currentVote;
}

class AlarmOption {
  AlarmOption(Timestamp timeStamp) {
    dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp.millisecondsSinceEpoch);
    time = TimeOfDay.fromDateTime(dateTime);
  }

  late final DateTime dateTime;
  late final TimeOfDay time;

  Timestamp get timeStamp =>
      Timestamp.fromMillisecondsSinceEpoch(dateTime.millisecondsSinceEpoch);

  @override
  bool operator ==(Object other) {
    return other is AlarmOption && other.dateTime == this.dateTime;
  }

  @override
  int get hashCode => dateTime.hashCode;
}