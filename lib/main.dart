import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/auth.dart';
import 'login.dart';
import 'share.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final AuthModel _auth = AuthModel();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _auth.loadSettings();
  } catch (e) {
    print("Error Loading Settings: $e");
  }
  runApp(PaperlessShare());
}

class PaperlessShare extends StatefulWidget {
  @override
  _PaperlessShareState createState() => _PaperlessShareState();
}

// https://medium.com/@filipvk/creating-a-custom-color-swatch-in-flutter-554bcdcb27f3
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}

class _PaperlessShareState extends State<PaperlessShare> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthModel>.value(value: _auth),
        ],
        child: Consumer<AuthModel>(builder: (context, model, child) {
          var initialRoute = '/';
          if (model?.user != null) {
            if (model?.user.isValid())
              initialRoute = '/share';
            else
              initialRoute = '/login';
          }

          return MaterialApp(
            title: 'Paperless Share',
            theme: ThemeData(
              primarySwatch: createMaterialColor(Color(0xFF17541f)),
              brightness: Brightness.light,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
              primarySwatch: createMaterialColor(Color(0xFF17541f)),
              accentColor: Colors.green,
              brightness: Brightness.dark,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            initialRoute: initialRoute,
            routes: {
              '/': (context) => new Container(),
              '/login': (context) => new LoginPage(),
              '/share': (context) => new SharePage(),
            },
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale('en', ''),
              const Locale('de', ''),
            ],
          );
        }));
  }
}
