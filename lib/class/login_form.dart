import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:regexed_validator/regexed_validator.dart';
import '../model/auth.dart';
import '../share.dart';

// Define a custom Form widget.
class LoginForm extends StatefulWidget {
  @override
  LoginFormState createState() {
    return LoginFormState();
  }
}

class LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController serverController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(children: <Widget>[
          _buildTextFields(),
          _buildLoginButton(context)
        ]));
  }

  Widget _buildTextFields() {
    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
            child: new TextFormField(
              controller: serverController,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Server is required.';
                }
                return null;
              },
              decoration: new InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  hintText: "http://192.168.1.50:8000",
                  labelText: 'Server'),
            ),
          ),
          new AutofillGroup(
              child: Column(children: <Widget>[
            new Container(
              child: new TextFormField(
                autofillHints: [AutofillHints.username],
                controller: usernameController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Username is required.';
                  }
                  return null;
                },
                decoration: new InputDecoration(
                  labelText: 'Username',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
            new Container(
              child: new TextFormField(
                autofillHints: [AutofillHints.password],
                controller: passwordController,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Password is required.';
                  }
                  return null;
                },
                decoration: new InputDecoration(
                  labelText: 'Password',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                obscureText: true,
              ),
            )
          ]))
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    final _auth = Provider.of<AuthModel>(context, listen: true);
    return Container(
        height: 40,
        margin: EdgeInsets.fromLTRB(0, 30, 0, 0),
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: RaisedButton(
          textColor: Colors.white,
          color: Color(0xFF17541f),
          child: Text('Login'),
          onPressed: () async {
            if (_formKey.currentState.validate()) {
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text('Logging in...')));

              _auth
                  .login(
                      server: serverController.text,
                      username: usernameController.text,
                      password: passwordController.text)
                  .then((loginError) {
                if (loginError == "") {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/share", (_) => false);
                } else {
                  print(loginError);
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to login: ' + loginError)));
                }
              });
            }
          },
        ));
  }
}
