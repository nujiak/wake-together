import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wake_together/data/alarm-helper.dart';
import 'package:wake_together/data/firebase-helper.dart';
import 'package:wake_together/data/models/alarm-channel.dart';

class AlarmChannelBloc {

  AlarmChannelBloc(this.alarmChannelOverview) {
    init();
  }

  final AlarmChannelOverview alarmChannelOverview;

  void init() async {
    // Should have been initialized by SharedAlarmsBloc.
    await Firebase.initializeApp();
  }

  /// Adds a user with targetUsername to an alarm channel.
  Future<bool> addUserToChannel(String targetUsername, AlarmChannel alarmChannel) async {

    targetUsername = targetUsername.trim().toLowerCase();

    String? targetUserId = await getUserId(targetUsername);

    if (targetUserId == null) {
      return false;
    }

    // Add user to channel's subscribers
    await FirebaseFirestore.instance
        .doc("/channels/${alarmChannel.channelId}/$SUBSCRIBERS_SUB/$targetUserId")
        .set({USERNAME_FIELD: targetUsername});

    // Add channel to user's subscribed_channels
    await FirebaseFirestore.instance
        .doc("/$USERS_COLLECTION/$targetUserId/$SUBSCRIBED_CHANNELS_SUB/${alarmChannel.channelId}")
        .set({
      CHANNEL_NAME_FIELD: alarmChannel.channelName,
    });

    return true;
  }

  /// Adds a voting option to the alarm.
  Future<bool> addNewVoteOption(Future<TimeOfDay?> timeFuture, AlarmChannel alarmChannel) async {

    final TimeOfDay? time = await timeFuture;
    if (time == null) {
      return false;
    }

    // Convert to the nearest DateTime
    DateTime dateTime = findNextAlarmDateTime(time);
    Timestamp timeStamp = Timestamp.fromDate(dateTime);

    CollectionReference optionsSubCollection = FirebaseFirestore.instance
        .collection("/$CHANNELS_COLLECTION/${alarmChannel.channelId}/$OPTIONS_SUB");

    // Check if the vote option already exists
    bool alreadyExists = await optionsSubCollection
        .where("time", isEqualTo: timeStamp)
        .get()
        .then((QuerySnapshot snapshot) => snapshot.docs.length > 0);

    if (alreadyExists) {
      return false;
    }

    // Add the option
    await optionsSubCollection.add({"time": timeStamp});
    return true;
  }

  void vote(AlarmOption option) async {
    await FirebaseFirestore.instance
        .doc("/$CHANNELS_COLLECTION/${alarmChannelOverview.channelId}/$VOTES_SUB/$userId")
        .set({TIME_FIELD: option.timeStamp});
  }
}