import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/screens/signup/views/signup_not_available_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SignupSendUniversityPage extends StatefulWidget {
  const SignupSendUniversityPage({Key? key}) : super(key: key);

  @override
  State<SignupSendUniversityPage> createState() => _SignupSendUniversityPageState();
}

class _SignupSendUniversityPageState extends State<SignupSendUniversityPage> {

  bool _enviandoUniversidad = false;
  final TextEditingController _universidadController = TextEditingController();
  String? _universidadErrorText;

  @override
  void initState() {
    super.initState();

    _universidadController.text = '';
  }

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

            const Text("Escribe tu universidad",
              style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
            ),
            const SizedBox(height: 24,),

            const SizedBox(height: 16,),
            TextField(
              controller: _universidadController,
              decoration: InputDecoration(
                hintText: "Nombre de universidad",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _universidadErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 50,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16,),
            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviandoUniversidad ? null : () => _enviarUniversidad(),
                child: const Text("Continuar"),
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

  Future<void> _enviarUniversidad() async {
    _universidadErrorText = null;

    setState(() {
      _enviandoUniversidad = true;
    });

    String universidad = _universidadController.text.trim();
    if(universidad.isEmpty){
      _universidadErrorText = 'Escribe tu universidad.';
      setState(() {_enviandoUniversidad = false;});
      return;
    }

    var response = await HttpService.httpPost(
      url: constants.urlRegistroSolicitarUniversidad,
      body: {
        "universidad_texto": universidad,
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => const SignupNotAvailablePage(
              isUniversidadNoDisponible: true,
            ),
        ));

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoUniversidad = false;
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