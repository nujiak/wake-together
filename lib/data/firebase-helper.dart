import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Name for the field containing the username in /users/userid
const String USERNAME_FIELD = "username";

/// Name for the field containing an alarm channel's owner's user id in
/// /channels/channelId
const String OWNER_ID_FIELD = "ownerId";

/// Name for the field containing an alarm channel's name
/// in /channels/channelId and /users/userId/subscribed_channels/.
const String CHANNEL_NAME_FIELD = "channelName";

/// Name for the field containing an alarm option's time in
/// /channels/channelId/options/.
const String TIME_FIELD = "time";

/// Name for the field containing an alarm option's vote count in
/// /channels/channelId/options/.
const String VOTES_FIELD = "votes";

/// Name for the sub-collection containing a user's subscribed alarm channels
/// in /user/userId/.
const String SUBSCRIBED_CHANNELS_SUB = "subscribed_channels";

/// Name for the sub-collection containing an alarm channels' subscribers
/// in /channels/channelId.
const String SUBSCRIBERS_SUB = "subscribers";

/// Name for the sub-collection containing an alarm channel's current
/// voting options in /channels/channelId.
const String OPTIONS_SUB = "options";

/// Name for the sub-collection containing an alarm channel's current
/// voting options in /channels/channelId.
const String VOTES_SUB = "votes";

/// Name for the top-level collection containing all user documents.
const String USERS_COLLECTION = "users";

/// Name for the top-level collection containing all alarm channels.
const String CHANNELS_COLLECTION = "channels";

/// Returns the user id for the current account.
String get userId => FirebaseAuth.instance.currentUser!.uid;

/// Absolute path to subscribed_channels Firestore sub-collection
/// for the current user.
String get subscribedChannelsPath => "/users/$userId/$SUBSCRIBED_CHANNELS_SUB";

/// Gets the username for a given userId.
Future<String?> getUsername(String targetUserId) {
  return FirebaseFirestore.instance
      .doc("/users/$targetUserId")
      .get()
      .then((DocumentSnapshot docSnap) => docSnap.data()?["username"]);
}

/// Gets the userId for a given username.
Future<String?> getUserId(String targetUsername) {
  return FirebaseFirestore.instance
      .collection(USERS_COLLECTION)
      .where("username", isEqualTo: targetUsername)
      .get()
      .then((QuerySnapshot snapshot) => snapshot.docs)
      .then((List<QueryDocumentSnapshot> snapshots) =>
          snapshots.length == 0 ? null : snapshots[0].id);
}

/// Checks whether a username already exists.
Future<bool> doesUsernameExist(String username) {
  return FirebaseFirestore.instance
      .collection("/users")
      .where("username", isEqualTo: username)
      .get()
      .then((QuerySnapshot snapshot) => snapshot.size > 0);
}