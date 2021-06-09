import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/firebase-bloc.dart';

/// Form for signing in using an email address and password.
class LoginForm extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseBloc>(builder: (BuildContext context, FirebaseBloc fbBloc, _) {
      return Column(
        children: [
          _getTextField(_emailController, "Email Address"),
          SizedBox(height: 8),
          _getTextField(_passwordController, "Password", isPasswordField: true),
          SizedBox(height: 16),
          _getButton("Sign in", () {
            fbBloc.signInWithEmailAndPassword(
                _emailController.text,
                _passwordController.text,
                (e) => _showErrorDialog(context, "Sign-in Error", e));
          }),
          _getButton("Register", () => fbBloc.startRegistrationFlow(),
              textButton: true)
        ],
      );
    });
  }
}

/// Form for registering an account using an email address, password and
/// display name.
class RegistrationForm extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseBloc>(builder: (BuildContext context, FirebaseBloc fbBloc, _) {
      return Column(
        children: [
          _getTextField(_emailController, "Email Address"),
          SizedBox(height: 8),
          _getTextField(_passwordController, "Password", isPasswordField: true),
          SizedBox(height: 8),
          _getTextField(_displayNameController, "Display Name"),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _getButton("Back", fbBloc.cancelRegistration, textButton: true),
              _getButton("Register", () {
                fbBloc.registerAccount(
                    _emailController.text,
                    _displayNameController.text,
                    _passwordController.text,
                    (e) => _showErrorDialog(context, "Registration Error", e));
              }),
            ],
          ),
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
              _getButton("OK", () => Navigator.of(context).pop()),
            ],
          ));
}

/// Returns a text field for the authentication form.
Widget _getTextField(TextEditingController controller, String hint,
    {bool isPasswordField = false}) {
  return TextField(
    obscureText: isPasswordField,
    autocorrect: !isPasswordField,
    enableSuggestions: !isPasswordField,
    controller: controller,
    decoration: InputDecoration(
      isDense: false,
      hintText: hint,
      border: UnderlineInputBorder(),
      filled: true,
    ),
  );
}

/// Returns a button for the authentication form.
Widget _getButton(String label, Function()? onPressed,
    {bool textButton = false}) {

  Widget buttonContent = Text(
    label.toUpperCase(),
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  );

  ButtonStyle style = ButtonStyle(
      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          EdgeInsets.only(left: 24, right: 24)),
      shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))));

  return textButton
      ? TextButton(
          onPressed: onPressed,
          child: buttonContent,
          style: style,
        )
      : ElevatedButton(
          onPressed: onPressed,
          child: buttonContent,
          style: style,
        );
}
