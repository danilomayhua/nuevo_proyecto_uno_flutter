import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/screens/signup/views/signup_location_page.dart';
import 'package:tenfo/screens/signup/views/signup_send_university_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_no_usuario.dart';
import 'package:tenfo/utilities/universidades.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupUniversityPage extends StatefulWidget {
  const SignupUniversityPage({Key? key}) : super(key: key);

  @override
  State<SignupUniversityPage> createState() => _SignupUniversityPageState();
}

class _SignupUniversityPageState extends State<SignupUniversityPage> {

  List<String> _universidadesId = [];

  @override
  void initState() {
    super.initState();

    _universidadesId = Universidades.getListaUniversidades();
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

            const Text("Elige tu universidad",
              style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
            ),
            const SizedBox(height: 16,),

            const Align(
              alignment: Alignment.center,
              child: Text("Este valor no se podrá cambiar.",
                style: TextStyle(color: constants.grey,),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24,),

            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _universidadesId.length + 1,
              itemBuilder: (context, index) {

                if(index == _universidadesId.length){
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8,),
                    child: _buildOtraUniversidad(),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8,),
                  child: _buildUniversidad(_universidadesId[index]),
                );
              },
            ),

            const SizedBox(height: 40,),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16,),
              alignment: Alignment.center,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
                  text: "Al continuar, aceptas los ",
                  children: [
                    TextSpan(
                      text: "Términos",
                      style: const TextStyle(decoration: TextDecoration.underline,),
                      recognizer: TapGestureRecognizer()..onTap = () async {
                        String urlString = "https://tenfo.app/politica.html";
                        Uri url = Uri.parse(urlString);

                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication,);
                        } catch (e){
                          throw 'Could not launch $urlString';
                        }
                      },
                    ),
                    const TextSpan(
                      text: " y ",
                    ),
                    TextSpan(
                      text: "Política de Privacidad",
                      style: const TextStyle(decoration: TextDecoration.underline,),
                      recognizer: TapGestureRecognizer()..onTap = () async {
                        String urlString = "https://tenfo.app/politica.html#politica-privacidad";
                        Uri url = Uri.parse(urlString);

                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication,);
                        } catch (e){
                          throw 'Could not launch $urlString';
                        }
                      },
                    ),
                    const TextSpan(
                      text: " y confirmas haberlos leído.",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16,),

          ],),
        ),
      ),
    );
  }

  Widget _buildUniversidad(String universidadId){
    return ListTile(
      title: Text(Universidades.getNombre(universidadId),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(Universidades.getDescripcion(universidadId),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: const CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(Icons.school_outlined, color: constants.blackGeneral,),
      ),
      onTap: (){
        // Envia historial no usuario
        _enviarHistorialNoUsuario(HistorialNoUsuario.getRegistroUniversidadElegir(universidadId));

        Navigator.push(context, MaterialPageRoute(
            builder: (context) => SignupLocationPage(
              universidadId: universidadId,
            )
        ));
      },
    );
  }

  Widget _buildOtraUniversidad(){
    return ListTile(
      title: const Text("Otra universidad",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: const CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(Icons.school_outlined, color: constants.blackGeneral,),
      ),
      onTap: (){
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => const SignupSendUniversityPage()
        ));
      },
    );
  }

  Future<void> _enviarHistorialNoUsuario(Map<String, dynamic> historialNoUsuario) async {
    //setState(() {});

    var response = await HttpService.httpPost(
      url: constants.urlCrearHistorialNoUsuario,
      body: {
        "historiales_no_usuario": [historialNoUsuario],
      },
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){
        //
      } else {
        //_showSnackBar("Se produjo un error inesperado");
      }
    }

    //setState(() {});
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}