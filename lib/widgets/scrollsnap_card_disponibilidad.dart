import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/chat/chat_page.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/services/superlike_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/icon_universidad_verificada.dart';

class ScrollsnapCardDisponibilidad extends StatefulWidget {
  ScrollsnapCardDisponibilidad({Key? key, required this.disponibilidad,
    this.isAutorActividadVisible = false, this.autorActividad,
    this.onNextItem, this.onChangeDisponibilidad}) : super(key: key);

  Disponibilidad disponibilidad;
  bool isAutorActividadVisible;
  Actividad? autorActividad;
  void Function()? onNextItem;
  void Function(Disponibilidad)? onChangeDisponibilidad;

  @override
  _ScrollsnapCardDisponibilidadState createState() => _ScrollsnapCardDisponibilidadState();
}

class _ScrollsnapCardDisponibilidadState extends State<ScrollsnapCardDisponibilidad> {

  bool _enviando = false;

  bool _enviandoSuperlike = false;
  bool _superlikeEnviadoAhora = false;

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
        Row(children: [
          const Text('Estado',
            style: TextStyle(fontSize: 12, color: constants.greyLight,),
          ),
          Text(widget.disponibilidad.fecha,
            style: const TextStyle(color: constants.greyLight, fontSize: 12,),
            maxLines: 1,
          ),
        ], mainAxisAlignment: MainAxisAlignment.spaceBetween,),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            const SizedBox(height: 16,),

