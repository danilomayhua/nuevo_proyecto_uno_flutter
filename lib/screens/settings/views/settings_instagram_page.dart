import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class SettingsInstagramPage extends StatefulWidget {
  const SettingsInstagramPage({Key? key}) : super(key: key);

  @override
  State<SettingsInstagramPage> createState() => _SettingsInstagramPageState();
}

class _SettingsInstagramPageState extends State<SettingsInstagramPage> {

  final RegExp _regExpInstagram = RegExp(r'^(?!.*\.\.)(?!.*\.$)[^\W][\w.]{0,29}$');

  final TextEditingController _instagramController = TextEditingController(text: '');
  String? _instagramErrorText;

  bool _enviando = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _instagramController.text = usuarioSesion.instagram ?? "";
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Instagram"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            TextField(
              controller: _instagramController,
              decoration: InputDecoration(
                hintText: "Ingresa tu usuario de instagram",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _instagramErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 35,
            ),
            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : () => _cambiarInstagram(),
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

  Future<void> _cambiarInstagram() async {
    _instagramErrorText = null;

    setState(() {
      _enviando = true;
    });

    String instagram = _instagramController.text.trim();
    if(instagram.length > 0 && instagram[0] == '@'){
      instagram = instagram.substring(1);
    }
    _instagramController.text = instagram;
    if(_instagramController.text != "" && !_regExpInstagram.hasMatch(instagram)){
      _instagramErrorText = 'Usuario no válido';
      setState(() {_enviando = false;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCambiarInstagram,
      body: {
        "instagram": instagram
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _instagramController.text = instagram;

        usuarioSesion.instagram = instagram == "" ? null : instagram;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

        _showSnackBar("¡Cambio realizado!");

      } else {
        _showSnackBar("Se produjo un error inesperado");
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