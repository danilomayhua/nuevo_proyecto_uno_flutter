import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SettingsContrasenaPage extends StatefulWidget {
  const SettingsContrasenaPage({Key? key}) : super(key: key);

  @override
  State<SettingsContrasenaPage> createState() => _SettingsContrasenaPageState();
}

class _SettingsContrasenaPageState extends State<SettingsContrasenaPage> {

  final RegExp _regExp1Contrasena = RegExp(r"[a-zA-Z]");
  final RegExp _regExp2Contrasena = RegExp(r"[\d]");

  final TextEditingController _contrasena1Controller = TextEditingController(text: '');
  String? _contrasena1ErrorText;
  bool _isContrasena1Oculta = true;
  final TextEditingController _contrasena2Controller = TextEditingController(text: '');
  String? _contrasena2ErrorText;
  bool _isContrasena2Oculta = true;

  final TextEditingController _contrasenaActualController = TextEditingController(text: '');
  String? _contrasenaActualErrorText;

  bool _enviando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contraseña"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

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
            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _validarContrasena(),
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
      _showDialogContrasena();
    }

    setState(() {});
  }

  void _showDialogContrasena(){
    _contrasenaActualController.text = "";
    _contrasenaActualErrorText = null;

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
                controller: _contrasenaActualController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Contraseña",
                  counterText: '',
                  border: const OutlineInputBorder(),
                  errorText: _contrasenaActualErrorText,
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
              onPressed: _enviando ? null : () => _cambiarContrasena(setStateDialog),
              child: const Text('Enviar'),
            ),
          ],
        );
      });
    }, barrierDismissible: false,);
  }

  Future<void> _cambiarContrasena(setStateDialog) async {
    _contrasenaActualErrorText = null;
    if(_contrasenaActualController.text == ''){ return; }

    setStateDialog(() {
      _enviando = true;
    });

    String contrasena = _contrasena1Controller.text;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlConfiguracionCambiarContrasena,
      body: {
        "contrasena_nueva": contrasena,
        "contrasena": _contrasenaActualController.text,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _contrasena1Controller.text = '';
        _contrasena2Controller.text = '';

        Navigator.of(context).pop();
        _showSnackBar("¡Cambio realizado!");

      } else {

        if(datosJson['error_tipo'] == 'contrasena'){
          _contrasenaActualErrorText = 'Contraseña incorrecta.';
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