import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [

          const Text("Permitir ubicación",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),

          Expanded(child: Column(children: [
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
          ], mainAxisAlignment: MainAxisAlignment.center,),),

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

  Future<void> _habilitarUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Tienes los servicios de ubicación deshabilitados. Actívalo desde Ajustes.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Los permisos están denegados. Permite la ubicación desde Ajustes en la app.");
      return;
    }

    try {

      // Position position = await Geolocator.getCurrentPosition();
      _continuarRegistro();

    } catch (e){
      //
    }
  }

  void _continuarRegistro(){
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => SignupProfilePage(
          email: widget.email,
          codigo: widget.codigo,
          registroActivadoToken: widget.registroActivadoToken,
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