import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/mensaje.dart';
import 'package:tenfo/models/notificacion.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/notificaciones/notificaciones_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class FirebaseNotificaciones {

  static final FirebaseNotificaciones _singleton = FirebaseNotificaciones._internal();

  FirebaseNotificaciones._internal(){
    navigationKey = GlobalKey<NavigatorState>();
  }

  factory FirebaseNotificaciones() {
    return _singleton;
  }

  /*static FirebaseNotificaciones instance = FirebaseNotificaciones();
  FirebaseNotificaciones(){
    // navigationKey = GlobalKey<NavigatorState>();
  }*/


  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isFlutterLocalNotificationsInitialized = false;

  static const int _localNotificationIdGenerales = 0;
  static const int _localNotificationIdChats = 1;

  late GlobalKey<NavigatorState> navigationKey;

  Chat? chatAbiertoAhora;

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_stat_logo_tenfo');
    const IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    ); // No solicita permisos automaticamente (esto lo hara FirebaseMessaging)
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) async {
        if(payload != null) _abrirPantalla(payload);
      },
    );


    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    ); // Configuracion para iOS

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> configurarNotificacionAbiertaYForegroundListen() async {
    // String? token = await FirebaseMessaging.instance.getToken(); // Sin esto, no recibia los datos en foreground (ahora no es necesario)

    // Se abre la app desde una notificacion de fcm, cuando estaba finalizada
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if(initialMessage != null){
      if(initialMessage.notification != null) _abrirPantalla(jsonEncode(initialMessage.data));
    }

    // Se abre la app desde una notificacion de fcm, cuando estaba en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if(message.notification != null) _abrirPantalla(jsonEncode(message.data));
    });

    // La app está en primer plano, fcm no muestra una notificación (esto solo debe llamarse una vez a nivel global)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // TODO : probar que no muestre dos veces en iOS
      if(message.notification != null) _showNotificactionForeground(message);
    });


    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) { _guardarTokenFirebase(fcmToken); })
        .onError((err) {});


    /*
    // Permisos para iOS (para ser necesario llamarlo desde FlutterLocalNotificationsPlugin tambien)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    */

    // Esto solo debe llamarse una vez a nivel global
    final NotificationAppLaunchDetails? notificationAppLaunchDetails = await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      String? payload = notificationAppLaunchDetails!.payload;
      if(payload != null) _abrirPantalla(payload);
    }
  }

  void _abrirPantalla(String payload){
    dynamic object;
    try {
      object = jsonDecode(payload);
      if(object == null || object['screen'] == null){
        return;
      }
    } catch(e){
      return;
    }

    if(object['screen'] == 'notificaciones_page'){

      navigationKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(
          builder: (context) => const PrincipalPage(principalPageView: PrincipalPageView.home)
      ), (route) => false);
      navigationKey.currentState?.push(MaterialPageRoute(
          builder: (context) => const NotificacionesPage()
      ));

    } else if(object['screen'] == 'mensajes_page'){

      navigationKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(
          builder: (context) => const PrincipalPage(principalPageView: PrincipalPageView.mensajes)
      ), (route) => false);

    }
  }

  void _showNotificactionForeground(RemoteMessage message){
    if(message.data['screen'] == null) return;

    // Las notificaciones manejan distintos id que FCM, asi que no sobrescribira la notificacion
    // actual de FCM (si existe). Pero si sobrescribira las notificaciones de foreground.

    if(message.data['screen'] == 'notificaciones_page'){
      _showNotificationWithSound(
        _localNotificationIdGenerales,
        message.notification?.title ?? "",
        message.notification?.body ?? "",
        jsonEncode(message.data),
      );
    } else if(message.data['screen'] == 'mensajes_page'){
      _showNotificationWithSound(
        _localNotificationIdChats,
        message.notification?.title ?? "",
        message.notification?.body ?? "",
        jsonEncode(message.data),
      );
    }
  }

  /*
  Future<void> showFlutterNotification(RemoteMessage message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Necesario para consistencia en foreground y background

    bool isLoggedIn = prefs.getBool(SharedPreferencesKeys.isLoggedIn) ?? false;
    if(isLoggedIn){

      await _crearNotificacionesGuardadas(prefs);

      Map<String, dynamic> data = message.data;

      if(data['type'] == 'notificacion'){

        _showNotificationGenerales(prefs, jsonDecode(data['data']));

      } else if(data['type'] == 'chat_individual_mensaje' || data['type'] == 'chat_grupal_mensaje'){

        bool isChatGrupal = data['type'] == 'chat_grupal_mensaje';
        _showNotificationChats(prefs, jsonDecode(data['data']), isChatGrupal);

      }

    }
  }
  */

  Future<void> _showNotificationWithSound(int id, String title, String body, String payload) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'canal_general',
      'Notificaciones generales y mensajes nuevos',
      importance: Importance.max,
      priority: Priority.high,
    );
    const IOSNotificationDetails iOSPlatformChannelSpecifics = IOSNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> _showNotificationWithoutSound(int id, String title, String body, String payload) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'canal_general_sin_sonido',
        'Mensajes agrupados',
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,
        enableVibration: false
    );
    const IOSNotificationDetails iOSPlatformChannelSpecifics = IOSNotificationDetails(presentSound: false);

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> _guardarTokenFirebase(String token) async {
    /*setState(() {
      _loading = true;
    });*/
    String origenPlataforma = "android";
    if(Platform.isIOS){
      origenPlataforma = "iOS";
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlGuardarFirebaseToken,
      body: {
        "firebase_token": token,
        "plataforma": origenPlataforma,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){
        //
      } else {
        //_showSnackBar("Se produjo un error inesperado");
      }
    }

    /*setState(() {
      _loading = false;
    });*/
  }



  /*
  Future<void> _crearNotificacionesGuardadas(SharedPreferences prefs) async {
    if(!prefs.containsKey(SharedPreferencesKeys.notificacionesPush)){
      String notificacionesActuales = jsonEncode({
        'notificacion_general' : {'numero' : 0},
        'mensajes_privados' : {'chats' : []}
      });

      await prefs.setString(SharedPreferencesKeys.notificacionesPush, notificacionesActuales);
    }
  }


  Future<void> _sumarLocalNotificationGenerales(SharedPreferences prefs, int nuevoNumero) async {
    var notificacionesActuales = jsonDecode(prefs.getString(SharedPreferencesKeys.notificacionesPush)!);
    notificacionesActuales['notificacion_general']['numero'] = nuevoNumero;

    await prefs.setString(SharedPreferencesKeys.notificacionesPush, jsonEncode(notificacionesActuales));
  }
  */

  Future<void> limpiarLocalNotificationGenerales() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey(SharedPreferencesKeys.notificacionesPush)){
      var notificacionesActuales = jsonDecode(prefs.getString(SharedPreferencesKeys.notificacionesPush)!);
      notificacionesActuales['notificacion_general']['numero'] = 0;

      await prefs.setString(SharedPreferencesKeys.notificacionesPush, jsonEncode(notificacionesActuales));
    }

    _flutterLocalNotificationsPlugin.cancel(_localNotificationIdGenerales);
  }

  /*
  Future<void> _showNotificationGenerales(SharedPreferences prefs, Map<String, dynamic> data) async {

    var notificacionesActuales = jsonDecode(prefs.getString(SharedPreferencesKeys.notificacionesPush)!);
    int numero = notificacionesActuales['notificacion_general']['numero'];

    String title;
    String description;

    if(numero > 0){
      numero++;
      title = 'Tienes $numero notificaciones nuevas';
    } else {
      numero = 1;
      title = 'Nueva notificación';
    }

    NotificacionTipo notificacionTipo = Notificacion.getNotificacionTipoFromString(data['notificacion']['tipo']);

    switch(notificacionTipo){
      case NotificacionTipo.ACTIVIDAD_INGRESO_SOLICITUD:
        description = '${data['notificacion']['autor_usuario']['nombre_completo']} envió una solicitud para entrar a tu actividad.';
        break;
      case NotificacionTipo.ACTIVIDAD_INGRESO_ACEPTADO:
        description = 'Fuiste aceptado en una actividad.';
        break;
      case NotificacionTipo.ACTIVIDAD_CREADOR:
        description = '${data['notificacion']['autor_usuario']['nombre_completo']} te agregó como cocreador de una actividad. Tienes que confirmar para ser parte.';
        break;
      case NotificacionTipo.STICKER_ENVIADO:
        description = '¡${data['notificacion']['autor_usuario']['nombre_completo']} te envió un sticker!';
        break;
      case NotificacionTipo.CONTACTO_SOLICITUD:
        description = '${data['notificacion']['autor_usuario']['nombre_completo']} te envió una solicitud de amigos.';
        break;
      case NotificacionTipo.CONTACTO_NUEVO:
        description = '${data['notificacion']['autor_usuario']['nombre_completo']} aceptó tu solicitud de amigos.';
        break;
      default:
        description = '';
    }

    await _sumarLocalNotificationGenerales(prefs, numero);


    String payload = jsonEncode({
      'screen' : 'notificaciones_page',
      'data' : ''
    });

    if(numero > 5){
      await _showNotificationWithoutSound(_localNotificationIdGenerales, title, description, payload);
    } else {
      await _showNotificationWithSound(_localNotificationIdGenerales, title, description, payload);
    }
  }
  */


  /*
  Future<void> _sumarLocalNotificationChats(SharedPreferences prefs, Map<String, dynamic> data) async {
    var notificacionesActuales = jsonDecode(prefs.getString(SharedPreferencesKeys.notificacionesPush)!);

    List chats = notificacionesActuales['mensajes_privados']['chats'];
    bool chatNuevo = true;

    for(var i = 0; i < chats.length; i++){
      var chat = chats[i];
      if(chat['id'] == data['chat']['id'].toString()){
        chatNuevo = false;

        notificacionesActuales['mensajes_privados']['chats'][i]['num_mensajes']++;
        break;
      }
    }

    if(chatNuevo) {
      notificacionesActuales['mensajes_privados']['chats'].add({
        'id': data['chat']['id'].toString(),
        'num_mensajes': 1
      });
    }

    await prefs.setString(SharedPreferencesKeys.notificacionesPush, jsonEncode(notificacionesActuales));
  }
  */

  Future<void> limpiarLocalNotificationChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey(SharedPreferencesKeys.notificacionesPush)){
      var notificacionesActuales = jsonDecode(prefs.getString(SharedPreferencesKeys.notificacionesPush)!);
      notificacionesActuales['mensajes_privados']['chats'] = [];

      await prefs.setString(SharedPreferencesKeys.notificacionesPush, jsonEncode(notificacionesActuales));
    }

    _flutterLocalNotificationsPlugin.cancel(_localNotificationIdChats);
  }

  /*
  Future<void> _showNotificationChats(SharedPreferences prefs, Map<String, dynamic> data, bool isChatGrupal) async {
    if(chatAbiertoAhora != null && chatAbiertoAhora!.id == data['chat']['id'].toString()){
      return;
    }

    var notificacionesActuales = jsonDecode(prefs.getString(SharedPreferencesKeys.notificacionesPush)!);
    List chats = notificacionesActuales['mensajes_privados']['chats'];

    String title;
    String description;

    bool conSonido = true;

    String msg = "";
    MensajeTipo mensajeTipo = Mensaje.getMensajeTipoFromString(data['mensaje']['tipo']);

    if(mensajeTipo == MensajeTipo.NORMAL){
      msg = data['mensaje']['texto'] ?? ""; // Los MensajeTipo que no reconoce son devueltos como NORMAL
    } else if(mensajeTipo == MensajeTipo.GRUPO_INGRESO){
      msg = "Ingresó al chat.";
    } else if(mensajeTipo == MensajeTipo.GRUPO_SALIDA){
      msg = "Salió del chat.";
    } else if(mensajeTipo == MensajeTipo.GRUPO_ELIMINAR_USUARIO){
      msg = "Eliminó un usuario del chat.";
    } else if(mensajeTipo == MensajeTipo.GRUPO_ENCUENTRO_FECHA){
      msg = "Cambió la fecha de encuentro.";
    } else if(mensajeTipo == MensajeTipo.GRUPO_ENCUENTRO_LINK){
      msg = "Cambió el link de encuentro.";
    } else if(mensajeTipo == MensajeTipo.PROPINA_STICKER){
      msg = "Envió un sticker.";
    }

    if(chats.length == 0){

      if(isChatGrupal){

        title = 'Chat de actividad'; //data['actividad']['titulo'];
        description = '${data['mensaje']['autor_usuario']['nombre_completo']}: $msg';

      } else {

        title = data['mensaje']['autor_usuario']['nombre_completo'];
        description = msg;

      }

    } else {

      bool chatNuevo = true;

      for(var i = 0; i < chats.length; i++){
        var chat = chats[i];
        if(chat['id'] == data['chat']['id'].toString()){
          chatNuevo = false;
          break;
        }
      }

      int numChats = chats.length;
      if(chatNuevo){
        numChats++;
      }

      if(numChats == 1){
        int num = notificacionesActuales['mensajes_privados']['chats'][0]['num_mensajes'];
        num++;

        if(isChatGrupal){
          title = 'Chat de actividad: $num mensajes nuevos';
          description = '${data['mensaje']['autor_usuario']['nombre_completo']}: $msg';
        } else {
          title = '${data['mensaje']['autor_usuario']['nombre_completo']}: $num mensajes nuevos';
          description = msg;
        }

      } else {

        title = 'Mensajes nuevos de $numChats conversaciones';
        if(isChatGrupal){
          description = 'Chat de actividad: $msg';
        } else {
          description = '${data['mensaje']['autor_usuario']['nombre_completo']}: $msg';
        }

      }

      if(isChatGrupal && !chatNuevo){
        conSonido = false;
      }
    }

    await _sumarLocalNotificationChats(prefs, data);


    String payload = jsonEncode({
      'screen' : 'mensajes_page',
      'data' : ''
    });

    if(conSonido){
      await _showNotificationWithSound(_localNotificationIdChats, title, description, payload);
    } else {
      await _showNotificationWithoutSound(_localNotificationIdChats, title, description, payload);
    }
  }
  */
}