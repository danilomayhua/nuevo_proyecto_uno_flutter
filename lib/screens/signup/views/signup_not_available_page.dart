import 'package:flutter/material.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SignupNotAvailablePage extends StatefulWidget {
  const SignupNotAvailablePage({Key? key, required this.isUniversidadNoDisponible}) : super(key: key);

  final bool isUniversidadNoDisponible;

  @override
  State<SignupNotAvailablePage> createState() => _SignupNotAvailablePageState();
}

class _SignupNotAvailablePageState extends State<SignupNotAvailablePage> {


  String _mensajeNoDisponible = "";

  @override
  void initState() {
    super.initState();

    if(widget.isUniversidadNoDisponible){
      _mensajeNoDisponible = "Lo sentimos, Tenfo no está disponible en tu universidad. 🙁\n\n"
          "Tendremos en cuenta tu solicitud para habilitar la universidad. Pronto estaremos en más lugares.\n\n"
          "¡Síguenos en redes para las novedades!";
    } else {
      _mensajeNoDisponible = "Lo sentimos, Tenfo no está disponible en tu ciudad o zona. 🙁\n\n"
          "Actualmente, estamos en CABA (Buenos Aires) y alrededores. Pronto estaremos en más lugares.\n\n"
          "¡Síguenos en redes para las novedades!";
    }
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

                Text(_mensajeNoDisponible,
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 16,),
                  textAlign: TextAlign.center,
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