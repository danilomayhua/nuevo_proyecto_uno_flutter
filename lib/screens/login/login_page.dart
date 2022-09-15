import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  bool _enviando = false;

  final TextEditingController _usernameController = TextEditingController();
  String? _usernameErrorText;
  final TextEditingController _contrasenaController = TextEditingController();
  String? _contrasenaErrorText;
  bool _isContrasenaOculta = true;

  @override
  void initState() {
    super.initState();

    _usernameController.text = '';
    _contrasenaController.text = '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

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
            Container(
              width: 160,
              child: Image.asset("assets/logo_letras_tenfo.png"),
            ),

            const SizedBox(height: 48,),

            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "Usuario o email",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _usernameErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16,),
            TextField(
              controller: _contrasenaController,
              decoration: InputDecoration(
                hintText: "Contraseña",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _contrasenaErrorText,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  icon: _isContrasenaOculta
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                  onPressed: () {
                    _isContrasenaOculta = !_isContrasenaOculta;
                    setState(() {});
                  },
                ),
              ),
              maxLength: 60,
              keyboardType: TextInputType.visiblePassword,
              obscureText: _isContrasenaOculta,
            ),
            const SizedBox(height: 24,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : () => _iniciarSesion(),
                child: const Text("Iniciar sesión"),
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

  Future<void> _iniciarSesion() async {
    _usernameErrorText = null;
    _contrasenaErrorText = null;

    setState(() {
      _enviando = true;
    });

    String username = _usernameController.text.trim();
    String contrasena = _contrasenaController.text;
    if(username.isEmpty || contrasena.isEmpty){
      setState(() {_enviando = false;});
      return;
    }
    String? firebaseToken;
    try {
      firebaseToken = await FirebaseMessaging.instance.getToken();
    } catch(e) {
      //
    }

    var response = await HttpService.httpPost(
      url: constants.urlLogin,
      body: {
        "username": username,
        "contrasena": contrasena,
        "firebase_token": firebaseToken ?? "",
      },
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        UsuarioSesion usuarioSesion = UsuarioSesion.fromJson(datosJson['data']);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));
        prefs.setBool(SharedPreferencesKeys.isLoggedIn, true);

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) => const PrincipalPage()
        ), (root) => false);

      } else {

        if(datosJson['error_tipo'] == 'contrasena'){
          _contrasenaErrorText = 'Contraseña incorrecta.';
        } else if(datosJson['error_tipo'] == 'usuario_inexistente'){
          _usernameErrorText = 'El usuario o email ingresado no existe.';
        } else if(datosJson['error_tipo'] == 'segundos'){
          _usernameErrorText = 'Tienes que esperar unos segundos para volver a iniciar sesión.';
        } else if(datosJson['error_tipo'] == 'ip'){
          _usernameErrorText = 'Usted ha sido bloqueado temporalmente para ingresar con esta cuenta.';
        } else if(datosJson['error_tipo'] == 'inactivo'){
          _usernameErrorText = 'El usuario ingresado está dado de baja.';
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviando = false;
    });
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}