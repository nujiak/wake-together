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
class AuthenticationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              switch (state) {
                case LoginState.loggedOut:
                  return LoginForm();
                case LoginState.register:
                  return RegistrationForm();
                case LoginState.loggedIn:
                  return Center(
                    child: ElevatedButton(
                      onPressed: authBloc.signOut,
                      child: Text("Sign out"),
                    ),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}
