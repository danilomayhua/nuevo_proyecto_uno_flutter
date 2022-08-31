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

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

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
      body: SafeArea(child: Column(
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              hintText: "Email o username",
              border: OutlineInputBorder(),
            ),
            maxLength: 200,
            minLines: 1,
            maxLines: 1,
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _contrasenaController,
            decoration: const InputDecoration(
              hintText: "Contraseña",
              border: OutlineInputBorder(),
            ),
            maxLength: 200,
            minLines: 1,
            maxLines: 1,
            keyboardType: TextInputType.visiblePassword,
            obscureText: true,
          ),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (){
                _iniciarSesion();
              },
              child: const Text("Iniciar sesión"),
            ),
          ),
        ],
      ),),
    );
  }

  Future<void> _iniciarSesion() async {
    String? firebaseToken;
    try {
      firebaseToken = await FirebaseMessaging.instance.getToken();
    } catch(e) {
      //
    }

    var response = await HttpService.httpPost(
      url: constants.urlLogin,
      body: {
        "username": _usernameController.text.trim(),
        "contrasena": _contrasenaController.text.trim(),
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
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    /*Map<String, dynamic> responseJson = jsonDecode(
        '{'
          '"error": false,'
          '"data": {'
            '"token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c3VhcmlvX2lkIjoiZmJlODcxNmEyYmRkNDhiOTk3NzA0NjY5MWFiOTc0ZjQiLCJ0ZXh0X3JhbmRvbSI6IjFlNjA3NmE4ZmI1MWNmNDA3Y2U2NmRiOWU1OGQwMDI5ZTc2ZjU4Y2I0MjgyZGVkODhmZTBjNGZiMzMxMGZiNzQzNmI4NzQxNWFjNGY1NDhjIiwiaWF0IjoxNjUwOTQ0MjIwfQ.uQYGMJnfeQX4d_a2cQLD7FXc1FeDGs84IFRQah2k_OU",'
            '"usuario": {'
              '"id": "fbe8716a2bdd48b9977046691ab974f4",'
              '"nombre": "Armando",'
              '"apellido": "Casas",'
              '"username": "armandocasas",'
              '"foto_url": "/images/usuario_test/foto5.webp",'
              '"email": "armandocasas@gmail.com",'
              '"intereses": [1, 4, 5],'
              '"is_admin": true'
            '}'
          '}'
        '}'
    );*/
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}