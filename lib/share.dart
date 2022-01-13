import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_handle_file/flutter_handle_file.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'model/auth.dart';

class SharePage extends StatefulWidget {
  @override
  _SharePageState createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  StreamSubscription _intentDataStreamSubscription;
  StreamSubscription _fileDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles;
  bool _isActivelySharing = false;

  void uploadDocuments() {
    if (_isActivelySharing) {
      for (var f in _sharedFiles) {
        uploadFileToPaperless(f.path);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    handleSharedFile();
    handleOpenWithFile();
  }

  void handleSharedFile() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        _isActivelySharing = _sharedFiles != null && _sharedFiles.isNotEmpty;
      });
      uploadDocuments();
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        _isActivelySharing = _sharedFiles != null && _sharedFiles.isNotEmpty;
      });
      uploadDocuments();
    });
  }

  void handleOpenWithFile() async {
    handleInitialFile();
    initializeFileStreamHandling();
  }

  Future<Null> handleInitialFile() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      String initialFile = await getInitialFile();
      if (initialFile != null) {
        uploadFileToPaperless(Uri.parse(initialFile).toFilePath());
      }
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<Null> initializeFileStreamHandling() async {
    _fileDataStreamSubscription = getFilesStream().listen((String file) {
      if (file != null) {
        uploadFileToPaperless(Uri.parse(file).toFilePath());
      }
    }, onError: (err) {
      print(err);
    });
  }

  void uploadFileToPaperless(String path) async {
    final _auth = Provider.of<AuthModel>(context, listen: false);
    print("Uploading " + path + " to " + _auth.user.server);

    var formData = FormData.fromMap({
      "document": await MultipartFile.fromFile(path),
    });
    Response response;
    try {
      response = await Dio().post(
          _auth.user.formatRoute('api/documents/post_document/'),
          data: formData,
          options: Options(headers: <String, String>{
            'authorization': _auth.user.formatBasicAuth()
          }));
    } on DioError catch (e) {
      response = e.response;
    }

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).fileUploaded,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.data.toString(),
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
    _fileDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Paperless Share"),
          actions: [_logoutButton()],
        ),
        body: Center(
          child: FractionallySizedBox(child: _bodyContent()),
        ));
  }

  Widget _bodyContent() {
    if (_isActivelySharing) {
      return new Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SpinKitRing(
          color: Color(0xFF17541f),
          size: 100.0,
        )
      ]);
    }

    return new Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            _shareScreenExample(),
            _welcomeText(),
          ],
        )));
  }

  Widget _logoutButton() {
    final _auth = Provider.of<AuthModel>(context, listen: true);

    if (_isActivelySharing) {
      return new Container();
    }

    return // action button
        IconButton(
      icon: Icon(Icons.logout),
      tooltip: "Logout",
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: new Text(AppLocalizations.of(context).logout),
                actions: [
                  new FlatButton(
                    child: new Text(AppLocalizations.of(context).yes),
                    onPressed: () {
                      _auth.logout();
                      Navigator.pushReplacementNamed(context, "/login");
                    },
                  ),
                  new FlatButton(
                      child: new Text(AppLocalizations.of(context).no),
                      onPressed: () {
                        Navigator.of(context).pop();
                      }),
                ],
              );
            });
      },
    );
  }

  Widget _welcomeText() {
    return new Container(
        padding: EdgeInsets.symmetric(vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _paddedText(AppLocalizations.of(context).readyToUpload),
            _paddedText(AppLocalizations.of(context).shareInstructions),
            _paddedText(AppLocalizations.of(context).serverInstructions),
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
