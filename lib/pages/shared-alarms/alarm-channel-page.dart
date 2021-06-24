import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/alarm-channel-bloc.dart';
import 'package:wake_together/colors.dart';
import 'package:wake_together/data/firebase-helper.dart';
import 'package:wake_together/data/models/alarm-channel.dart';

import '../../widgets.dart';

/// Radius of rounded edges of cards.
const double _cardRadius = 16;

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
          backgroundColor: Theme.of(context).colorScheme.background,
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

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SubscribersBlock(alarmChannel),
                              _AlarmBlock(alarmChannel),
                            ],
                          ),
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
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        accentColor: Colors.blue,
      ),
      child: Consumer<AlarmChannelBloc>(
        builder: (BuildContext context, AlarmChannelBloc bloc, _) => Container(
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(8),
          child: StreamBuilder(
              stream: bloc.subscribers,
              builder: (BuildContext context,
                  AsyncSnapshot<List<String?>> snapshot) {
                final List<String?>? users = snapshot.data;

                final String subscriberCount = users == null
                    ? "Subscribers"
                    : users.length == 1
                        ? "1 Subscriber"
                        : "${users.length} Subscribers";

                final bool isOwner = _alarmChannel.ownerId == userId;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  child: Material(
                    color: Theme.of(context).colorScheme.background,
                    child: ExpansionTile(
                        title: Text(subscriberCount),
                        leading: !isOwner
                        ? Icon(Icons.people)
                        : InkResponse(
                            child: Icon(Icons.person_add),
                            onTap: () async {
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
                                        content: Text("User does not exist")));
                              }
                            }),
                        children: [
                          AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: users == null
                                  ? Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : Container(
                                constraints: BoxConstraints(maxHeight: 192),
                                    child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: users.length,
                                        itemBuilder:
                                            (BuildContext context, int position) {
                                          return ListTile(
                                            visualDensity: VisualDensity.comfortable,
                                            leading: Icon(Icons.person, color: toColor(users[position]!)),
                                            title: Text(users[position]!),
                                            trailing: !isOwner
                                                    ? null
                                                    : IconButton(
                                                        icon: Icon(Icons.delete),
                                                        onPressed: () {},
                                                      ),
                                          );
                                        }),
                                  )),
                        ]),
                  ),
                );
              }),
        ),
      ),
    );
  }
}

class _AlarmBlock extends StatelessWidget {
  const _AlarmBlock(this._alarmChannel);

  final AlarmChannel _alarmChannel;

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmChannelBloc>(
        builder: (BuildContext context, AlarmChannelBloc bloc, _) => Container(
              alignment: Alignment.centerLeft,
              child: StreamBuilder(
                stream: bloc.alarmOptions,
                builder: (BuildContext context,
                    AsyncSnapshot<List<AlarmOption>> snapshot) {
                  return StreamBuilder(
                    stream: bloc.currentUserVote,
                    builder: (BuildContext context,
                        AsyncSnapshot<Timestamp?> voteSnapshot) {
                      Timestamp? selection = voteSnapshot.data;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding:
                                EdgeInsets.only(left: 16, right: 16, top: 8),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text("Alarm",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline6),
                                  ),
                                ),
                                if (_alarmChannel.ownerId == userId)
                                  IconButton(
                                    icon: Icon(Icons.add_alarm),
                                    onPressed: () {
                                      Future<TimeOfDay?> timeFuture =
                                          showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now());
                                      bloc.addNewVoteOption(
                                          timeFuture, _alarmChannel);
                                    },
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (selection != null)
                                  TextButton.icon(
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                                Colors.white)),
                                    icon: Icon(Icons.cancel),
                                    label: Text("Opt out"),
                                    onPressed: bloc.optOut,
                                  )
                              ],
                            ),
                          ),
                          for (AlarmOption option in snapshot.data ?? [])
                            RadioListTile(
                              groupValue: selection,
                              title: Text(option.time.format(context)),
                              subtitle: Text(option.dateTime.toString()),
                              onChanged: (Timestamp? value) {
                                if (value != null) bloc.vote(value);
                              },
                              secondary: Text(option.votes.toString()),
                              value: option.timestamp,
                            )
                        ],
                      );
                    },
                  );
                },
              ),
            ));
  }
}
