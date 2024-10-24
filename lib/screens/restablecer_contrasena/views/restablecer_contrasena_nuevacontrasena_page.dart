import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/signup/views/signup_picture_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class RestablecerContrasenaNuevacontrasenaPage extends StatefulWidget {
  const RestablecerContrasenaNuevacontrasenaPage({Key? key, required this.medioContacto, required this.codigo}) : super(key: key);

  final String medioContacto;
  final String codigo;

  @override
  State<RestablecerContrasenaNuevacontrasenaPage> createState() => _RestablecerContrasenaNuevacontrasenaPageState();
}

class _RestablecerContrasenaNuevacontrasenaPageState extends State<RestablecerContrasenaNuevacontrasenaPage> {

  final RegExp _regExp1Contrasena = RegExp(r"[a-zA-Z]");
  final RegExp _regExp2Contrasena = RegExp(r"[\d]");

  final TextEditingController _contrasena1Controller = TextEditingController(text: '');
  String? _contrasena1ErrorText;
  bool _isContrasena1Oculta = true;
  final TextEditingController _contrasena2Controller = TextEditingController(text: '');
  String? _contrasena2ErrorText;
  bool _isContrasena2Oculta = true;

  bool _enviando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            const SizedBox(height: 16,),

            const Text("Cambiar contraseña",
              style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
            ),
            const SizedBox(height: 24,),

            TextField(
              controller: _contrasena1Controller,
              decoration: InputDecoration(
                hintText: "Nueva contraseña",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _contrasena1ErrorText,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  icon: _isContrasena1Oculta
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                  onPressed: () {
                    _isContrasena1Oculta = !_isContrasena1Oculta;
                    setState(() {});
                  },
                ),
              ),
              maxLength: 60,
              keyboardType: TextInputType.visiblePassword,
              obscureText: _isContrasena1Oculta,
            ),
            const SizedBox(height: 16,),
            TextField(
              controller: _contrasena2Controller,
              decoration: InputDecoration(
                hintText: "Repetir contraseña",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _contrasena2ErrorText,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  icon: _isContrasena2Oculta
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                  onPressed: () {
                    _isContrasena2Oculta = !_isContrasena2Oculta;
                    setState(() {});
                  },
                ),
              ),
              maxLength: 60,
              keyboardType: TextInputType.visiblePassword,
              obscureText: _isContrasena2Oculta,
            ),
            const SizedBox(height: 24,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : () => _validarContrasena(),
                child: const Text("Guardar"),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),
            const SizedBox(height: 16,),

          ],),
        ),
      ),
    );
  }

  void _validarContrasena(){
    if(_enviando) return;
    _enviando = true;


    _contrasena1ErrorText = null;
    _contrasena2ErrorText = null;

    if(_contrasena1Controller.text.length < 8){
      _contrasena1ErrorText = 'Ingrese más de 8 caracteres.';
    } else if(!_regExp1Contrasena.hasMatch(_contrasena1Controller.text) || !_regExp2Contrasena.hasMatch(_contrasena1Controller.text)){
      _contrasena1ErrorText = 'Ingrese mínimo una letra y un número.';
    } else if(_contrasena1Controller.text != _contrasena2Controller.text){
      _contrasena1ErrorText = 'Las contraseñas no coinciden.';
      _contrasena2ErrorText = 'Las contraseñas no coinciden.';
    }

    if(_contrasena1ErrorText == null && _contrasena2ErrorText == null){
      _cambiarContrasena();
    } else {
      _enviando = false;
    }

    setState(() {});
  }

  Future<void> _cambiarContrasena() async {
    setState(() {
      _enviando = true;
    });

    String contrasena = _contrasena1Controller.text;

    var response = await HttpService.httpPost(
      url: constants.urlRestablecerContrasena,
      body: {
        "medioContacto": widget.medioContacto,
        "codigo": widget.codigo,
        "contrasena_nueva": contrasena,
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        //_contrasena1Controller.text = '';
        //_contrasena2Controller.text = '';
        String username = datosJson['data']['username'];

        _showSnackBar("¡Contraseña cambiada!\nIniciando sesión...");
        await _iniciarSesion(username, contrasena);

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviando = false;
    });
  }

  Future<void> _iniciarSesion(username, contrasena) async {
    /*setState(() {
      _enviando = true;
    });*/

    String? firebaseToken;
    try {
      firebaseToken = await FirebaseMessaging.instance.getToken();
    } catch(e) {
      //
    }
    String origenPlataforma = "android";
    if(Platform.isIOS){
      origenPlataforma = "iOS";
    }

    var response = await HttpService.httpPost(
      url: constants.urlLogin,
      body: {
        "username": username,
        "contrasena": contrasena,
        "firebase_token": firebaseToken ?? "",
        "plataforma": origenPlataforma,
      },
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        UsuarioSesion usuarioSesion = UsuarioSesion.fromJson(datosJson['data']);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));
        prefs.setBool(SharedPreferencesKeys.isLoggedIn, true);

        if(usuarioSesion.isUsuarioSinFoto){

          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (context) => const SignupPicturePage(isFromSignup: false,)
          ), (root) => false);

        } else {

          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (context) => const PrincipalPage()
          ), (root) => false);

        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    /*setState(() {
      _enviando = false;
    });*/
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}