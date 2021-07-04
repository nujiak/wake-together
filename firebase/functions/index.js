// The Cloud Functions for Firebase SDK to
// create Cloud Functions and setup triggers.
const functions = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
admin.initializeApp();
admin.firestore().settings({ignoreUndefinedProperties: true});

// Name for the field containing the username in /users/userid
// const USERNAME_FIELD = "username";

// Name for the field containing an alarm channel's id in
// /channels/channelId
const CHANNEL_ID_FIELD = "channelId";

// Name for the field containing an alarm channel's owner's user id in
// /channels/channelId
// const OWNER_ID_FIELD = "ownerId";

// Name for the field containing an alarm channel's name
// in /channels/channelId and /users/userId/subscribed_channels/.
const CHANNEL_NAME_FIELD = "channelName";

// Name for the field containing an alarm channel's current highest voted
// alarm option in /users/userId/subscribed_channels/.
const CURRENT_ALARM_FIELD = "currentAlarm";

// Name for the field containing an alarm option's time in
// /channels/channelId/options/.
// const TIME_FIELD = "time";

// Name for the field containing an alarm option's vote count in
// /channels/channelId/options/.
// const VOTES_FIELD = "votes";

// Name for the field containing a boolean representing whether a user has
// voted in an alarm channel in /users/userId/subscribed_channels/channelId/.
const HAS_VOTED_FIELD = "hasVoted";

// Name for the sub-collection containing a user's subscribed alarm channels
// in /user/userId/.
const SUBSCRIBED_CHANNELS_SUB = "subscribed_channels";

// Name for the sub-collection containing an alarm channels' subscribers
// in /channels/channelId.
const SUBSCRIBERS_SUB = "subscribers";

// Name for the sub-collection containing an alarm channel's current
// voting options in /channels/channelId.
// const OPTIONS_SUB = "options";

// Name for the sub-collection containing an alarm channel's current
// voting options in /channels/channelId.
// const VOTES_SUB = "votes";

// Name for the top-level collection containing all user documents.
const USERS_COLLECTION = "users";

// Name for the top-level collection containing all alarm channels.
const CHANNELS_COLLECTION = "channels";

// Adds the alarm channel details to the user when the user is added.
exports.onAddUserToChannel = functions.firestore
    .document(`/${CHANNELS_COLLECTION}/{channelId}/${SUBSCRIBERS_SUB}/{userId}`)
    .onCreate((_snapshot, context) => {
      const channelId = context.params.channelId;
      const userId = context.params.userId;

      return admin.firestore().doc(`/${CHANNELS_COLLECTION}/${channelId}`).get()
          .then((snapshot) => admin.firestore()
              .collection(USERS_COLLECTION)
              .doc(userId)
              .collection(SUBSCRIBED_CHANNELS_SUB)
              .doc(channelId)
              .set({
                [CHANNEL_ID_FIELD]: channelId,
                [CHANNEL_NAME_FIELD]: snapshot.get(CHANNEL_NAME_FIELD),
                [CURRENT_ALARM_FIELD]: snapshot.get(CURRENT_ALARM_FIELD),
                [HAS_VOTED_FIELD]: false,
              }, {merge: true}));
    });
