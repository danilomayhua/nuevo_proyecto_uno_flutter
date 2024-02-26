import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tenfo/firebase_options.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/signup/views/signup_picture_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/firebase_notificaciones.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No comparte la misma instancia de FirebaseNotificaciones() con foreground (¿Tal vez esto no pase en iOS?)
  // Por lo tanto, las variables no están inicializadas

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseNotificaciones().setupFlutterNotifications();
  FirebaseNotificaciones().showFlutterNotification(message);
}
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool(SharedPreferencesKeys.isLoggedIn) ?? false;
  UsuarioSesion? usuarioSesion;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseNotificaciones().setupFlutterNotifications();


    if(isLoggedIn){
      usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);
    }
  } catch (e) {
    //
  }

  runApp(MyApp(isLoggedIn: isLoggedIn, usuarioSesion: usuarioSesion,));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.isLoggedIn, required this.usuarioSesion}) : super(key: key);

  final bool isLoggedIn;
  final UsuarioSesion? usuarioSesion;

  @override
  Widget build(BuildContext context) {
    try {
      FirebaseNotificaciones().configurarNotificacionAbiertaYForegroundListen();
    } catch (e) {
      //
    }

    return MaterialApp(
      navigatorKey: FirebaseNotificaciones().navigationKey,
      title: 'Tenfo',
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

      // Al cambiar una condicion aqui, cambiar _verificarSesion de los screen en onGenerateRoute
      home: isLoggedIn
          ? (_isUsuarioSinFoto())
            ? const SignupPicturePage(isFromSignup: false,)
            : const PrincipalPage()
          : const WelcomePage(),

      onGenerateRoute: (settings){
        // Al crear nuevas rutas para deep linking, agregar path en AndroidManifest.xml y en archivo iOS de la web (ver documentacion)

        // Si la app no está abierta, abre "home" y despues la ruta especificada (al ir a atras, ira a home)
        // Si la app está abierta, abre la ruta especificada (al ir atras, ira a lo que estaba abierto)

        // No comprobar aqui isLoggedIn, porque el valor no se actualiza hasta cerrar y volver a abrir la app.

        Uri? uri = Uri.tryParse(settings.name ?? "");

        if (uri != null && uri.pathSegments.length == 1 && uri.pathSegments[0].startsWith('@')) {
          String username = uri.pathSegments[0].substring(1); // Elimina el "@" del inicio
          if (username.length > 50) {
            username = username.substring(0, 50); // Obtiene solo el string hasta una longitud de 50
          }
          return MaterialPageRoute(builder: (context) => UserPage(usuario: null, routeUsername: username,));
        }

        if (uri != null && uri.pathSegments.length == 2 && uri.pathSegments[0] == 'add-friend') {
          String username = uri.pathSegments[1];
          if (username.length > 50) {
            username = username.substring(0, 50); // Obtiene solo el string hasta una longitud de 50
          }
          return MaterialPageRoute(builder: (context) => UserPage(usuario: null, routeUsername: username,));
        }

        //return MaterialPageRoute(builder: (context) => UnknownScreen());
        return null;
      },
    );
  }

  bool _isUsuarioSinFoto(){
    if(!isLoggedIn) return false;
    if(usuarioSesion == null) return false;

    // Comprueba 'usuario_foto_default.png' para los usuarios que actualizan la app y aun no cargaron el valor en isUsuarioSinFoto
    //if(usuarioSesion!.isUsuarioSinFoto || usuarioSesion!.foto == (constants.urlBase + '/images/usuario_foto_default.png'))

    // TODO : Hubo un error, al registrarse usuarios nuevos y elegir foto no cambiaba isUsuarioSinFoto. Cambiar esta linea cuando la mayoria haya actualizado la app.
    if(usuarioSesion!.foto == (constants.urlBase + '/images/usuario_foto_default.png')){
      return true;
    } else {
      return false;
    }
  }
}

