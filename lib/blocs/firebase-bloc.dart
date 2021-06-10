import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // new
import 'package:rxdart/rxdart.dart';
import 'package:wake_together/constants.dart';

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

  /// Stream for channels to listen for realtime changes.
  Stream<QuerySnapshot>? _subscribedChannels;

  /// Getter for _subscribedChannels with lazy evaluation.
  Stream<QuerySnapshot> get subscribedChannels {
    if (_subscribedChannels == null) {
      _subscribedChannels = FirebaseFirestore.instance
          .collection("/users/$userId/subscribed_channels")
          .snapshots();
    }
    return _subscribedChannels!;
  }

  /// Stream for the current account's username.
  Stream<String?>? _username;

  /// Getter for _username with lazy evaluation.
  Stream<String?> get username {
    if (_username == null) {
      _username = FirebaseFirestore.instance
          .doc("users/$userId")
          .snapshots()
      .map((docSnap) => docSnap.get("username"));
    }
    return _username!;
  }

  /// Creates a new alarm channel with a name.
  void createNewAlarmChannel(String channelName) async {
    CollectionReference channelsCollection =
        FirebaseFirestore.instance.collection("/channels");

    // Add the new channel to the channels collection
    Future<DocumentReference> addToChannels = channelsCollection.add({
      "ownerId": userId,
      "channelName": channelName,
    });

    // Add the new channel to the subscribed channels sub-collection,
    // including the channel's documentId and name.
    Future<DocumentReference> addReferenceToUsers =
        addToChannels.then((docRef) {
      return FirebaseFirestore.instance
          .collection("/users/$userId/subscribed_channels")
          .add({
        "channelId": docRef.id,
        "channelName": channelName,
      });
    });
    await addReferenceToUsers;
  }

  /// Checks whether a username already exists
  Future<bool> doesUsernameExist(String username) {
    return FirebaseFirestore.instance
        .collection("/users")
        .where("username", isEqualTo: username)
        .get()
        .then((QuerySnapshot snapshot) => snapshot.size > 0);
  }

  /// Registers a username for the current account
  Future<bool> registerUsername(String username) async {
    if (await doesUsernameExist(username)) {
      print("Username $username alr exists");
      return false;
    } else {
      await FirebaseFirestore.instance
          .doc("/users/$userId")
          .set({"username": username});
      return true;
    }
  }
}
