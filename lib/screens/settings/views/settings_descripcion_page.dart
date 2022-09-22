import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class SettingsDescripcionPage extends StatefulWidget {
  const SettingsDescripcionPage({Key? key}) : super(key: key);

  @override
  State<SettingsDescripcionPage> createState() => _SettingsDescripcionPageState();
}

class _SettingsDescripcionPageState extends State<SettingsDescripcionPage> {

  final TextEditingController _descripcionController = TextEditingController(text: '');
  String? _descripcionErrorText;

  bool _enviandoDescripcion = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _descripcionController.text = usuarioSesion.descripcion ?? "";
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Descripción"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            TextField(
              controller: _descripcionController,
              decoration: InputDecoration(
                hintText: "Por ej. ¿Qué estás estudiando?",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _descripcionErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 100,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviandoDescripcion ? null : () => _cambiarDescripcion(),
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

  Future<void> _cambiarDescripcion() async {
    _descripcionErrorText = null;

    setState(() {
      _enviandoDescripcion = true;
    });

    _descripcionController.text = _descripcionController.text.trim();
    String descripcion = _descripcionController.text;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCambiarDescripcion,
      body: {
        "descripcion": descripcion
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _descripcionController.text = descripcion;

        usuarioSesion.descripcion = descripcion == "" ? null : descripcion;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

        _showSnackBar("¡Cambio realizado!");

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoDescripcion = false;
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