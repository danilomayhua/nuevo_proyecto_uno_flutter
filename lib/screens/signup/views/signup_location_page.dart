import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tenfo/models/signup_permisos_estado.dart';
import 'package:tenfo/screens/signup/views/signup_not_available_page.dart';
import 'package:tenfo/screens/signup/views/signup_phone_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/services/location_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SignupLocationPage extends StatefulWidget {
  const SignupLocationPage({Key? key, required this.universidadId}) : super(key: key);

  final String universidadId;

  @override
  State<SignupLocationPage> createState() => _SignupLocationPageState();
}

class _SignupLocationPageState extends State<SignupLocationPage> {

  bool _isNotificacionesPushHabilitado = false;
  bool _loadingNotificacionesPushHabilitado = false;

  bool _isAvailableBotonOmitir = false;

  SignupPermisosEstado _signupPermisosEstado = SignupPermisosEstado(
    isPermisoUbicacionAceptado: false,
    isPermisoTelefonoContactosAceptado: false,
    isPermisoNotificacionesAceptado: false,
    isRequierePermisoNotificaciones: false,
  );

  bool _enviandoUbicacion = false;

  final LocationService _locationService = LocationService();
  LocationServicePermissionStatus _permissionStatus = LocationServicePermissionStatus.loading;
  LocationServicePosition? _locationServicePosition;

