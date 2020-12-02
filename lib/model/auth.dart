import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:http/http.dart' as http;

class User {
  User({
    this.server,
    this.username,
    this.password,
  });

  final String server;
  final String username;
  final String password;

  @override
  String toString() {
    return "$username@$server $password".toString();
  }

  bool isValid() {
    return (this.server.isNotEmpty &&
        this.username.isNotEmpty &&
        this.password.isNotEmpty);
  }

  String formatRoute(String route) {
    var url = this.server;
    if (this.server[this.server.length - 1] != '/') {
      url = url + '/';
    }
    // Append route
    print(url + route);
    return url + route;
  }

  String formatBasicAuth() {
    String basicAuth = 'Basic ' +
        base64Encode(utf8.encode(this.username + ':' + this.password));
    return basicAuth;
  }
}

class AuthModel extends ChangeNotifier {
  String errorMessage = "";
  User _user;

  void loadSettings() async {
    var _prefs = await EncryptedSharedPreferences();

    User _savedUser;
    try {
      String _saved = await _prefs.getString("user_data");
      print("Saved: $_saved");
      _savedUser = User(
          server: await _prefs.getString("saved_server"),
          username: await _prefs.getString("saved_username"),
          password: await _prefs.getString("saved_password"));
    } catch (e) {
      print("User Not Found: $e");
    }
    _user = _savedUser;

    notifyListeners();
  }

  User get user => _user;

  Future<String> login({
    @required String server,
    @required String username,
    @required String password,
  }) async {
    String _server = server;
    String _username = username;
    String _password = password;

    print("Logging In => $_username, $_password at $_server");
    User _newUser =
        User(password: _password, username: _username, server: _server);

    var response = await http.get(_newUser.formatRoute('api/documents/'),
        headers: <String, String>{'authorization': _newUser.formatBasicAuth()});
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      EncryptedSharedPreferences prefs = EncryptedSharedPreferences();
      await prefs.setString("saved_server", _server);
      await prefs.setString("saved_username", _username);
      await prefs.setString("saved_password", _password);

      return "";
    } else {
      return response.body;
    }
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
    EncryptedSharedPreferences prefs = EncryptedSharedPreferences();
    await prefs.clear();
    return;
  }
}
