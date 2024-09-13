import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/share_utils.dart';

class ActividadBotonEnviar extends StatefulWidget {
  const ActividadBotonEnviar({Key? key, required this.actividad, this.fromPantalla}) : super(key: key);

  final Actividad actividad;
  final ActividadBotonEnviarFromPantalla? fromPantalla;

  @override
  _ActividadBotonEnviarState createState() => _ActividadBotonEnviarState();
}

// Es importante no cambiar los nombres de este enum (se envian al backend)
enum ActividadBotonEnviarFromPantalla { card_actividad, scrollsnap_actividad, actividad_page }

class _ActividadBotonEnviarState extends State<ActividadBotonEnviar> {

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.arrowshape_turn_up_right, size: 18, color: constants.blackGeneral,),
      onPressed: () => _showDialogCompartir(),
      constraints: const BoxConstraints(),
    );
  }

  void _showDialogCompartir(){
    bool isClosed = false;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context){
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16,),
          child: Column(children: [
            Container(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: (){
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.clear_rounded, color: Colors.black54,),
              ),
            ),

            Container(
              alignment: Alignment.center,
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: [

                  /*InkWell(
                    onTap: () => (){},
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            child: Image.asset("assets/instagram_icon_circulo.png"),
                          ),
                          const SizedBox(height: 10,),
                          const Text("Instagram", style: TextStyle(fontSize: 12), textAlign: TextAlign.center,)
                        ],
                        //mainAxisAlignment: MainAxisAlignment.center,
                      ),
                    ),
                  ),

                  InkWell(
                      onTap: () => _compartirWhatsapp(),
                      child: Container(
                        width: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              child: Image.asset("assets/whatsapp_icon_circulo.png"),
                            ),
                            const SizedBox(height: 10,),
                            const Text("WhatsApp", style: TextStyle(fontSize: 12), textAlign: TextAlign.center,)
                          ],
                          //mainAxisAlignment: MainAxisAlignment.center,
                        ),
                      ),
                  ),*/

                  Column(children: [
                    InkWell(
                      onTap: () => _compartirWhatsapp(),
                      child: Container(
                        //width: 56,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25d366),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              child: Image.asset("assets/whatsapp_icon_circulo.png"),
                            ),
                            const SizedBox(width: 4,),
                            const Text("Enviar a WhatsApp", style: TextStyle(fontSize: 14, color: Colors.white,),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          //mainAxisAlignment: MainAxisAlignment.center,
                        ),
                      ),
                    ),
                  ], mainAxisAlignment: MainAxisAlignment.start,),

                  InkWell(
                    onTap: () => _copiarLink(),
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.cyan,
                            ),
                            child: const Icon(CupertinoIcons.link, size: 24, color: Colors.white,),
                          ),
                          const SizedBox(height: 10,),
                          const Text("Copiar enlace", style: TextStyle(fontSize: 12), textAlign: TextAlign.center,)
                        ],
                        //mainAxisAlignment: MainAxisAlignment.center,
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: () => _compartirGeneral(),
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: constants.grey),
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(CupertinoIcons.share, size: 24,),
                          ),
                          const SizedBox(height: 10,),
                          const Text("Compartir", style: TextStyle(fontSize: 12), textAlign: TextAlign.center,)
                        ],
                        //mainAxisAlignment: MainAxisAlignment.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32,),

          ], mainAxisSize: MainAxisSize.min,),
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0),),
      ),
      isScrollControlled: true,
    ).then((value){
      isClosed = true;
    });
  }

  void _compartirWhatsapp(){
    ShareUtils.shareActivityWhatsapp(widget.actividad.id);

    // Envia historial del usuario
    _enviarHistorialUsuario(HistorialUsuario.getActividadEnviarWhatsapp(widget.actividad.id, fromPantalla: widget.fromPantalla,));
  }

  void _copiarLink(){
    Navigator.of(context).pop();
    ShareUtils.copyLinkActivity(widget.actividad.id)
        .then((value) => _showSnackBar("Enlace copiado"));

    // Envia historial del usuario
    _enviarHistorialUsuario(HistorialUsuario.getActividadEnviarCopiar(widget.actividad.id, fromPantalla: widget.fromPantalla,));
  }

  void _compartirGeneral(){
    ShareUtils.shareActivity(widget.actividad.id);

    // Envia historial del usuario
    _enviarHistorialUsuario(HistorialUsuario.getActividadEnviarCompartir(widget.actividad.id, fromPantalla: widget.fromPantalla,));
  }


  Future<void> _enviarHistorialUsuario(Map<String, dynamic> historialUsuario) async {
    //setState(() {});

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCrearHistorialUsuarioActivo,
      body: {
        "historiales_usuario_activo": [historialUsuario],
      },
      usuarioSesion: usuarioSesion,
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