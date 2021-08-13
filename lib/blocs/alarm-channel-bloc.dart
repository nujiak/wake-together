
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

  /// Registers the user's vote.
  void vote(Timestamp timestamp) async {
    await FirebaseFirestore.instance
        .doc("/$CHANNELS_COLLECTION/$channelId/$VOTES_SUB/$userId")
        .set({TIME_FIELD: timestamp});
  }

  /// Opts the user out of the current vote.
  void optOut() async {
    await FirebaseFirestore.instance
        .doc(("/$CHANNELS_COLLECTION/${alarmChannel.channelId}/$VOTES_SUB/$userId"))
        .delete();
  }
}