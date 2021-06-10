import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/firebase-bloc.dart';
import 'package:wake_together/pages/shared-alarms/authentication-forms.dart';
import 'package:wake_together/widgets.dart';

import '../../constants.dart';

/// Authentication Page for logging in thru Firebase Authentication.
///
/// Shows a login and registration page if logged out, and redirects
/// to the shared alarms page if logged in.
class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Call build from super for AutomaticKeepAliveClientMixin
    super.build(context);

    return Provider<FirebaseBloc>(
      create: (BuildContext context) => FirebaseBloc(),
      dispose: (BuildContext context, FirebaseBloc fbBloc) => fbBloc.dispose(),
      child: Consumer<FirebaseBloc>(
        builder: (BuildContext context, FirebaseBloc fbBloc, _) =>
            StreamBuilder(
              stream: fbBloc.loginState,
              builder: (BuildContext context,
                  AsyncSnapshot<LoginState> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                LoginState state = snapshot.data!;
                if (state == LoginState.loggedIn) {
                  return SharedAlarmsPage();
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        padding: EdgeInsets.only(bottom: 32),
                        child: Text(
                          "WakeTogether",
                          style: Theme
                              .of(context)
                              .textTheme
                              .headline3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: WillPopScope(
                        onWillPop: () async {
                          if (state == LoginState.register) {
                            fbBloc.cancelRegistration();
                            return false;
                          }
                          return true;
                        },
                        child: SingleChildScrollView(
                          child: Container(
                            margin: EdgeInsets.only(left: 64, right: 64),
                            child: AuthenticationForm(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class SharedAlarmsPage extends StatelessWidget {
  const SharedAlarmsPage({Key? key}) : super(key: key);

  /// Shows a dialog requesting a non-empty channel name and creates an alarm
  /// channel with the name.
  void _createNewAlarmChannel(BuildContext context, FirebaseBloc fbBloc) async {
    String? newChannelName = await showInputDialog(
        context: context,
        title: "New Alarm Channel",
        validator: (value) {
          value = value?.trim();
          if (value == null || value.isEmpty) {
            return "Name cannot be empty";
          } else if (value.length > 32) {
            return "Name has more than 32 characters"
          }
          return null;
        },
        labelText: "Name"
        doneAction: "Create",
        cancelAction: "Cancel"
    );

    if (newChannelName != null) {
      fbBloc.createNewAlarmChannel(newChannelName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseBloc>(
      builder: (BuildContext context, FirebaseBloc fbBloc, _) {
        return StreamBuilder<String?>(
            stream: fbBloc.username,
            builder: (BuildContext context, AsyncSnapshot<String?> usernameSnap) {

              if (!usernameSnap.hasData) {
                return UsernameForm();
              }

              return StreamBuilder<QuerySnapshot>(
                stream: fbBloc.subscribedChannels,
                builder:
                    (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> subscribedChannelsSnap) {
                  return Scaffold(
                    appBar: AppBar(
                      backgroundColor: Theme.of(context).colorScheme.background,
                      title: Text(usernameSnap.data!),
                      actions: [
                        IconButton(onPressed: fbBloc.signOut, icon: Icon(Icons.logout))
                      ],
                    ),
                    floatingActionButton: FloatingActionButton(
                      backgroundColor: Theme
                          .of(context)
                          .colorScheme
                          .primary,
                      child: const Icon(Icons.add),
                      onPressed: () => _createNewAlarmChannel(context, fbBloc),
                    ),
                    body: ListView.builder(
                        itemCount: subscribedChannelsSnap.hasData
                            ? subscribedChannelsSnap.data!.size
                            : 0,
                        itemBuilder: (BuildContext context, int index) {
                          print(subscribedChannelsSnap.data!.docs[index].data());
                          return _SharedAlarmsListItem(
                              subscribedChannelsSnap.data!.docs[index]);
                        }),
                  );
                },
              );
            }
        );
      },
    );
  }
}

class _SharedAlarmsListItem extends StatelessWidget {
  const _SharedAlarmsListItem(this.doc);
  final DocumentSnapshot doc;
  static const double _cardRadius = 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 24),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(_cardRadius)),
          color: Colors.grey[800],
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(2, 2))
          ]),
      child: Text(doc.data()?['channelName'] ?? "<null>",
          style: Theme.of(context).textTheme.headline3,
      ),
    );
  }
}
