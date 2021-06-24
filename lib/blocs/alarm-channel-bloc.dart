import "dart:collection";

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wake_together/data/alarm-helper.dart';
import 'package:wake_together/data/firebase-helper.dart';
import 'package:wake_together/data/models/alarm-channel.dart';

class AlarmChannelBloc {

  AlarmChannelBloc(this.alarmChannel) {
    init();
    channelId = this.alarmChannel.channelId;
  }

  /// AlarmChannel tied to this bloc.
  final AlarmChannel alarmChannel;

  /// Channel ID of the alarm tied to this bloc.
  late final String channelId;

  void init() async {
    // Should have been initialized by SharedAlarmsBloc.
    await Firebase.initializeApp();

    _channelInfo = FirebaseFirestore.instance
        .doc("/$CHANNELS_COLLECTION/$channelId/")
        .snapshots()
        .map((DocumentSnapshot snapshot) => snapshot.data());

    _channelInfo.listen((Map<String, dynamic>? data) {
      if (data == null) {
        return;
      }
      if (data[CHANNEL_NAME_FIELD] != null) {
        _channelName.add(data[CHANNEL_NAME_FIELD]);
      }
      if (data[OWNER_ID_FIELD] != null) {
        _ownerId.add(data[OWNER_ID_FIELD]);
      }
    });
  }

  void dispose() {
    _ownerId.close();
    _channelName.close();
  }

  /// Stream of subscribers for this alarm channel.
  Stream<List<String?>>? _subscribers;

  /// Lazy getter for the stream of subscribers.
  Stream<List<String?>> get subscribers {
    if (_subscribers == null) {
      _subscribers = FirebaseFirestore.instance
          .collection("/$CHANNELS_COLLECTION/$channelId/$SUBSCRIBERS_SUB")
          .snapshots()
          .map((QuerySnapshot snapshot) => snapshot.docs)
          .map((List<QueryDocumentSnapshot> docSnapshots) {
        return docSnapshots.map((QueryDocumentSnapshot docSnapshot) =>
        docSnapshot.data()[USERNAME_FIELD] as String?).toList();
      });
    }
    return _subscribers!;
  }

  /// Stream of the current user's vote for this alarm channel.
  Stream<Timestamp?>? _currentUserVote;

  /// Lazy getter for the stream of user's current vote.
  Stream<Timestamp?> get currentUserVote {
    if (_currentUserVote == null) {
      _currentUserVote = FirebaseFirestore.instance
          .doc("/$CHANNELS_COLLECTION/$channelId/$VOTES_SUB/$userId")
          .snapshots()
          .map((DocumentSnapshot docSnap) => docSnap.data()?[TIME_FIELD]);
    }
    return _currentUserVote!;
  }

  /// Stream of the alarm options in this alarm channel.
  Stream<List<AlarmOption>>? _alarmOptions;

  /// Lazy getter for the stream of alarm options.
  Stream<List<AlarmOption>> get alarmOptions {
    if (_alarmOptions == null) {
      _alarmOptions = FirebaseFirestore.instance
          .collection("/$CHANNELS_COLLECTION/$channelId/$OPTIONS_SUB")
          .orderBy(TIME_FIELD)
          .snapshots()
          .map((QuerySnapshot snapshot) => snapshot.docs)
          .map((List<QueryDocumentSnapshot> docs) {
        return docs.map((QueryDocumentSnapshot docSnap) =>
            AlarmOption(docSnap.data()[TIME_FIELD], docSnap.data()[VOTES_FIELD] ?? 0));
      })
          .map((Iterable<AlarmOption> alarmOptions) => alarmOptions.toList());
    }
    return _alarmOptions!;
  }

  late Stream<Map<String, dynamic>?> _channelInfo;

  BehaviorSubject<String> _channelName = BehaviorSubject();
  Stream<String> get channelName => _channelName.stream;

  BehaviorSubject<String> _ownerId = BehaviorSubject();
  Stream<String> get ownerId => _ownerId.stream;


  /// Adds a user with targetUsername to an alarm channel.
  Future<bool> addUserToChannel(String targetUsername) async {

    targetUsername = targetUsername.trim().toLowerCase();

    String? targetUserId = await getUserId(targetUsername);

    if (targetUserId == null) {
      return false;
    }

    // Add user to channel's subscribers
    await FirebaseFirestore.instance
        .doc("/channels/$channelId/$SUBSCRIBERS_SUB/$targetUserId")
        .set({USERNAME_FIELD: targetUsername});

    // Add channel to user's subscribed_channels
    await FirebaseFirestore.instance
        .doc("/$USERS_COLLECTION/$targetUserId/$SUBSCRIBED_CHANNELS_SUB/$channelId")
        .set({
      CHANNEL_ID_FIELD: channelId,
      CHANNEL_NAME_FIELD: await _channelName.last,
      CURRENT_ALARM_FIELD: alarmChannel.currentAlarm,
    });

    return true;
  }

