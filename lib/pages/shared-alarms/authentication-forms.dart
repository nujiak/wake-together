import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/authentication-bloc.dart';

/// Form for logging in using an email and password.
class LoginForm extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationBloc>(builder: (context, authBloc, _) {
      return Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Email Address",
            ),
          ),
          TextField(
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: "Password",
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                  onPressed: () => authBloc.startRegistrationFlow(),
                  child: Text("Register")),
              ElevatedButton(
                onPressed: () {
                  authBloc.signInWithEmailAndPassword(
                      _emailController.text,
                      _passwordController.text,
                      (e) => _showErrorDialog(context, "Invalid Password", e)
                  );
                },
                child: Text("Sign In"),
              ),
            ],
          )
        ],
      );
    });
  }
}

/// Form for registering an account with an email, password, and display name.
class RegistrationForm extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationBloc>(builder: (context, authBloc, _) {
      return Column(
        children: [
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(hintText: "Display Name"),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(hintText: "Email Address"),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: "Password",
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                  onPressed: authBloc.cancelRegistration,
                  child: Text("Back"),
              ),
              ElevatedButton(
                onPressed: () {
                  authBloc.registerAccount(
                    _emailController.text,
                      _displayNameController.text,
                      _passwordController.text,
                          (e) => _showErrorDialog(context, "Registration Error", e));
                },
                child: Text("Register"),
              ),
            ],
          )

        ],
      );
    });
  }
}

/// Shows an error dialog for the provided FirebaseAuthException.
void _showErrorDialog(
    BuildContext context, String title, FirebaseAuthException e) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(
              title,
              style: TextStyle(fontSize: 24),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    '${(e as dynamic).message}',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ));
}
