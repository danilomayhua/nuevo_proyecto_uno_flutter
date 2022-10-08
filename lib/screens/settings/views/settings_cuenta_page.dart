import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SettingsCuentaPage extends StatefulWidget {
  const SettingsCuentaPage({Key? key}) : super(key: key);

  @override
  State<SettingsCuentaPage> createState() => _SettingsCuentaPageState();
}

class _SettingsCuentaPageState extends State<SettingsCuentaPage> {

  final TextEditingController _contrasenaController = TextEditingController(text: '');
  String? _contrasenaErrorText;

  bool _enviandoEliminarCuenta = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cuenta"),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          ListTile(
            title: const Text("Eliminar cuenta", style: TextStyle(color: constants.redAviso),),
            onTap: () {
              _showDialogEliminarCuenta();
            },
            shape: const Border(bottom: BorderSide(color: constants.grey, width: 0.2,),),
          ),
          const SizedBox(height: 16,),
        ],),
      ),
    );
  }

  void _showDialogEliminarCuenta(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Seguro que quieres eliminar tu cuenta?'),
          content: const Text('Al eliminar tu cuenta, no podrás volver acceder y perderás la información dentro.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Eliminar cuenta'),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
              onPressed: (){
                Navigator.pop(context);
                _showDialogContrasena();
              },
            ),
          ],
        );
      });
    });
  }

  void _showDialogContrasena(){
    _contrasenaController.text = "";
    _contrasenaErrorText = null;

    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(children: [
              const SizedBox(width: double.maxFinite,),
              const Text("Ingresa tu contraseña para confirmar:",
                style: TextStyle(fontSize: 12,),
              ),
              const SizedBox(height: 16,),
              TextField(
                controller: _contrasenaController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Contraseña",
                  counterText: '',
                  border: const OutlineInputBorder(),
                  errorText: _contrasenaErrorText,
                  errorMaxLines: 2,
                ),
                maxLength: 60,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                style: const TextStyle(fontSize: 12,),
              ),
            ], mainAxisSize: MainAxisSize.min,),
          ),
          actions: [
            TextButton(
              onPressed: _enviandoEliminarCuenta ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _enviandoEliminarCuenta ? null : () => _eliminarCuenta(setStateDialog),
              child: const Text('Enviar'),
            ),
          ],
        );
      });
    }, barrierDismissible: false,);
  }

  Future<void> _eliminarCuenta(setStateDialog) async {
    _contrasenaErrorText = null;
    if(_contrasenaController.text == ''){ return; }

    setStateDialog(() {
      _enviandoEliminarCuenta = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    // No es necesario enviar firebaseToken (borra todos los tokens)
    String? firebaseToken;
    try {
      firebaseToken = await FirebaseMessaging.instance.getToken();
    } catch(e) {
      //
    }

    var response = await HttpService.httpPost(
      url: constants.urlConfiguracionEliminarCuenta,
      body: {
        "contrasena": _contrasenaController.text,
        "firebase_token": firebaseToken ?? ""
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool logout = await prefs.clear();

        if(logout){
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (context) => const WelcomePage()
          ), (route) => false);
        }

      } else {

        if(datosJson['error_tipo'] == 'contrasena'){
          _contrasenaErrorText = 'Contraseña incorrecta.';
        } else {
          Navigator.of(context).pop();
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setStateDialog(() {
      _enviandoEliminarCuenta = false;
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