/// Stores the information to be displayed in each list item in the Shared
/// Alarms page.
class AlarmChannelOverview {
  AlarmChannelOverview(this.channelName, this.alarmChannel);

  final String? channelName;
  final Future<Stream<AlarmChannel>> alarmChannel;
}

/// Stores the detailed information of each alarm channel.
class AlarmChannel {
  AlarmChannel(this.channelId, this.channelName, this.ownerId, this.subscribers);

  final String channelId;
  final String? channelName;
  final String? ownerId;
  final Future<Stream<List<String?>>> subscribers;
}