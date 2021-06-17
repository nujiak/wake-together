import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/alarm-channel-bloc.dart';
import 'package:wake_together/data/models/alarm-channel.dart';

import '../../widgets.dart';

/// Displays the details of an AlarmChannel given its AlarmChannelOverview.
class AlarmChannelPage extends StatelessWidget {
  const AlarmChannelPage(this._alarmChannelOverview);

  final AlarmChannelOverview _alarmChannelOverview;

  @override
  Widget build(BuildContext context) {
    return Provider<AlarmChannelBloc>(
      create: (BuildContext context) => AlarmChannelBloc(_alarmChannelOverview),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_alarmChannelOverview.channelName ?? "<null>"),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .background,
        ),
        body: FutureBuilder(
            future: _alarmChannelOverview.alarmChannel,
            builder: (BuildContext context,
                AsyncSnapshot<Stream<AlarmChannel>> streamSnapshot) {
              return !streamSnapshot.hasData
                  ? const Center(child: const CircularProgressIndicator())
                  : StreamBuilder(
                  stream: streamSnapshot.data,
                  builder: (BuildContext context,
                      AsyncSnapshot<AlarmChannel> alarmChannelSnap) {
                    if (!alarmChannelSnap.hasData) {
                      return const Center(
                          child: const CircularProgressIndicator());
                    }

                    AlarmChannel alarmChannel = alarmChannelSnap.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SubscribersBlock(alarmChannel),
                      ],
                    );
                  });
            }),
      ),
    );
  }
}

class _SubscribersBlock extends StatelessWidget {
  const _SubscribersBlock(this._alarmChannel);
  final AlarmChannel _alarmChannel;

  @override
  Widget build(BuildContext context) {
    return
      Consumer<AlarmChannelBloc>(
        builder: (BuildContext context, AlarmChannelBloc bloc, _) => Container(
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.background,
          ),
          child: FutureBuilder(
            future: _alarmChannel.subscribers,
            builder: (BuildContext context, AsyncSnapshot<Stream<List<String?>>> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: const CircularProgressIndicator());
              }

              return StreamBuilder(
                  stream: snapshot.data!,
                  builder: (BuildContext context, AsyncSnapshot<List<String?>> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: const CircularProgressIndicator());
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Subscribers", style: Theme
                                .of(context)
                                .textTheme
                                .headline6),
                            IconButton(
                                icon: Icon(Icons.person_add),
                                onPressed: () async {
                                  String? username = await showInputDialog(
                                    context: context,
                                    title: "Add subscriber",
                                    validator: (String? username) {

                                      username = username?.trim().toLowerCase();

                                      if (username == null || username.isEmpty) {
                                        return "Username cannot be empty";
                                      }
                                    },
                                    doneAction: "Add",
                                  );

                                  if (username == null) return;

                                  bool success = await bloc.addUserToChannel(
                                      username, _alarmChannel);

                                  if (!success) {
                                    // Notify user if the username does not exist.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "User does not exist")));
                                  }
                                }
                            )
                          ],
                        ),
                        for (String? name in snapshot.data!)
                          if (name != null) Text(name),
                      ],
                    );
                  });
            },
          ),
        ),
      );
  }
}
