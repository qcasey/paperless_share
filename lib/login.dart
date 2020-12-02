import 'package:flutter/material.dart';
import 'class/login_form.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 50),
          child: FractionallySizedBox(
            widthFactor: .8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(image: AssetImage('assets/logo.png')),
                LoginForm()
              ],
            ),
          )),
    ));
  }
}
