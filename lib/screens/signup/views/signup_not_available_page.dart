import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class SignupNotAvailablePage extends StatefulWidget {
  const SignupNotAvailablePage({Key? key, required this.isUniversidadNoDisponible}) : super(key: key);

  final bool isUniversidadNoDisponible;

  @override
  State<SignupNotAvailablePage> createState() => _SignupNotAvailablePageState();
}

class _SignupNotAvailablePageState extends State<SignupNotAvailablePage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [

          const Text("No disponible",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),

          Expanded(
            child: Center(child: SingleChildScrollView(
              child: Column(children: [

                const SizedBox(height: 24,),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: constants.blackGeneral, fontSize: 16,),
                    text: widget.isUniversidadNoDisponible
                        ? "Lo sentimos, Tenfo no está disponible en tu universidad. 🙁\n\n"
                        "Por ahora, solo está disponible en universidades de CABA (Buenos Aires) y alrededores.\n\n"
                        "Verifica que el nombre esté escrito correctamente. Tendremos en cuenta esta solicitud y pronto llegaremos a más lugares.\n\n"

                        : "Lo sentimos, Tenfo no está disponible en tu ciudad o zona. 🙁\n\n"
                        "Actualmente, estamos en CABA (Buenos Aires) y alrededores. Pronto estaremos en más lugares.\n\n",

                    children: [
                      const TextSpan(
                        text: "¡También puedes comunicarte con nosotros a nuestro instagram ",
                      ),
                      TextSpan(
                        text: "@tenfo_social",
                        style: const TextStyle(color: constants.grey,),
                        recognizer: TapGestureRecognizer()..onTap = () async {
                          String urlString = "https://www.instagram.com/tenfo_social";
                          Uri url = Uri.parse(urlString);

                          try {
                            await launchUrl(url, mode: LaunchMode.externalApplication,);
                          } catch (e){
                            throw 'Could not launch $urlString';
                          }
                        },
                      ),
                      const TextSpan(
                        text: " o email ",
                      ),
                      TextSpan(
                        text: "soporte@tenfo.app",
                        style: const TextStyle(color: constants.grey,),
                        recognizer: TapGestureRecognizer()..onTap = () async {
                          String urlString = "mailto:soporte@tenfo.app?subject=Consultas sobre crear cuenta en Tenfo";
                          Uri url = Uri.parse(urlString);

                          try {
                            await launchUrl(url, mode: LaunchMode.externalApplication,);
                          } catch (e){
                            throw 'Could not launch $urlString';
                          }
                        },
                      ),
                      const TextSpan(
                        text: "!",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24,),

              ], mainAxisAlignment: MainAxisAlignment.center,),
            ),),
          ),

          // height es la suma del appBar y el primer texto. Lo hace ver más centrado al Expanded.
          const SizedBox(height: (24 + kToolbarHeight),),
        ],),
      ),
    );
  }
}