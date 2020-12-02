import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'model/auth.dart';

class SharePage extends StatefulWidget {
  @override
  _SharePageState createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles;
  final AuthModel _auth = AuthModel();

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        if (_sharedFiles != null && _sharedFiles.isNotEmpty) {
          for (var f in _sharedFiles) {
            uploadFileToPaperless(f.path);
          }
        }
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        if (_sharedFiles != null && _sharedFiles.isNotEmpty) {
          for (var f in _sharedFiles) {
            uploadFileToPaperless(f.path);
          }
        }
      });
    });
  }

  void uploadFileToPaperless(String path) async {
    final _auth = Provider.of<AuthModel>(context, listen: true);
    print("Uploading " + path + " to " + _auth.user.server);

    var formData = FormData.fromMap({
      "document": await MultipartFile.fromFile(path),
    });
    var response = await Dio().post(
        _auth.user.formatRoute('api/documents/post_document/'),
        data: formData,
        options: RequestOptions(headers: <String, String>{
          'authorization': _auth.user.formatBasicAuth()
        }));

    print(response.statusCode);
    print(response.data);

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: "File uploaded.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.data,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    }

    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _auth = Provider.of<AuthModel>(context, listen: true);

    return Scaffold(
        appBar: AppBar(
          title: Text("Paperless Share"),
          actions: [
            // action button
            IconButton(
              icon: Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: new Text("Logout?"),
                        actions: [
                          new FlatButton(
                            child: new Text("Yes"),
                            onPressed: () {
                              _auth.logout();
                              Navigator.pushReplacementNamed(context, "/login");
                            },
                          ),
                          new FlatButton(
                              child: new Text("No"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              }),
                        ],
                      );
                    });
              },
            ),
          ],
        ),
        body: Center(
            child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 0),
                  child: FractionallySizedBox(
                      child: Column(
                    children: <Widget>[
                      _shareScreenExample(),
                      _welcomeText(),
                    ],
                  )),
                ))));
  }

  Widget _welcomeText() {
    return new Container(
        padding: EdgeInsets.symmetric(vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _paddedText("Ready to upload!"),
            _paddedText(
                "Select Paperless Share in the Share Menu to upload pictures and documents."),
            _paddedText("Your server will begin processing it automatically."),
          ],
        ));
  }

  Widget _shareScreenExample() {
    return new FractionallySizedBox(
      widthFactor: 0.7,
      child: Image(image: AssetImage('assets/ShareScreen.png')),
    );
  }

  Widget _paddedText(String text) {
    return new Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ));
  }
}
