import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class SettingsNombrePage extends StatefulWidget {
  const SettingsNombrePage({Key? key}) : super(key: key);

  @override
  State<SettingsNombrePage> createState() => _SettingsNombrePageState();
}

class _SettingsNombrePageState extends State<SettingsNombrePage> {

  final RegExp _regExpNombre = RegExp(r"^[a-zA-ZñÑáéíóúÁÉÍÓÚäëïöüÄËÏÖÜ'\s]+$");

  final TextEditingController _nombreController = TextEditingController(text: '');
  String? _nombreErrorText;
  final TextEditingController _apellidoController = TextEditingController(text: '');
  String? _apellidoErrorText;

  final TextEditingController _contrasenaController = TextEditingController(text: '');
  String? _contrasenaErrorText;

  bool _enviando = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _nombreController.text = usuarioSesion.nombre;
      _apellidoController.text = usuarioSesion.apellido;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nombre"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                hintText: "Nombre",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _nombreErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16,),
            TextField(
              controller: _apellidoController,
              decoration: InputDecoration(
                hintText: "Apellido",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _apellidoErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _validarNombreCompleto(),
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

  void _validarNombreCompleto(){
    _nombreErrorText = null;
    _apellidoErrorText = null;

    _nombreController.text = _nombreController.text.trim();
    if(!_regExpNombre.hasMatch(_nombreController.text)){
      _nombreErrorText = 'Ingrese un nombre válido.';
    }

    _apellidoController.text = _apellidoController.text.trim();
    if(!_regExpNombre.hasMatch(_apellidoController.text)){
      _apellidoErrorText = 'Ingrese un apellido válido.';
    }

    if(_nombreErrorText == null && _apellidoErrorText == null){
      _showDialogContrasena();
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
              onPressed: _enviando ? null : () => _cambiarNombre(setStateDialog),
              child: const Text('Enviar'),
            ),
          ],
        );
      });
    }, barrierDismissible: false,);
  }

  Future<void> _cambiarNombre(setStateDialog) async {
    _contrasenaErrorText = null;
    if(_contrasenaController.text == ''){ return; }

    setStateDialog(() {
      _enviando = true;
    });

    String nombre = _nombreController.text;
    String apellido = _apellidoController.text;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlConfiguracionCambiarNombre,
      body: {
        "nombre": nombre,
        "apellido": apellido,
        "contrasena": _contrasenaController.text,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _nombreController.text = nombre;
        _apellidoController.text = apellido;

        usuarioSesion.nombre = nombre;
        usuarioSesion.apellido = apellido;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

        Navigator.of(context).pop();
        _showSnackBar("¡Cambio realizado!");

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