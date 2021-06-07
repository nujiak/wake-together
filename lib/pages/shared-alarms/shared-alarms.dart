import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/authentication-bloc.dart';
import 'package:wake_together/pages/shared-alarms/authentication-forms.dart';

import '../../constants.dart';

/// Authentication Page for logging in thru Firebase Authentication.
///
/// Shows a login and registration page if logged out, and redirects
/// to the shared alarms page if logged in.
class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Call build from super for AutomaticKeepAliveClientMixin
    super.build(context);

    return Provider<AuthenticationBloc>(
      create: (BuildContext context) => AuthenticationBloc(),
      dispose: (context, authBloc) => authBloc.dispose(),
      child: Scaffold(
        body: Consumer<AuthenticationBloc>(
          builder: (context, authBloc, _) => StreamBuilder(
            stream: authBloc.loginState,
            builder:
                (BuildContext context, AsyncSnapshot<LoginState> snapshot) {
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
                        style: Theme.of(context).textTheme.headline3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: WillPopScope(
                      onWillPop: () async {
                        if (state == LoginState.register) {
                          authBloc.cancelRegistration();
                          return false;
                        }
                        return true;
                      },
                      child: SingleChildScrollView(
                        child: Container(
                          margin: EdgeInsets.only(left: 64, right: 64),
                          child: state == LoginState.loggedOut
                              ? LoginForm()
                              : RegistrationForm(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SharedAlarmsPage extends StatelessWidget {
  const SharedAlarmsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationBloc>(
      builder: (context, authBloc, _) {
        return Center(
            child: ElevatedButton(
              onPressed: authBloc.signOut,
              child: Text("Sign out"),
            )
        );
      },
    );
  }
}
