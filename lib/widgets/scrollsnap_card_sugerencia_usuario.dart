import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/sugerencia_usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/icon_universidad_verificada.dart';

class ScrollsnapCardSugerenciaUsuario extends StatefulWidget {
  ScrollsnapCardSugerenciaUsuario({Key? key, required this.sugerenciaUsuario,
    this.isAutorActividadVisible = false, this.onNextItem, this.onChangeSugerenciaUsuario}) : super(key: key);

  SugerenciaUsuario sugerenciaUsuario;
  bool isAutorActividadVisible;
  void Function()? onNextItem;
  void Function(SugerenciaUsuario)? onChangeSugerenciaUsuario;

  @override
  _ScrollsnapCardSugerenciaUsuarioState createState() => _ScrollsnapCardSugerenciaUsuarioState();
}

class _ScrollsnapCardSugerenciaUsuarioState extends State<ScrollsnapCardSugerenciaUsuario> {

  bool _enviando = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16,),
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Row(children: const [
          Text('Sugerencia',
            style: TextStyle(fontSize: 12, color: constants.greyLight,),
          ),
        ], mainAxisAlignment: MainAxisAlignment.start,),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            const SizedBox(height: 16,),

            GestureDetector(
              onTap: (){
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserPage(
                    usuario: widget.sugerenciaUsuario.toUsuario(),
                  )),
                );
              },
              child: CircleAvatar(
                radius: 40,
                backgroundImage: CachedNetworkImageProvider(widget.sugerenciaUsuario.foto),
                backgroundColor: Colors.transparent,
              ),
            ),

            const SizedBox(height: 24,),

            GestureDetector(
              onTap: (){
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserPage(
                    usuario: widget.sugerenciaUsuario.toUsuario(),
                  )),
                );
              },
              child: Row(children: [
                Flexible(
                  child: Text(widget.sugerenciaUsuario.nombre,
                    style: const TextStyle(color: constants.blackGeneral, fontSize: 20,),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                if(widget.sugerenciaUsuario.isVerificadoUniversidad)
                  ...[
                    const SizedBox(width: 4,),
                    const IconUniversidadVerificada(size: 16),
                  ],
              ], mainAxisSize: MainAxisSize.min,),
            ),

            const SizedBox(height: 24,),

            if(!(widget.isAutorActividadVisible))
              ...[
                const SizedBox(height: 16,),
                const Text("Crea una actividad y jugá con invitaciones anónimas:",
                  style: TextStyle(color: constants.grey, fontSize: 12, height: 1.3,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16,),
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  child: ElevatedButton.icon(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => CrearActividadPage(fromSugerenciaUsuario: widget.sugerenciaUsuario,),
                      ));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Crear"),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                  ),
                ),
              ],

            if((widget.isAutorActividadVisible))
              ...[
                const SizedBox(height: 16,),
                const Text("Elige en anónimo como integrante permitido para tu actividad:",
                  style: TextStyle(color: constants.grey, fontSize: 12, height: 1.3,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16,),
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  child: (widget.sugerenciaUsuario.isMatch ?? false)
                      ? _buildMatchExito()
                      : (widget.sugerenciaUsuario.isMatchLiked ?? false)
                      ? _buildMatchLikeEnviado()
                      : _buildBotonMatchLike(),
                ),
              ],

            const SizedBox(height: 16,),
          ]),
        ),
      ],),
    );
  }

  Widget _buildBotonMatchLike(){
    return OutlinedButton.icon(
      onPressed: _enviando ? null : () => _enviarMatchLike(),
      icon: const Icon(Icons.thumb_up_off_alt, size: 18,),
      label: const Text("Si", style: TextStyle(fontSize: 14),),
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        primary: Colors.lightGreen,
      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
    );
  }

  Widget _buildMatchExito(){
    return TextButton.icon(
      onPressed: (){},
      icon: const Icon(Icons.check,),
      label: const Text("Seleccionados mutuamente", style: TextStyle(fontSize: 12),),
      style: TextButton.styleFrom(
        //shape: const StadiumBorder(),
        primary: Colors.lightGreen,
      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
    );
  }

  Widget _buildMatchLikeEnviado(){
    return TextButton.icon(
      onPressed: (){},
      icon: const Icon(Icons.thumb_up, size: 18,),
      label: const Text("Seleccionado", style: TextStyle(fontSize: 12),),
      style: TextButton.styleFrom(
        //shape: const StadiumBorder(),
        primary: Colors.lightGreen,
      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
    );
  }

  Future<void> _enviarMatchLike() async {
    widget.sugerenciaUsuario.isMatchLiked = true;

    setState(() {
      _enviando = true;
    });

    // Actualiza sugerenciaUsuario que abrio este widget
    if(widget.onChangeSugerenciaUsuario != null) widget.onChangeSugerenciaUsuario!(widget.sugerenciaUsuario);

    if(widget.onNextItem != null){
      widget.onNextItem!();
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadEnviarMatchLikeIntegrante,
      body: {
        "usuario_id": widget.sugerenciaUsuario.id,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        bool isMatch = datosJson['data']['is_match'];

        if(isMatch){
          widget.sugerenciaUsuario.isMatch = true;

          String chatId = datosJson['data']['chat']['id'].toString();
          _showDialogMatchExito(chatId);

          // Actualiza sugerenciaUsuario que abrio este widget
          if(widget.onChangeSugerenciaUsuario != null) widget.onChangeSugerenciaUsuario!(widget.sugerenciaUsuario);

        } else {

          // Los cambios ya fueron agregados al principio de la funcion

        }

      } else {
        if(datosJson['error_tipo'] == 'tiene_match_like'){

          // widget.onChangeSugerenciaUsuario.isMatchLiked = true;

        } else if(datosJson['error_tipo'] == 'limite_match_likes'){

          widget.sugerenciaUsuario.isMatchLiked = false;
          // Actualiza sugerenciaUsuario que abrio este widget
          if(widget.onChangeSugerenciaUsuario != null) widget.onChangeSugerenciaUsuario!(widget.sugerenciaUsuario);

          Navigator.pop(context);
          _showSnackBar("Alcanzaste el límite de usuarios para seleccionar por hoy.");

        } else if(datosJson['error_tipo'] == 'limite_integrantes'){

          _showDialogLimiteIntegrantes();

        } else if(datosJson['error_tipo'] == 'integrante'){

          _showDialogIntegranteActual();

        } else if(datosJson['error_tipo'] == 'ingreso_no_permitido'){

          widget.sugerenciaUsuario.isMatchLiked = false;
          // Actualiza sugerenciaUsuario que abrio este widget
          if(widget.onChangeSugerenciaUsuario != null) widget.onChangeSugerenciaUsuario!(widget.sugerenciaUsuario);

          _showDialogIntegranteExpulsado();

        } else {
          widget.sugerenciaUsuario.isMatchLiked = false;
          _showSnackBar("Se produjo un error inesperado");

          // Actualiza sugerenciaUsuario que abrio este widget
          if(widget.onChangeSugerenciaUsuario != null) widget.onChangeSugerenciaUsuario!(widget.sugerenciaUsuario);
        }
      }
    }

    setState(() {
      _enviando = false;
    });
  }

  void _showDialogMatchExito(String chatId){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("${widget.sugerenciaUsuario.nombre} seleccionó anteriormente tu actividad ¡Ahora forma parte de la actividad!",
                style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: const Text("Continuar seleccionando"),
          ),
        ],
      );
    });
  }

  void _showDialogLimiteIntegrantes(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("${widget.sugerenciaUsuario.nombre} seleccionó anteriormente tu actividad, pero el chat grupal ya está lleno. No pueden unirse más usuarios.",
                style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: const Text("Entendido"),
          ),
        ],
      );
    });
  }

  void _showDialogIntegranteActual(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("¡${widget.sugerenciaUsuario.nombre} ya está en tu actividad!",
                style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: const Text("Entendido"),
          ),
        ],
      );
    });
  }

  void _showDialogIntegranteExpulsado(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("No puedes seleccionar a ${widget.sugerenciaUsuario.nombre} porque fue eliminado de tu actividad.",
                style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: const Text("Entendido"),
          ),
        ],
      );
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