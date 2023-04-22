import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/screens/signup/signup_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SignupInvitationPage extends StatefulWidget {
  const SignupInvitationPage({Key? key}) : super(key: key);

  @override
  State<SignupInvitationPage> createState() => _SignupInvitationPageState();
}

class _SignupInvitationPageState extends State<SignupInvitationPage> {

  bool _enviandoCodigoInvitacion = false;
  final TextEditingController _codigoInvitacionController = TextEditingController();
  String? _codigoInvitacionErrorText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            const Text("Código de invitación",
              style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
            ),
            const SizedBox(height: 24,),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Escribe el código de invitación que te compartieron:",
                style: TextStyle(color: constants.grey,),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 16,),
            TextField(
              controller: _codigoInvitacionController,
              decoration: InputDecoration(
                hintText: "",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _codigoInvitacionErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 100,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16,),
            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviandoCodigoInvitacion ? null : () => _verificarCodigo(),
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

  Future<void> _verificarCodigo() async {
    _codigoInvitacionErrorText = null;

    setState(() {
      _enviandoCodigoInvitacion = true;
    });

    String codigo = _codigoInvitacionController.text.trim();
    if(codigo.isEmpty){
      _codigoInvitacionErrorText = 'Ingresa un código.';
      setState(() {_enviandoCodigoInvitacion = false;});
      return;
    }

    var response = await HttpService.httpPost(
      url: constants.urlRegistroVerificarInvitacion,
      body: {
        "codigo_invitacion": codigo
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        String actividadTitulo = datosJson['data']['actividad']['titulo'];

        _showDialogActividadInvitado(codigo, actividadTitulo);

      } else {

        if(datosJson['error_tipo'] == 'codigo_invitacion_invalido'){
          _codigoInvitacionErrorText = 'El código de invitación no es válido o ya ha sido utilizado.';
        } else if(datosJson['error_tipo'] == 'codigo_invitacion_no_asignado'){
          _codigoInvitacionErrorText = 'El código fue eliminado antes de crear la actividad o aún no se asignó a una actividad.';
        } else if(datosJson['error_tipo'] == 'actividad_eliminado'){
          _codigoInvitacionErrorText = 'El código fue eliminado.';
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoCodigoInvitacion = false;
    });
  }

  void _showDialogActividadInvitado(String codigoInvitacion, String actividadTitulo){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            Text("Fuiste invitado como co-creador de la actividad \"$actividadTitulo\"\n\n"
                "¡Primero crea tu perfil!",
              style: const TextStyle(color: constants.blackGeneral, fontSize: 16, height: 1.3,),
              textAlign: TextAlign.center,
            ),
          ], mainAxisSize: MainAxisSize.min,),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      );
    }).then((value){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) => SignupPage(codigoInvitacion: codigoInvitacion,)
      ), (route) => false);
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