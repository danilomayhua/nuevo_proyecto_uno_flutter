import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tenfo/firebase_options.dart';
import 'package:tenfo/screens/login/login_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/services/firebase_notificaciones.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No comparte la misma instancia de FirebaseNotificaciones() con foreground (¿Tal vez esto no pase en iOS?)
  // Por lo tanto, las variables no están inicializadas

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseNotificaciones().setupFlutterNotifications();
  FirebaseNotificaciones().showFlutterNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool(SharedPreferencesKeys.isLoggedIn) ?? false;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseNotificaciones().setupFlutterNotifications();
  } catch (e) {
    //
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    try {
      FirebaseNotificaciones().requerirPermisosYForegroundListen();
    } catch (e) {
      //
    }

    return MaterialApp(
      navigatorKey: FirebaseNotificaciones().navigationKey,
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
    );
  }
}

