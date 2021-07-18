/* eslint-disable linebreak-style */
// The Cloud Functions for Firebase SDK to
// create Cloud Functions and setup triggers.
const functions = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
const {firestore} = require("firebase-admin");
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
const TIME_FIELD = "time";

// Name for the field containing an alarm option's vote count in
// /channels/channelId/options/.
const VOTES_FIELD = "votes";

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
const OPTIONS_SUB = "options";

// Name for the sub-collection containing an alarm channel's current
// voting options in /channels/channelId.
const VOTES_SUB = "votes";

// Name for the top-level collection containing all user documents.
const USERS_COLLECTION = "users";

// Name for the top-level collection containing all alarm channels.
const CHANNELS_COLLECTION = "channels";

// Adds the alarm channel details to the user when the user is added.
exports.onAddUserToChannel = functions.region("asia-southeast2").firestore
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

exports.recountVotes = functions.region("asia-southeast2").firestore
    .document(`/${CHANNELS_COLLECTION}/{channelId}/${VOTES_SUB}/{userId}`)
    .onWrite((change, context) => {
      const channelId = context.params.channelId;
      const userId = context.params.userId;

      // Check if user voted or opted out.
      const hasVoted = change.after.get(TIME_FIELD) != undefined;

      // Update user's opt-in status.
      const updateUserHasVoted = admin.firestore()
          .collection(USERS_COLLECTION)
          .doc(userId)
          .collection(SUBSCRIBED_CHANNELS_SUB)
          .doc(channelId)
          .set({[HAS_VOTED_FIELD]: hasVoted}, {merge: true});

      // Fetch all user votes for this alarm channel.
      const allVotes = updateUserHasVoted.then((_) => {
        return admin.firestore()
            .collection(`${CHANNELS_COLLECTION}/${channelId}/${VOTES_SUB}`)
            .get()
            .then((snapshot) => snapshot.docs);
      });

      // Tally all votes.
      const votesMap = allVotes.then((docSnapshots) => {
        // Stores the number of votes for each option.
        const voteCounts = new Map();

        for (let i = 0; i < docSnapshots.length; ++i) {
          const docSnap = docSnapshots[i];
          if (docSnap != undefined) {
            const timestamp = docSnap.get(TIME_FIELD);
            voteCounts.set(
                timestamp.toMillis(),
                voteCounts.has(timestamp.toMillis()) ?
                voteCounts.get(timestamp.toMillis()) + 1 : 1);
          }
        }

        return voteCounts;
      });

      // Get all vote options.
      const voteOptions = admin.firestore()
          .collection(`/${CHANNELS_COLLECTION}/${channelId}/${OPTIONS_SUB}`)
          .get()
          .then((querySnapshot) => querySnapshot.docs);

      // Update each option with its vote count.
      const updateOptions = Promise.all([votesMap, voteOptions])
          .then((values) => {
            const map = values[0];
            const options = values[1];

            options.forEach((optionSnapshot) => {
              if (optionSnapshot != undefined) {
                const timestamp = optionSnapshot.get(TIME_FIELD);
                optionSnapshot.ref.set(
                    {[VOTES_FIELD]:
                        map.has(timestamp.toMillis()) ?
                        map.get(timestamp.toMillis()) : 0},
                    {merge: true}
                );
              }
            });
          });

      // Find the highest voted timestamp.
      const highestVote = votesMap.then((map) => {
        let highestTimestamp;
        let highestCount;

        for (const [timestampMillis, count] of map.entries()) {
          if (highestTimestamp == undefined || count > highestCount) {
            highestTimestamp = firestore.Timestamp.fromMillis(timestampMillis);
            highestCount = count;
          }
        }

        return highestTimestamp;
      });

      // Get all channels under the users collection.
      const userChannels = admin.firestore()
          .collectionGroup(SUBSCRIBED_CHANNELS_SUB)
          .where(CHANNEL_ID_FIELD, "==", channelId)
          .get()
          .then((snapshot) => snapshot.docs)
          .then((docSnaps) => docSnaps.map((docSnap) => docSnap.ref));

      // Update info of all channels under the users collection.
      const updateUserChannels = Promise.all([highestVote, userChannels])
          .then((values) => {
            const highestVote = values[0];
            const userChannels = values[1];

            // Update all channels under users.
            for (let i = 0; i < userChannels.length; ++i) {
              const channel = userChannels[i];
              if (channel != undefined) {
                channel.set(
                    {[CURRENT_ALARM_FIELD]: highestVote},
                    {merge: true}
                );
              }
            }

            // Update alarm channel.
            admin.firestore()
                .doc(`${CHANNELS_COLLECTION}/${channelId}`)
                .set({[CURRENT_ALARM_FIELD]: highestVote}, {merge: true});
          });

      return Promise.all([updateUserChannels, updateOptions]);
    });
