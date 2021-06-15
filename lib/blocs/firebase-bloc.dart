import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wake_together/constants.dart';
import 'package:wake_together/data/models/alarm-channel.dart';

/// Bloc handling all Firebase Authentication processes.
class FirebaseBloc {
  FirebaseBloc() {
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
  Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loginStateSubject.sink.add(LoginState.loggedIn);
      } else {
        _loginStateSubject.sink.add(LoginState.loggedOut);
      }
    });
  }

  /// Returns the user id for the current account.
  String get userId => FirebaseAuth.instance.currentUser!.uid;

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

  /// Name for the field containing the username in /users/userid
  static const String USERNAME_FIELD = "username";

  /// Name for the field containing an alarm channel's owner's user id in
  /// /channels/channelId
  static const String OWNER_ID_FIELD = "ownerId";

  /// Name for the field containing an alarm channel's name
  /// in /channels/channelId and /users/userId/subscribed_channels/.
  static const String CHANNEL_NAME_FIELD = "channelName";

  /// Name for the sub-collection containing a user's subscribed alarm channels
  /// in /user/userId/.
  static const String SUBSCRIBED_CHANNELS_SUB = "subscribed_channels";

  /// Name for the sub-collection containing an alarm channels' subscribers
  /// in /channels/channelId.
  static const String SUBSCRIBERS_SUB = "subscribers";

  /// Name for the top-level collection containing all user documents.
  static const String USERS_COLLECTION = "users";

  /// Name for the top-level collection containing all alarm channels.
  static const String CHANNELS_COLLECTION = "channels";

  /// Absolute path to subscribed_channels Firestore sub-collection
  /// for the current user.
  String get subscribedChannelsPath => "/users/$userId/$SUBSCRIBED_CHANNELS_SUB";

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
        .set({USERNAME_FIELD: await _getUsername(userId)});
  }

  /// Adds a user with targetUsername to an alarm channel.
  Future<bool> addUserToChannel(String targetUsername, AlarmChannel alarmChannel) async {

    targetUsername = targetUsername.trim().toLowerCase();

    String? targetUserId = await _getUserId(targetUsername);

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

  /// Gets the username for a given userId.
  Future<String?> _getUsername(String targetUserId) {
    return FirebaseFirestore.instance
        .doc("/users/$targetUserId")
        .get()
        .then((DocumentSnapshot docSnap) => docSnap.data()?["username"]);
  }

  /// Gets the userId for a given username.
  Future<String?> _getUserId(String targetUsername) {
    return FirebaseFirestore.instance
        .collection(USERS_COLLECTION)
        .where("username", isEqualTo: targetUsername)
        .get()
        .then((QuerySnapshot snapshot) => snapshot.docs)
        .then((List<QueryDocumentSnapshot> snapshots) =>
          snapshots.length == 0 ? null :snapshots[0].id);
  }

  /// Checks whether a username already exists.
  Future<bool> _doesUsernameExist(String username) {
    return FirebaseFirestore.instance
        .collection("/users")
        .where("username", isEqualTo: username)
        .get()
        .then((QuerySnapshot snapshot) => snapshot.size > 0);
  }

  /// Registers a username for the current account
  Future<bool> registerUsername(String username) async {
    if (await _doesUsernameExist(username)) {
      return false;
    } else {
      await FirebaseFirestore.instance
          .doc("/users/$userId")
          .set({USERNAME_FIELD: username});
      return true;
    }
  }
}
