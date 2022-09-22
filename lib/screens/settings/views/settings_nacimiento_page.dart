import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class SettingsNacimientoPage extends StatefulWidget {
  const SettingsNacimientoPage({Key? key}) : super(key: key);

  @override
  State<SettingsNacimientoPage> createState() => _SettingsNacimientoPageState();
}

class _SettingsNacimientoPageState extends State<SettingsNacimientoPage> {

  DateTime _nacimientoDateTime = DateTime(DateTime.now().year - 21);
  String _nacimientoFechaString = "";
  String? _nacimientoErrorText;

  final TextEditingController _contrasenaController = TextEditingController(text: '');
  String? _contrasenaErrorText;

  bool _enviando = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _nacimientoDateTime = usuarioSesion.nacimiento_fecha;
      _actualizarFechaString();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cumpleaños"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            GestureDetector(
              onTap: (){
                _showDialogEditarNacimiento();
              },
              child: InputDecorator(
                isEmpty: _nacimientoFechaString == "" ? true : false,
                decoration: InputDecoration(
                  hintText: "dd/mm/aaaa",
                  border: OutlineInputBorder(),
                  //counterText: '',
                  errorText: _nacimientoErrorText,
                  errorMaxLines: 2,
                ),
                child: Text(_nacimientoFechaString,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showDialogContrasena(),
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

  void _actualizarFechaString(){
    String year = '${_nacimientoDateTime.year}';
    String mes = _nacimientoDateTime.month < 10 ? '0${_nacimientoDateTime.month}' : '${_nacimientoDateTime.month}';
    String dia = _nacimientoDateTime.day < 10 ? '0${_nacimientoDateTime.day}' : '${_nacimientoDateTime.day}';

    _nacimientoFechaString = "$dia/$mes/$year";
  }

  void _showDialogEditarNacimiento(){
    showModalBottomSheet(context: context, builder: (BuildContext builder) {
      return Container(
        height: MediaQuery.of(context).copyWith().size.height / 3,
        color: Colors.white,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (picked) {
            if (picked != null && picked != _nacimientoDateTime){
              _nacimientoDateTime = picked;
              _actualizarFechaString();

              setState(() {});
            }
          },
          initialDateTime: _nacimientoDateTime,
          minimumYear: 1920,
          maximumYear: DateTime.now().year - 17,
        ),
      );
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
              onPressed: _enviando ? null : () => _cambiarNacimiento(setStateDialog),
              child: const Text('Enviar'),
            ),
          ],
        );
      });
    }, barrierDismissible: false,);
  }

  Future<void> _cambiarNacimiento(setStateDialog) async {
    _contrasenaErrorText = null;
    if(_contrasenaController.text == ''){ return; }

    setStateDialog(() {
      _enviando = true;
    });

    String nacimiento = _nacimientoDateTime.millisecondsSinceEpoch.toString();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlConfiguracionCambiarNacimiento,
      body: {
        "nacimiento_fecha": nacimiento,
        "contrasena": _contrasenaController.text,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _nacimientoDateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(nacimiento), isUtc: true,);

        usuarioSesion.nacimiento_fecha = DateTime.fromMillisecondsSinceEpoch(int.parse(nacimiento), isUtc: true,);
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