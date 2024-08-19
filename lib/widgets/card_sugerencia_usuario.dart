import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/sugerencia_usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/services/superlike_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/icon_universidad_verificada.dart';

class CardSugerenciaUsuario extends StatefulWidget {
  CardSugerenciaUsuario({Key? key, required this.sugerenciaUsuario,
    this.isAutorActividadVisible, this.onOpen, this.onChangeSugerenciaUsuario}) : super(key: key);

  SugerenciaUsuario sugerenciaUsuario;
  bool? isAutorActividadVisible;
  void Function()? onOpen;
  void Function(SugerenciaUsuario)? onChangeSugerenciaUsuario;

  @override
  _CardSugerenciaUsuarioState createState() => _CardSugerenciaUsuarioState();
}

class _CardSugerenciaUsuarioState extends State<CardSugerenciaUsuario> {

  bool _enviandoMatchLike = false;

  bool _enviandoSuperlike = false;
  bool _superlikeEnviadoAhora = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        if(widget.onOpen != null){
          widget.onOpen!();
          return;
        }
      },
      child: _contenido(),
    );
  }

  Widget _contenido(){
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.only(left: 16, top: 28, right: 16, bottom: 28,),
      child: Row(children: [

        Container(
          width: 120,
          child: GestureDetector(
            onTap: (){
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => UserPage(
                  usuario: widget.sugerenciaUsuario.toUsuario(),
                )),
              );
            },
            child: Column(children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: constants.greyLight, width: 0.5,),
                ),
                height: 48,
                width: 48,
                child: CircleAvatar(
                  //backgroundColor: constants.greyBackgroundImage,
                  backgroundColor: const Color(0xFFFAFAFA),
                  backgroundImage: CachedNetworkImageProvider(widget.sugerenciaUsuario.foto),
                ),
              ),
              const SizedBox(height: 16,),
              Row(children: [
                Flexible(
                  child: Text(widget.sugerenciaUsuario.nombre,
                    style: const TextStyle(color: constants.blackGeneral, fontSize: 18,),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if(widget.sugerenciaUsuario.isVerificadoUniversidad)
                  ...[
                    const SizedBox(width: 4,),
                    const IconUniversidadVerificada(size: 14),
                  ],
              ], mainAxisSize: MainAxisSize.min,),
            ], mainAxisAlignment: MainAxisAlignment.center,),
          ),
        ),

        Expanded(child: Column(children: [

          const SizedBox(height: 16,),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8,),
            child: Text(!(widget.isAutorActividadVisible ?? false)
                ? "Crea una actividad o incentiva a ${widget.sugerenciaUsuario.nombre} a hacer actividades:"
                : "Incentiva a ${widget.sugerenciaUsuario.nombre} a participar en tu actividad:",
              style: const TextStyle(color: constants.grey, fontSize: 10, height: 1.3,),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24,),

          Row(children: [
            if(!(widget.isAutorActividadVisible ?? false))
              ...[
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => CrearActividadPage(
                        fromSugerenciaUsuario: widget.sugerenciaUsuario,
                        fromPantalla: CrearActividadFromPantalla.card_sugerencia_usuario,
                      ),
                    ));
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.add_rounded, size: 14,),
                    SizedBox(width: 2),
                    Text("Crear", style: TextStyle(fontSize: 12,),),
                  ],),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 0,),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                    primary: Colors.lightBlue,
                    side: const BorderSide(width: 0.5, color: Colors.lightBlue),
                    fixedSize: const Size.fromWidth(84),
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),
                const SizedBox(width: 16),
              ],

            if(!widget.sugerenciaUsuario.isSuperliked)
              OutlinedButton(
                onPressed: _enviandoSuperlike ? null : (){
                  SuperlikeService.enviarSuperlike(
                    usuarioId: widget.sugerenciaUsuario.id,
                    onChange: ({bool? isSuperliked, bool? enviando}){
                      widget.sugerenciaUsuario.isSuperliked = isSuperliked ?? false;
                      if(widget.sugerenciaUsuario.isSuperliked){
                        _superlikeEnviadoAhora = true;
                      }
                      _enviandoSuperlike = enviando ?? false;

                      setState(() {});

                      // Actualiza sugerenciaUsuario que abrio este widget
                      if(widget.onChangeSugerenciaUsuario != null) widget.onChangeSugerenciaUsuario!(widget.sugerenciaUsuario);
                    },
                    context: context,
                    fromSugerenciaUsuario: widget.sugerenciaUsuario,
                    fromPantalla: SuperlikeServiceFromPantalla.card_sugerencia_usuario,
                  );
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(CupertinoIcons.heart, size: 14,),
                  SizedBox(width: 2),
                  Text("Incentivar", style: TextStyle(fontSize: 10,),),
                ],),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 0,),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                  primary: Colors.lightGreen,
                  side: const BorderSide(width: 0.5, color: Colors.lightGreen),
                  fixedSize: const Size.fromWidth(84),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            if(widget.sugerenciaUsuario.isSuperliked)
              OutlinedButton(
                onPressed: (){
                  SuperlikeService.intentarPresionarSuperliked(
                    usuarioNombre: widget.sugerenciaUsuario.nombre,
                    context: context,
                  );
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_superlikeEnviadoAhora ? CupertinoIcons.heart_fill : CupertinoIcons.heart, size: 14,),
                  const SizedBox(width: 2),
                  const Text("Incentivar", style: TextStyle(fontSize: 10,),),
                ],),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 0,),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                  primary: _superlikeEnviadoAhora ? Colors.lightGreen : constants.greyLight,
                  side: BorderSide(width: 0.5, color: _superlikeEnviadoAhora ? Colors.lightGreen : constants.greyLight),
                  fixedSize: const Size.fromWidth(84),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
          ], mainAxisAlignment: MainAxisAlignment.center,),

          /*
          if((widget.isAutorActividadVisible ?? false))
            ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16,),
                child: Text("Elige en anónimo como integrante permitido para tu actividad:",
                  style: TextStyle(color: constants.grey, fontSize: 10, height: 1.3,),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16,),

              if(!(widget.sugerenciaUsuario.isMatchLiked ?? false))
                OutlinedButton(
                  onPressed: _enviandoMatchLike ? null : () => _enviarMatchLike(),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.thumb_up_off_alt, size: 16, color: Colors.lightGreen,),
                    SizedBox(width: 4),
                    Text("Si", style: TextStyle(fontSize: 12, color: Colors.lightGreen,),),
                  ],),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16,),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(48, 36),
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),

              if((widget.sugerenciaUsuario.isMatchLiked ?? false) && !(widget.sugerenciaUsuario.isMatch ?? false))
                TextButton(
                  onPressed: () {},
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.thumb_up, size: 16, color: Colors.lightGreen,),
                    SizedBox(width: 4),
                    Text("Seleccionado", style: TextStyle(fontSize: 12, color: Colors.lightGreen,),),
                  ],),
                  style: TextButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 8,),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(48, 36),
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),

              if((widget.sugerenciaUsuario.isMatchLiked ?? false) && (widget.sugerenciaUsuario.isMatch ?? false))
                TextButton(
                  onPressed: () {},
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.check, size: 16, color: Colors.lightGreen,),
                    SizedBox(width: 4),
                    Text("Seleccionados mutuamente", style: TextStyle(fontSize: 10, color: Colors.lightGreen,),),
                  ],),
                  style: TextButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 8,),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(48, 36),
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),
            ],
         */

          const SizedBox(height: 16,),

        ], mainAxisAlignment: MainAxisAlignment.center,)),
      ], crossAxisAlignment: CrossAxisAlignment.center,),
    );
  }


  Future<void> _enviarMatchLike() async {
    widget.sugerenciaUsuario.isMatchLiked = true;

    setState(() {
      _enviandoMatchLike = true;
    });

    // Actualiza sugerenciaUsuario que abrio este widget
    if(widget.onChangeSugerenciaUsuario != null) widget.onChangeSugerenciaUsuario!(widget.sugerenciaUsuario);

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

          //Navigator.pop(context);
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
      _enviandoMatchLike = false;
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