import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wake_together/constants.dart';
import 'package:wake_together/data/firebase-helper.dart';
import 'package:wake_together/data/models/alarm-channel.dart';

/// Bloc handling all Firebase Authentication processes.
class SharedAlarmsBloc {
  SharedAlarmsBloc() {
    init();
  }

  /// Behaviour Subject for the app's login state.
  BehaviorSubject<LoginState> _loginStateSubject = BehaviorSubject();

  /// ValueStream for AuthenticationPage to listen to.
  ValueStream<LoginState> get loginState => _loginStateSubject.stream;

  /// Disposes sinks.
  void dispose() {
    _loginStateSubject.close();
  }

  /// Initializes FlutterFire.
  void init() async {
    await Firebase.initializeApp();

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loginStateSubject.sink.add(LoginState.loggedIn);
      } else {
        _loginStateSubject.sink.add(LoginState.loggedOut);
      }
    });
  }

  /// Brings the user to the registration page.
  void startRegistrationFlow() {
    _loginStateSubject.sink.add(LoginState.register);
  }

  /// Attempts to sign in with an email and password.
  void signInWithEmailAndPassword(
    String email,
    String password,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  /// Returns the user to the sign in page.
  void cancelRegistration() {
    _loginStateSubject.sink.add(LoginState.loggedOut);
  }

  /// Attempts to register a user with an email, password, and display name.
  void registerAccount(String email, String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  /// Signs a user out and return to sign in page.
  void signOut() {
    FirebaseAuth.instance.signOut();
    FirebaseFirestore.instance.clearPersistence();
    _subscribedChannels = null;
    _username = null;
  }

  /// Stream for channels to listen for realtime changes.
  Stream<List<AlarmChannelOverview>>? _subscribedChannels;

  /// Getter for _subscribedChannels with lazy evaluation.
  Stream<List<AlarmChannelOverview>> get subscribedChannels {
    if (_subscribedChannels == null) {
      _subscribedChannels = FirebaseFirestore.instance
          .collection(subscribedChannelsPath)
          .snapshots()
          .map((QuerySnapshot snapshot) =>
          snapshot.docs.map(_alarmChannelOverviewFrom).toList());
    }
    return _subscribedChannels!;
  }

  /// Maps a QueryDocumentSnapshot from /user/.../subscribed_channels/ to
  /// an AlarmChannelOverview.
  AlarmChannelOverview _alarmChannelOverviewFrom(
      QueryDocumentSnapshot docSnap) {
    return AlarmChannelOverview(docSnap.data()[CHANNEL_NAME_FIELD],
        _getAlarmChannel(docSnap.id));
  }

  /// Returns a Future that provides the AlarmChannel representing the alarm
  /// channel with channelId in /channels/.
  Future<Stream<AlarmChannel>> _getAlarmChannel(String channelId) async {
    return FirebaseFirestore.instance
        .doc("/$CHANNELS_COLLECTION/$channelId")
        .snapshots()
        .map((DocumentSnapshot docSnap) => AlarmChannel(
        channelId,
        docSnap.data()?[CHANNEL_NAME_FIELD],
        docSnap.data()?[OWNER_ID_FIELD],
        _getAlarmChannelSubscribers(channelId)));
  }

  Future<Stream<List<String?>>> _getAlarmChannelSubscribers(
      String channelId) async {
    return FirebaseFirestore.instance
        .collection("/$CHANNELS_COLLECTION/$channelId/$SUBSCRIBERS_SUB")
        .snapshots()
        .map((QuerySnapshot snapshot) => snapshot.docs)
        .map((List<QueryDocumentSnapshot> docSnapshots) {
      return docSnapshots.map((QueryDocumentSnapshot docSnapshot) =>
      docSnapshot.data()[USERNAME_FIELD] as String?).toList();
    });
  }

  /// Creates a new alarm channel with a name.
  void createNewAlarmChannel(String channelName) async {
    CollectionReference channelsCollection =
        FirebaseFirestore.instance.collection("/$CHANNELS_COLLECTION");

    // Add the new channel to the channels collection
    DocumentReference channelDocument = await channelsCollection.add({
      OWNER_ID_FIELD: userId,
      CHANNEL_NAME_FIELD: channelName,
    });

    // Add the new channel to the subscribed channels sub-collection,
    // including the channel's documentId and name.
    await FirebaseFirestore.instance.doc("$subscribedChannelsPath/${channelDocument.id}").set({
      CHANNEL_NAME_FIELD: channelName,
    });

    // Insert current user (owner) as a subscriber of the channel.
    await channelDocument
        .collection("/$SUBSCRIBERS_SUB")
        .doc(userId)
        .set({USERNAME_FIELD: await getUsername(userId)});
  }

  /// Stream for the current account's username.
  Stream<String?>? _username;

  /// Getter for _username with lazy evaluation.
  Stream<String?> get username {
    if (_username == null) {
      _username = FirebaseFirestore.instance
          .doc("users/$userId")
          .snapshots()
          .map((docSnap) => docSnap.get(USERNAME_FIELD));
    }
    return _username!;
  }

  /// Registers a username for the current account
  Future<bool> registerUsername(String username) async {
    if (await doesUsernameExist(username)) {
      return false;
    } else {
      await FirebaseFirestore.instance
          .doc("/users/$userId")
          .set({USERNAME_FIELD: username});
      return true;
    }
  }
}
