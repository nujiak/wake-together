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

  /// Name of the alarm channel.
  final String? channelName;

  /// Future containing a Stream of the full AlarmChannel
  final Future<Stream<AlarmChannel>> alarmChannel;

  /// Unique id for the alarm channel.
  final String channelId;

  /// Timestamp for the current highest voted alarm time.
  final Timestamp? currentAlarmTimestamp;

  /// TimeOfDay for the current highest voted alarm time.
  late final TimeOfDay? currentAlarm;

  /// Whether the user has voted and the alarm is activated for the user.
  final bool isActivated;
}

/// Stores the detailed information of each alarm channel.
class AlarmChannel {
  AlarmChannel(this.channelId, this.channelName, this.ownerId,
      this.alarmOptions);

  /// Name of the alarm channel.
  final String? channelName;

  /// Unique id for the alarm channel.
  final String channelId;

  /// User id for the owner (creator) of this alarm channel.
  final String? ownerId;

  /// List of alarm options for voting.
  final Stream<List<AlarmOption>> alarmOptions;
}

/// A single voting option in AlarmChannel.
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