  /// Adds a voting option to the alarm.
  Future<bool> addNewVoteOption(Future<TimeOfDay?> timeFuture) async {

    final TimeOfDay? time = await timeFuture;
    if (time == null) {
      return false;
    }

    // Convert to the nearest DateTime
    DateTime dateTime = findNextAlarmDateTime(time);
    Timestamp timeStamp = Timestamp.fromDate(dateTime);

    CollectionReference optionsSubCollection = FirebaseFirestore.instance
        .collection("/$CHANNELS_COLLECTION/$channelId/$OPTIONS_SUB");

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

  /// Recounts all the votes in the alarm alarm channel.
  ///
  /// To be moved into a Cloud Function.
  void recountVotes() async {
    // Fetch all votes from firestore.
    List<QueryDocumentSnapshot> voteSnapshots = await FirebaseFirestore.instance
        .collection("/$CHANNELS_COLLECTION/$channelId/$VOTES_SUB")
        .get()
        .then((QuerySnapshot querySnapshot) => querySnapshot.docs);

    // Stores the vote counts of an option.
    HashMap<Timestamp, int> voteCounts = HashMap();

    // Count all votes.
    for (QueryDocumentSnapshot voteSnapshot in voteSnapshots) {
      Timestamp timestamp = voteSnapshot.data()[TIME_FIELD];
      voteCounts[timestamp] = (voteCounts[timestamp] ?? 0) + 1;
    }

    // Fetch all options from firestore.
    List<QueryDocumentSnapshot> optionsSnapshots = await FirebaseFirestore.instance
    .collection("/$CHANNELS_COLLECTION/$channelId/$OPTIONS_SUB")
    .get()
    .then((QuerySnapshot querySnapshot) => querySnapshot.docs);

    // Add vote counts to each option in firestore.
    for (QueryDocumentSnapshot optionSnapshot in optionsSnapshots) {
      Timestamp? timestamp = optionSnapshot.data()[TIME_FIELD];
      optionSnapshot.reference.set(
          {VOTES_FIELD: voteCounts[timestamp] ?? 0}, SetOptions(merge: true));
    }

    // Calculate highest voted timestamp
    Timestamp? highestVoted;
    int highestCount = 0;

    // Find most votes
    for (Timestamp timestamp in voteCounts.keys) {
      if (voteCounts[timestamp]! > highestCount) {
        highestVoted = timestamp;
        highestCount = voteCounts[timestamp]!;
      }
    }

    // Save highest voted option in /users/userId/subscribed_channels/channelId/
    List<DocumentReference> channelsInSubscribedChannels =
        await FirebaseFirestore.instance
            .collectionGroup(SUBSCRIBED_CHANNELS_SUB)
            .where(CHANNEL_ID_FIELD, isEqualTo: channelId)
            .get()
            .then((QuerySnapshot snapshot) => snapshot.docs)
            .then((List<QueryDocumentSnapshot> docSnaps) => docSnaps
                .map((QueryDocumentSnapshot docSnap) => docSnap.reference)
                .toList());

    // Update the highest voted option in the alarm channel
    await FirebaseFirestore.instance
        .doc("/$CHANNELS_COLLECTION/$channelId")
        .set({CURRENT_ALARM_FIELD: highestVoted}, SetOptions(merge: true));

    // Update the highest voted option in each alarm channel under each
    // subscriber's subscribed_channels
    for (DocumentReference userAlarmChannel in channelsInSubscribedChannels) {
      await userAlarmChannel.set({CURRENT_ALARM_FIELD: highestVoted}, SetOptions(merge: true));
    }
  }

  /// Registers the user's vote.
  void vote(Timestamp timestamp) async {
    await FirebaseFirestore.instance
        .doc("/$CHANNELS_COLLECTION/$channelId/$VOTES_SUB/$userId")
        .set({TIME_FIELD: timestamp});

    // Register vote under the user
    await FirebaseFirestore.instance.doc("/$USERS_COLLECTION/$userId/$SUBSCRIBED_CHANNELS_SUB/$channelId")
    .set({HAS_VOTED_FIELD: true}, SetOptions(merge: true));

    // Recount all votes
    recountVotes();
  }

  /// Opts the user out of the current vote.
  void optOut() async {
    await FirebaseFirestore.instance
        .doc(("/$CHANNELS_COLLECTION/${alarmChannel.channelId}/$VOTES_SUB/$userId"))
        .delete();

    // Register opt out under the user
    await FirebaseFirestore.instance.doc("/$USERS_COLLECTION/$userId/$SUBSCRIBED_CHANNELS_SUB/$channelId")
        .set({HAS_VOTED_FIELD: false}, SetOptions(merge: true));

    // Recount all votes
    recountVotes();
  }
}