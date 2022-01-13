import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
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

  Future<Map<int, String>> getAvailableTagsList() async {
    final _auth = Provider.of<AuthModel>(context, listen: false);
    var response = await Dio().get(_auth.user.formatRoute('api/tags/'),
        options: Options(headers: <String, String>{
          'authorization': _auth.user.formatBasicAuth()
        }));
    Map<int, String> tags = Map<int, String>();
    for (var availableTag in response.data["results"]) {
      tags[availableTag["id"]] = availableTag["name"];
    }

    return tags;
  }

  void uploadFileToPaperless(String path) async {
    final _auth = Provider.of<AuthModel>(context, listen: false);
    print("Uploading " + path + " to " + _auth.user.server);

    // Check that tags still exist
    List<int> postTags = List<int>.empty(growable: true);
    try {
      EncryptedSharedPreferences prefs = EncryptedSharedPreferences();
      final tags = await prefs.getString("use_document_tags");
      final tagList = tags != ";" ? tags.split(';') : [];
      final availableTags = await getAvailableTagsList();

      for (var tag in tagList) {
        for (var availableTagID in availableTags.keys) {
          if (int.parse(tag) == availableTagID) {
            postTags.add(availableTagID);
          }
        }
      }
    } catch (e) {
      print(e);
    }

    var formData = FormData.fromMap({
      "tags": postTags,
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
      print(e);
      print(response.data.toString());
    }

    Fluttertoast.showToast(
      msg: response.statusCode == 200
          ? AppLocalizations.of(context).fileUploaded
          : response.data.toString(),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
    );

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
          actions: _isActivelySharing ? [] : [_setTagButton(), _logoutButton()],
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

  Widget _setTagButton() {
    final _auth = Provider.of<AuthModel>(context, listen: true);

    return // action button
        IconButton(
      icon: Icon(Icons.local_offer_outlined),
      tooltip: "Set Tag",
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return TagAlertDialog(getAvailableTagsList: getAvailableTagsList);
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

class TagAlertDialog extends StatefulWidget {
  final Function getAvailableTagsList;

  const TagAlertDialog({Key key, this.getAvailableTagsList}) : super(key: key);

  @override
  _TagAlertDialogState createState() => _TagAlertDialogState();
}

class _TagAlertDialogState extends State<TagAlertDialog> {
  Set<int> selectedTags = Set<int>();
  Map<int, String> _availableTags = Map<int, String>();

  @override
  void initState() {
    super.initState();
    widget.getAvailableTagsList().then((availableTags) => {
          setState(() {
            _availableTags = availableTags;
          })
        });
    EncryptedSharedPreferences prefs = EncryptedSharedPreferences();
    prefs.getString("use_document_tags").then((value) {
      Set<int> newTags = new Set<int>();

      if (value != ";")
        value.split(';').forEach((element) {
          newTags.add(int.parse(element));
        });
      setState(() {
        selectedTags = newTags;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> checkboxes = List<Widget>.empty(growable: true);
    for (var tagID in _availableTags.keys) {
      final tagName = _availableTags[tagID];
      checkboxes.add(CheckboxListTile(
          secondary: Icon(Icons.local_offer_outlined),
          dense: true,
          visualDensity: VisualDensity(vertical: -2, horizontal: -4),
          title: Text(tagName),
          // subtitle: Text(tagID.toString()),
          value: this.selectedTags.contains(tagID),
          onChanged: (isSelected) {
            var newTags = new Set<int>.from(selectedTags);
            if (isSelected)
              newTags.add(tagID);
            else
              newTags.remove(tagID);
            setState(() {
              selectedTags = newTags;
            });
          }));
    }

    return AlertDialog(
      title: new Text("Paperless Tag"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(AppLocalizations.of(context).tagIntro),
        Container(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Column(children: checkboxes))
      ]),
      actionsPadding: EdgeInsets.symmetric(horizontal: 10),
      actions: [
        new TextButton(
          child: new Text(AppLocalizations.of(context).tagConfirm),
          onPressed: () async {
            EncryptedSharedPreferences prefs = EncryptedSharedPreferences();
            var ret = await prefs.setString(
                "use_document_tags",
                this.selectedTags.length > 0
                    ? this.selectedTags.join(';')
                    : ";");
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
