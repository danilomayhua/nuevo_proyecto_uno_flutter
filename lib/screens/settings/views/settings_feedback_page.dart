import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class SettingsFeedbackPage extends StatefulWidget {
  const SettingsFeedbackPage({Key? key}) : super(key: key);

  @override
  State<SettingsFeedbackPage> createState() => _SettingsFeedbackPageState();
}

class _SettingsFeedbackPageState extends State<SettingsFeedbackPage> {

  final TextEditingController _feedbackController = TextEditingController(text: '');
  String? _feedbackErrorText;

  bool _enviandoFeedback = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comentarios y dudas"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: constants.grey),
                  text: "Comparte tus comentarios, sugerencias o reporta errores en la app a través de nuestro formulario. Si necesitas asistencia o tienes "
                      "consultas específicas, también puedes contactarnos en ",
                  children: [
                    TextSpan(
                      text: "soporte@tenfo.app",
                      style: const TextStyle(color: constants.grey, decoration: TextDecoration.underline,),
                      recognizer: TapGestureRecognizer()..onTap = () async {
                        String urlString = "mailto:soporte@tenfo.app?subject=Consultas sobre Tenfo";
                        Uri url = Uri.parse(urlString);

                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication,);
                        } catch (e){
                          throw 'Could not launch $urlString';
                        }
                      },
                    ),
                    const TextSpan(
                      text: " ¡Tu opinión es fundamental para nosotros!",
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24,),

            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: "Escribe un comentario sobre la app...",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _feedbackErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 2000,
              minLines: 5,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviandoFeedback ? null : () => _enviarFeedback(),
                child: const Text("Enviar"),
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

  Future<void> _enviarFeedback() async {
    _feedbackErrorText = null;

    setState(() {
      _enviandoFeedback = true;
    });


    _feedbackController.text = _feedbackController.text.trim();
    String feedbackText = _feedbackController.text;
    if(feedbackText == ''){
      setState(() {_enviandoFeedback = false;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCrearFeedback,
      body: {
        "feedback_texto": feedbackText
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _feedbackController.text = '';

        _showSnackBar("¡Comentario enviado! Gracias por tu contribución.");

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoFeedback = false;
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