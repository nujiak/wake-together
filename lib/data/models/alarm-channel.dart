/// Stores the information to be displayed in each list item in the Shared
/// Alarms page.
class AlarmChannelOverview {
  AlarmChannelOverview(this.channelName, this.alarmChannel);

  final String? channelName;
  final Future<Stream<AlarmChannel>> alarmChannel;
}

/// Stores the detailed information of each alarm channel.
class AlarmChannel {
  AlarmChannel(this.channelName, this.ownerId);

  final String? channelName;
  final String? ownerId;
}