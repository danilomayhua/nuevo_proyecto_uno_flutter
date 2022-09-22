import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class SettingsUsernamePage extends StatefulWidget {
  const SettingsUsernamePage({Key? key}) : super(key: key);

  @override
  State<SettingsUsernamePage> createState() => _SettingsUsernamePageState();
}

class _SettingsUsernamePageState extends State<SettingsUsernamePage> {

  final RegExp _regExpUsername = RegExp(r"^[a-zA-Z\d_]{4,}$");

  final TextEditingController _usernameController = TextEditingController(text: '');
  String? _usernameErrorText;

  final TextEditingController _contrasenaController = TextEditingController(text: '');
  String? _contrasenaErrorText;

  bool _enviando = false;

  String _usernameActual = "";

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _usernameActual = usuarioSesion.username;
      _usernameController.text = usuarioSesion.username;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Usuario"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "Usuario",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _usernameErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _validarUsername(),
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

  void _validarUsername(){
    _usernameErrorText = null;

    _usernameController.text = _usernameController.text.trim();
    if(!_regExpUsername.hasMatch(_usernameController.text)){
      _usernameErrorText = 'Ingrese un usuario válido. Solo acepta letras, números y guion bajo. Mínimo 4 caracteres.';
    }

    if(_usernameErrorText == null){
      // Si permite enviar el mismo usuario actual, va devolver que ya está registrado
      if(_usernameController.text != _usernameActual){
        _showDialogContrasena();
      }
    }

    setState(() {});
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
              const Text("Ingresa tu contraseña actual para guardar los cambios:",
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
              onPressed: _enviando ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _enviando ? null : () => _cambiarUsername(setStateDialog),
              child: const Text('Enviar'),
            ),
          ],
        );
      });
    }, barrierDismissible: false,);
  }

  Future<void> _cambiarUsername(setStateDialog) async {
    _contrasenaErrorText = null;
    if(_contrasenaController.text == ''){ return; }

    setStateDialog(() {
      _enviando = true;
    });

    String username = _usernameController.text;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlConfiguracionCambiarUsername,
      body: {
        "username": username,
        "contrasena": _contrasenaController.text,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _usernameActual = username;
        _usernameController.text = username;

        usuarioSesion.username = username;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

        Navigator.of(context).pop();
        _showSnackBar("¡Cambio realizado!");

      } else {

        if(datosJson['error_tipo'] == 'contrasena'){
          _contrasenaErrorText = 'Contraseña incorrecta.';
        } else if(datosJson['error_tipo'] == 'username_registrado'){
          Navigator.of(context).pop();
          _usernameErrorText = 'El nombre de usuario no está disponible.';
          setState(() {});
        } else {
          Navigator.of(context).pop();
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setStateDialog(() {
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