import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nuevoproyectouno/screens/login/login_page.dart';
import 'package:nuevoproyectouno/screens/principal/principal_page.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:nuevoproyectouno/utilities/shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool(SharedPreferencesKeys.isLoggedIn) ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: constants.blackGeneral,
          elevation: 1,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es')
      ],
      home: isLoggedIn
          ? const PrincipalPage()
          : const LoginPage(),
      //home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