  @override
  void initState() {
    super.initState();

    _isNotificacionesPushHabilitado = false;
    _loadingNotificacionesPushHabilitado = true;
    _cargarNotificacionesPushEstado();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
              child: _contenidoSolicitarUbicacionNotificaciones(),
            ),),
          ),

          // height es la suma del appBar y el primer texto. Lo hace ver más centrado al Expanded.
          const SizedBox(height: (24 + kToolbarHeight),),
        ],),
      ),
    );
  }


  Future<void> _cargarNotificacionesPushEstado() async {
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

  Widget _contenidoSolicitarUbicacionNotificaciones(){
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
          onPressed: _enviandoUbicacion ? null : () => _habilitarNotificacionesPush(),
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
            onPressed: _enviandoUbicacion ? null : () => _cargarUbicacion(),
            child: const Text("Omitir este paso"),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 12,),
            ),
          ),
        ],
    ], mainAxisAlignment: MainAxisAlignment.center,);
  }

  Widget _contenidoSolicitarUbicacion(){
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
          onPressed: _enviandoUbicacion ? null : () => (){},//_habilitarUbicacion(),,
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

  Widget _contenidoSolicitarUbicacionContactos(){
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
        Container(
          width: 40,
          alignment: Alignment.center,
          child: const Icon(Icons.contacts_outlined, size: 28, color: constants.blackGeneral,),
        ),
        const SizedBox(width: 16,),
        Expanded(child: Text(
          'Permite los contactos para poder sugerirte amigos en tu universidad y cocrear actividades fácilmente.',
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
          onPressed: _enviandoUbicacion ? null : () => (){},//_habilitarUbicacion(),
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
            onPressed: _enviandoUbicacion ? null : () => _cargarUbicacion(),
            child: const Text("Omitir este paso"),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 12,),
            ),
          ),
        ],
    ], mainAxisAlignment: MainAxisAlignment.center,);
  }


  Future<void> _habilitarUbicacion(bool isNotificacionesHabilitado) async {

    bool isUbicacionAceptado = true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Tienes los servicios de ubicación deshabilitados. Actívalo desde Ajustes.");
      //_habilitarTelefonoContactos(false);
      //return;

      isUbicacionAceptado = false;

    } else {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          //_habilitarTelefonoContactos(false);
          //return;

          isUbicacionAceptado = false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("Los permisos están denegados. Permite la ubicación desde Ajustes en la app.");
        //_habilitarTelefonoContactos(false);
        //return;

        isUbicacionAceptado = false;
      }
    }

    if(!isUbicacionAceptado || !isNotificacionesHabilitado){
      _signupPermisosEstado.isPermisoUbicacionAceptado = isUbicacionAceptado;
      _signupPermisosEstado.isPermisoNotificacionesAceptado = isNotificacionesHabilitado;

      _isAvailableBotonOmitir = true;
      setState(() {});
      return;
    }

    _signupPermisosEstado.isPermisoUbicacionAceptado = true;
    _signupPermisosEstado.isPermisoNotificacionesAceptado = true;

    //_habilitarTelefonoContactos(true);
    _cargarUbicacion();
  }

  Future<void> _habilitarNotificacionesPush() async {
    if(_isNotificacionesPushHabilitado){
      _habilitarUbicacion(true);
      return;
    }

    try {
      // Permisos para iOS y para Android 13+
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();

      if(settings.authorizationStatus != AuthorizationStatus.authorized){
        _habilitarUbicacion(false);
        return;
      }
    } catch(e){
      // Captura error, por si surge algun posible error con FirebaseMessaging
    }

    _habilitarUbicacion(true);
  }

  Future<void> _habilitarTelefonoContactos(bool isUbicacionHabilitado) async {
    bool permisoTelefonoContactos = false;

    try {

      // TODO : Buscar otro paquete para manejar permisos.

      // No usar "readonly: true", esto genera un error que termina la app.
      // permisoTelefonoContactos = await FlutterContacts.requestPermission(readonly: true);
      permisoTelefonoContactos = await FlutterContacts.requestPermission();

    } catch(e){
      // Captura error, por si surge algun posible error con el paquete
    }

    if (!permisoTelefonoContactos || !isUbicacionHabilitado) {
      _signupPermisosEstado.isPermisoUbicacionAceptado = isUbicacionHabilitado;
      _signupPermisosEstado.isPermisoTelefonoContactosAceptado = permisoTelefonoContactos;

      _isAvailableBotonOmitir = true;
      setState(() {});
      return;
    }

    _signupPermisosEstado.isPermisoUbicacionAceptado = true;
    _signupPermisosEstado.isPermisoTelefonoContactosAceptado = true;

    _cargarUbicacion();
  }

  Future<void> _cargarUbicacion() async {
    _enviandoUbicacion = true;
    setState(() {});

    _permissionStatus = await _locationService.verificarUbicacion();
    if(_permissionStatus == LocationServicePermissionStatus.permitted){

      _locationServicePosition = await _locationService.obtenerUbicacion();
      _verificarUbicacion();

    } else {
      //_enviandoUbicacion = false;
      //setState(() {});
      //_continuarRegistro();


      // Si apreto "Omitir", puede tener la ubicacion no permitida
      // Si no tiene ubicacion permitida, _locationServicePosition es null
      _verificarUbicacion();
    }
  }

  Future<void> _verificarUbicacion() async {
    setState(() {
      _enviandoUbicacion = true;
    });

    var response = await HttpService.httpPost(
      url: constants.urlRegistroVerificarUbicacion,
      body: {
        "ubicacion_latitud": _locationServicePosition?.latitude.toString() ?? "",
        "ubicacion_longitud": _locationServicePosition?.longitude.toString() ?? "",
        "universidad_id": widget.universidadId,

        // Envia datos para analizar comportamiento en historial
        "permiso_ubicacion_aceptado": _signupPermisosEstado.isPermisoUbicacionAceptado ? "SI" : "NO",
        "permiso_telefono_contactos_aceptado": _signupPermisosEstado.isPermisoTelefonoContactosAceptado ? "SI" : "NO",
        "permiso_notificaciones_aceptado": _signupPermisosEstado.isPermisoNotificacionesAceptado ? "SI" : "NO",
        "requiere_permiso_notificaciones": _signupPermisosEstado.isRequierePermisoNotificaciones ? "SI" : "NO",
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _continuarRegistro();

      } else {

        if(datosJson['error_tipo'] == 'ubicacion_no_disponible'){

          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => const SignupNotAvailablePage(
              isUniversidadNoDisponible: false,
            ),
          ));

        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoUbicacion = false;
    });
  }

  void _continuarRegistro(){
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => SignupPhonePage(
          universidadId: widget.universidadId,
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