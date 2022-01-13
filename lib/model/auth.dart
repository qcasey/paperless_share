import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:dio/dio.dart';

class User {
  User({
    this.server,
    this.token,
  });

  final String server;
  final String token;

  @override
  String toString() {
    return "$token@$server".toString();
  }

  bool isValid() {
    return (this.server.isNotEmpty && this.token.isNotEmpty);
  }

  String formatRoute(String route) {
    var url = this.server;
    if (this.server[this.server.length - 1] != '/') {
      url = url + '/';
    }
    // Append route
    return url + route;
  }

  String formatBasicAuth() {
    String basicAuth = 'Token ' + this.token;
    return basicAuth;
  }
}

class AuthModel extends ChangeNotifier {
  String errorMessage = "";
  User _user;

  Future<bool> loadSettings() async {
    var _prefs = EncryptedSharedPreferences();

    User _savedUser;
    try {
      _savedUser = User(
          server: await _prefs.getString("saved_server"),
          token: await _prefs.getString("saved_token"));
    } catch (e) {
      print("User Not Found: $e");
      return false;
    }
    _user = _savedUser;

    notifyListeners();
    return true;
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

    print("Logging In => $_username at $_server");
    User _newUser = User(server: _server);

    var response = await Dio().post(_newUser.formatRoute('api/token/'),
        data: {"username": username, "password": password});

    if (response.statusCode == 200) {
      Map responseBody = response.data;
      EncryptedSharedPreferences prefs = EncryptedSharedPreferences();
      await prefs.setString("saved_server", _server);
      await prefs.setString("saved_token", responseBody["token"]);

      return "";
    } else {
      return response.data;
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
