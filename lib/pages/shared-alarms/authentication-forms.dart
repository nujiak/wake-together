import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wake_together/blocs/shared-alarms-bloc.dart';
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
    return Consumer<SharedAlarmsBloc>(
        builder: (BuildContext context, SharedAlarmsBloc fbBloc, _) {
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

class UsernameForm extends StatefulWidget {
  const UsernameForm({Key? key}) : super(key: key);

  @override
  _UsernameFormState createState() => _UsernameFormState();
}

class _UsernameFormState extends State<UsernameForm> {

  late final TextEditingController _controller;
  late final GlobalKey<FormState> _formKey;
  bool _usernameExists = false;

  /// Checks if a username does not contain invalid characters.
  static bool _validateUsername(String username) {
    username = username.trim();
    for (String character in username.characters) {
      if (!VALID_USERNAME_CHARACTERS.contains(character)) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SharedAlarmsBloc>(
      builder: (BuildContext context, SharedAlarmsBloc fbBloc, _) => Container(
        child: Container(
          padding: EdgeInsets.only(left: 48, right: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("You need a username to share alarms with your friends.",
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _controller,
                  validator: (String? value) {
                    value = value?.trim().toLowerCase();
                    if (value?.isEmpty ?? false) {
                      return "Username cannot be empty";
                    }
                    if (!_validateUsername(value!)) {
                      return "Username contains illegal characters";
                    }
                    if (_usernameExists) {
                      return "This username is already taken";
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Username",
                    filled: true,
                  ),
                ),
              ),
              SizedBox(height: 8),
              _getButton("Confirm", () async {
                // Reset _usernameExists status first
                _usernameExists = false;

                // Validate form
                if (_formKey.currentState?.validate() ?? false) {
                  bool successful = await fbBloc.registerUsername(_controller.text.trim().toLowerCase());
                  if (!successful) {
                    // If registration fails, the username is already taken
                    _usernameExists = true;
                    _formKey.currentState?.validate();
                  }
                }
              })
            ],
          ),
        ),
      ),
    );
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
Widget _getTextField(TextEditingController controller, String label,
    {bool isPasswordField = false}) {
  return TextField(
    obscureText: isPasswordField,
    autocorrect: !isPasswordField,
    enableSuggestions: !isPasswordField,
    controller: controller,
    decoration: InputDecoration(
      isDense: false,
      labelText: label,
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
