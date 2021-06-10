import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/firebase-bloc.dart';
import 'package:wake_together/constants.dart';
import 'package:wake_together/widgets.dart';

/// Combined authentication form that handles login and registration.
class AuthenticationForm extends StatefulWidget {
  @override
  _AuthenticationFormState createState() => _AuthenticationFormState();
}

class _AuthenticationFormState extends State<AuthenticationForm> {

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;


  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseBloc>(
        builder: (BuildContext context, FirebaseBloc fbBloc, _) {
          return StreamBuilder<LoginState>(
            stream: fbBloc.loginState,
            builder: (BuildContext context, AsyncSnapshot<LoginState> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              bool inRegistration = snapshot.data == LoginState.register;

              return Column(
                children: [
                  _getTextField(_emailController, "Email Address"),
                  SizedBox(height: 8),
                  _getTextField(_passwordController, "Password",
                      isPasswordField: true),
                  SizedBox(height: 16),
                  if (inRegistration)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _getButton("Back", fbBloc.cancelRegistration,
                            textButton: true),
                        _getButton("Register", () {
                          fbBloc.registerAccount(
                              _emailController.text,
                              _passwordController.text,
                                  (e) => _showErrorDialog(
                                  context, "Registration Error", e));
                        }),
                      ],
                    ),
                  if (!inRegistration)
                    _getButton("Sign in", () {
                      fbBloc.signInWithEmailAndPassword(
                          _emailController.text,
                          _passwordController.text,
                              (e) => _showErrorDialog(context, "Sign-in Error", e));
                    }),
                  if (!inRegistration)
                    _getButton("Register", () => fbBloc.startRegistrationFlow(),
                        textButton: true)
                ],
              );
            },
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
Widget _getButton(String label, void Function() onPressed,
    {bool textButton = false}) {
  ButtonStyle style = ButtonStyle(
      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          EdgeInsets.only(left: 24, right: 24)),
      shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))));

  return textButton
      ? StyledButton(
          buttonType: ButtonType.text,
          onPressed: onPressed,
          text: label,
          style: style,
        )
      : StyledButton(
          buttonType: ButtonType.elevated,
          onPressed: onPressed,
          text: label,
          style: style,
        );
}