            GestureDetector(
              onTap: (){
                // TODO : obtener los datos completos del usuario en disponibilidad.creador
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserPage(
                    usuario: Usuario(id: widget.disponibilidad.creador.id, nombre: "", username: "", foto: widget.disponibilidad.creador.foto,),
                  )),
                );
              },
              child: CircleAvatar(
                radius: 40,
                backgroundImage: CachedNetworkImageProvider(widget.disponibilidad.creador.foto),
                backgroundColor: Colors.transparent,
              ),
            ),

            const SizedBox(height: 16,),

            GestureDetector(
              onTap: (){
                // TODO : obtener los datos completos del usuario en disponibilidad.creador
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserPage(
                    usuario: Usuario(id: widget.disponibilidad.creador.id, nombre: "", username: "", foto: widget.disponibilidad.creador.foto,),
                  )),
                );
              },
              child: Row(children: [
                Flexible(
                  child: Text(widget.disponibilidad.creador.nombre,
                    style: const TextStyle(color: constants.blackGeneral, fontSize: 16,),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                if(widget.disponibilidad.creador.isVerificadoUniversidad)
                  ...[
                    const SizedBox(width: 4,),
                    const IconUniversidadVerificada(size: 16),
                  ],
              ], mainAxisSize: MainAxisSize.min,),
            ),

            const SizedBox(height: 24,),

            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(widget.disponibilidad.texto,
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 18, height: 1.3, fontWeight: FontWeight.bold,),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 48,),

            if(!(widget.isAutorActividadVisible) && !widget.disponibilidad.isAutor)
              ...[
                const SizedBox(height: 16,),
                Text("Crea una actividad para que usuarios como ${widget.disponibilidad.creador.nombre} puedan unirse:",
                  style: const TextStyle(color: constants.grey, fontSize: 12, height: 1.3,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16,),
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  child: ElevatedButton.icon(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => CrearActividadPage(
                          fromDisponibilidad: widget.disponibilidad,
                          fromPantalla: CrearActividadFromPantalla.scrollsnap_disponibilidad,
                        ),
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

            if((widget.isAutorActividadVisible) && !widget.disponibilidad.isAutor)
              ...[
                const SizedBox(height: 16,),
                const Text("Envía un incentivo en anónimo para que revise las actividades creadas:",
                  style: TextStyle(color: constants.grey, fontSize: 12, height: 1.3,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16,),
                if(!widget.disponibilidad.creador.isSuperliked)
                  Container(
                    constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                    child: OutlinedButton.icon(
                      onPressed: _enviandoSuperlike ? null : (){
                        SuperlikeService.enviarSuperlike(
                          usuarioId: widget.disponibilidad.creador.id,
                          onChange: ({bool? isSuperliked, bool? enviando}){
                            widget.disponibilidad.creador.isSuperliked = isSuperliked ?? false;
                            if(widget.disponibilidad.creador.isSuperliked){
                              _superlikeEnviadoAhora = true;
                            }
                            _enviandoSuperlike = enviando ?? false;

                            setState(() {});

                            // Actualiza la disponibilidad que abrio este widget
                            if(widget.onChangeDisponibilidad != null) widget.onChangeDisponibilidad!(widget.disponibilidad);
                          },
                          context: context,
                          fromDisponibilidad: widget.disponibilidad,
                          fromPantalla: SuperlikeServiceFromPantalla.scrollsnap_disponibilidad,
                        );
                      },
                      icon: const Icon(CupertinoIcons.heart),
                      label: const Text("Incentivar"),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        primary: Colors.lightGreen,
                        side: const BorderSide(width: 0.5, color: Colors.lightGreen),
                      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                    ),
                  ),
                if(widget.disponibilidad.creador.isSuperliked)
                  Container(
                    constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                    child: OutlinedButton.icon(
                      onPressed: (){
                        SuperlikeService.intentarPresionarSuperliked(
                          usuarioNombre: widget.disponibilidad.creador.nombre,
                          context: context,
                        );
                      },
                      icon: _superlikeEnviadoAhora ? const Icon(CupertinoIcons.heart_fill) : const Icon(CupertinoIcons.heart),
                      label: const Text("Incentivar"),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        primary: _superlikeEnviadoAhora ? Colors.lightGreen : constants.greyLight,
                        side: BorderSide(width: 0.5, color: _superlikeEnviadoAhora ? Colors.lightGreen : constants.greyLight,),
                      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                    ),
                  ),
              ],

            /*if((widget.isAutorActividadVisible) && !widget.disponibilidad.isAutor)
              ...[
                const SizedBox(height: 16,),
                const Text("Elige en anónimo como integrante permitido para tu actividad:",
                  style: TextStyle(color: constants.grey, fontSize: 12, height: 1.3,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16,),
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  child: (widget.disponibilidad.creador.isMatch ?? false)
                      ? _buildMatchExito()
                      : (widget.disponibilidad.creador.isMatchLiked ?? false)
                      ? _buildMatchLikeEnviado()
                      : _buildBotonMatchLike(),
                ),
              ],*/

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
    widget.disponibilidad.creador.isMatchLiked = true;

    setState(() {
      _enviando = true;
    });

    // Actualiza la disponibilidad que abrio este widget
    if(widget.onChangeDisponibilidad != null) widget.onChangeDisponibilidad!(widget.disponibilidad);

    if(widget.onNextItem != null){
      widget.onNextItem!();
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadEnviarMatchLikeIntegrante,
      body: {
        "actividad_id": widget.autorActividad?.id,
        "usuario_id": widget.disponibilidad.creador.id,
        "disponibilidad_id": widget.disponibilidad.id,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        bool isMatch = datosJson['data']['is_match'];

        if(isMatch){
          widget.disponibilidad.creador.isMatch = true;

          String chatId = datosJson['data']['chat']['id'].toString();
          _showDialogMatchExito(chatId);

          // Actualiza la disponibilidad que abrio este widget
          if(widget.onChangeDisponibilidad != null) widget.onChangeDisponibilidad!(widget.disponibilidad);

        } else {

          // Los cambios ya fueron agregados al principio de la funcion

        }

      } else {
        if(datosJson['error_tipo'] == 'tiene_match_like'){

          // widget.disponibilidad.creador.isMatchLiked = true;

        } else if(datosJson['error_tipo'] == 'limite_match_likes'){

          widget.disponibilidad.creador.isMatchLiked = false;
          // Actualiza la disponibilidad que abrio este widget
          if(widget.onChangeDisponibilidad != null) widget.onChangeDisponibilidad!(widget.disponibilidad);

          Navigator.pop(context);
          _showSnackBar("Alcanzaste el límite de usuarios para seleccionar por hoy.");

        } else if(datosJson['error_tipo'] == 'limite_integrantes'){

          _showDialogLimiteIntegrantes();

        } else if(datosJson['error_tipo'] == 'integrante'){

          _showDialogIntegranteActual();

        } else if(datosJson['error_tipo'] == 'ingreso_no_permitido'){

          widget.disponibilidad.creador.isMatchLiked = false;
          // Actualiza la disponibilidad que abrio este widget
          if(widget.onChangeDisponibilidad != null) widget.onChangeDisponibilidad!(widget.disponibilidad);

          _showDialogIntegranteExpulsado();

        } else {
          widget.disponibilidad.creador.isMatchLiked = false;
          _showSnackBar("Se produjo un error inesperado");

          // Actualiza la disponibilidad que abrio este widget
          if(widget.onChangeDisponibilidad != null) widget.onChangeDisponibilidad!(widget.disponibilidad);
        }
      }
    }

    setState(() {
      _enviando = false;
    });
  }

  void _showDialogMatchExito(String chatId){
    if(widget.autorActividad != null){
      widget.autorActividad!.ingresoEstado = ActividadIngresoEstado.INTEGRANTE;
      widget.autorActividad!.chat = Chat(
          id: chatId,
          tipo: ChatTipo.GRUPAL,
          numMensajesPendientes: null,
          actividadChat: widget.autorActividad!
      );
    }

    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("${widget.disponibilidad.creador.nombre} seleccionó anteriormente tu actividad ¡Ahora forma parte de la actividad!",
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
          if(widget.autorActividad != null)
            TextButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ChatPage(chat: widget.autorActividad!.chat,),
                ));
              },
              child: const Text("Ir al chat"),
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
              Text("${widget.disponibilidad.creador.nombre} seleccionó anteriormente tu actividad, pero el chat grupal ya está lleno. No pueden unirse más usuarios.",
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
              Text("¡${widget.disponibilidad.creador.nombre} ya está en tu actividad!",
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
              Text("No puedes seleccionar a ${widget.disponibilidad.creador.nombre} porque fue eliminado de tu actividad.",
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