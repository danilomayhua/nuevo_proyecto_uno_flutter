import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tenfo/models/signup_permisos_estado.dart';
import 'package:tenfo/screens/signup/views/signup_profile_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SignupLocationPage extends StatefulWidget {
  const SignupLocationPage({Key? key, required this.email,
    required this.codigo, required this.registroActivadoToken}) : super(key: key);

  final String email;
  final String codigo;
  final String registroActivadoToken;

  @override
  State<SignupLocationPage> createState() => _SignupLocationPageState();
}

class _SignupLocationPageState extends State<SignupLocationPage> {

  bool _isNotificacionesPushHabilitado = false;
  bool _loadingNotificacionesPushHabilitado = false;

  bool _isAvailableBotonOmitir = false;

  SignupPermisosEstado _signupPermisosEstado = SignupPermisosEstado(
    isPermisoUbicacionAceptado: false,
    isPermisoNotificacionesAceptado: false,
    isRequierePermisoNotificaciones: false,
  );

  @override
  void initState() {
    super.initState();

    _isNotificacionesPushHabilitado = false;
    _loadingNotificacionesPushHabilitado = true;
    _showContenido();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: BackButton(
          onPressed: (){
            _handleBack();
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: _loadingNotificacionesPushHabilitado ? const Center(child: CircularProgressIndicator(),) : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [

          const Text("Permitir ubicación",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),

          Expanded(
            child: Center(child: SingleChildScrollView(
              child: _isNotificacionesPushHabilitado
                  ? _contenidoSinSolicitarNotificacionesPush()
                  : _contenidoConSolicitarNotificacionesPush(),
            ),),
          ),

          // height es la suma del appBar y el primer texto. Lo hace ver más centrado al Expanded.
          const SizedBox(height: (24 + kToolbarHeight),),
        ],),
      ),
    );

    return WillPopScope(
      child: child,
      onWillPop: (){
        _handleBack();
        return Future.value(false);
      },
    );
  }

  void _handleBack(){
    _showDialogCancelarRegistro();
  }

  void _showDialogCancelarRegistro() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("¿Estás seguro de que quieres cancelar el registro?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                  builder: (context) => const WelcomePage()
              ), (root) => false);
            },
            child: const Text('Eliminar registro', style: TextStyle(color: constants.redAviso),),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Continuar registro'),
          ),
        ],
      );
    });
  }


  Future<void> _showContenido() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
      if(settings.authorizationStatus == AuthorizationStatus.authorized){
        _isNotificacionesPushHabilitado = true;
      }
    } catch(e){
      // Captura error, por si surge algun posible error con FirebaseMessaging
    }

    if(_isNotificacionesPushHabilitado){
      _signupPermisosEstado.isPermisoUbicacionAceptado = false;
      _signupPermisosEstado.isPermisoNotificacionesAceptado = true;
      _signupPermisosEstado.isRequierePermisoNotificaciones = false;
    } else {
      _signupPermisosEstado.isPermisoUbicacionAceptado = false;
      _signupPermisosEstado.isPermisoNotificacionesAceptado = false;
      _signupPermisosEstado.isRequierePermisoNotificaciones = true;
    }

    _loadingNotificacionesPushHabilitado = false;
    setState(() {});
  }

  Widget _contenidoConSolicitarNotificacionesPush(){
    return Column(children: [
      Row(children: [
        const Icon(Icons.location_on, size: 40, color: constants.blackGeneral,),
        const SizedBox(width: 16,),
        Expanded(child: Text(
          'Es necesario permitir ubicación para ver actividades de tu ciudad y al crear tus actividades. '
              'Tu ubicación siempre será privada y nunca será compartida con otros usuarios.',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[700],
            height: 1.2,
          ),
        ),),
      ], crossAxisAlignment: CrossAxisAlignment.start,),
      const SizedBox(height: 24,),
      Row(children: [
        const Icon(Icons.notifications, size: 40, color: constants.blackGeneral,),
        const SizedBox(width: 16,),
        Expanded(child: Text(
          'Permite las notificaciones para enterarte cuando ingreses a una actividad, '
              'cuando alguien ingrese a tus actividades o cuando te agregan nuevos amigos.',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[700],
            height: 1.2,
          ),
        ),),
      ], crossAxisAlignment: CrossAxisAlignment.start,),
      const SizedBox(height: 24,),
      Container(
        constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _habilitarUbicacion();
          },
          child: const Text('Continuar'),
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
          ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
        ),
      ),

      if(_isAvailableBotonOmitir)
        ...[
          const SizedBox(height: 16,),
          TextButton(
            onPressed: (){
              _continuarRegistro();
            },
            child: const Text("Omitir este paso"),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 12,),
            ),
          ),
        ],
    ], mainAxisAlignment: MainAxisAlignment.center,);
  }

  Widget _contenidoSinSolicitarNotificacionesPush(){
    return Column(children: [
      const Icon(Icons.location_on, size: 50.0, color: constants.grey,),
      const SizedBox(height: 15.0,),
      Text(
        'Es necesario permitir ubicación para ver actividades de tu ciudad y al crear tus actividades. '
            'Tu ubicación siempre será privada y nunca será compartida con otros usuarios.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.grey[700],
        ),
      ),
      const SizedBox(height: 15.0,),
      Container(
        constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _habilitarUbicacion();
          },
          child: const Text('Permitir ubicación'),
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
          ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
        ),
      ),
      const SizedBox(height: 16,),
      TextButton(
        onPressed: (){
          _continuarRegistro();
        },
        child: const Text("Omitir este paso"),
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 12,),
        ),
      ),
    ], mainAxisAlignment: MainAxisAlignment.center,);
  }


  Future<void> _habilitarUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Tienes los servicios de ubicación deshabilitados. Actívalo desde Ajustes.");
      _habilitarNotificacionesPush(false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _habilitarNotificacionesPush(false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Los permisos están denegados. Permite la ubicación desde Ajustes en la app.");
      _habilitarNotificacionesPush(false);
      return;
    }

    _habilitarNotificacionesPush(true);
  }

  Future<void> _habilitarNotificacionesPush(bool isUbicacionHabilitado) async {
    try {
      // Permisos para iOS y para Android 13+
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();

      if(settings.authorizationStatus != AuthorizationStatus.authorized || !isUbicacionHabilitado){
        _signupPermisosEstado.isPermisoUbicacionAceptado = isUbicacionHabilitado;
        _signupPermisosEstado.isPermisoNotificacionesAceptado = settings.authorizationStatus == AuthorizationStatus.authorized;

        _isAvailableBotonOmitir = true;
        setState(() {});
        return;
      }
    } catch(e){
      // Captura error, por si surge algun posible error con FirebaseMessaging
    }

    if(!isUbicacionHabilitado){
      _signupPermisosEstado.isPermisoUbicacionAceptado = false;
      _signupPermisosEstado.isPermisoNotificacionesAceptado = true;

      _isAvailableBotonOmitir = true;
      setState(() {});
      return;
    }

    _signupPermisosEstado.isPermisoUbicacionAceptado = true;
    _signupPermisosEstado.isPermisoNotificacionesAceptado = true;
    _continuarRegistro();
  }

  void _continuarRegistro(){
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => SignupProfilePage(
          email: widget.email,
          codigo: widget.codigo,
          registroActivadoToken: widget.registroActivadoToken,
          signupPermisosEstado: _signupPermisosEstado,
        )
    ));
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}