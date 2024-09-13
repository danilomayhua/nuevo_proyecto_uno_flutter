import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/actividad/actividad_page.dart';
import 'package:tenfo/screens/chat/chat_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/actividad_boton_entrar.dart';
import 'package:tenfo/widgets/actividad_boton_like.dart';
import 'package:tenfo/widgets/actividad_boton_enviar.dart';

class CardActividad extends StatefulWidget {
  CardActividad({Key? key, required this.actividad,
    this.showTooltipUnirse = false, this.onOpen, this.onChangeActividad}) : super(key: key);

  Actividad actividad;
  bool showTooltipUnirse;
  void Function()? onOpen;
  void Function(Actividad)? onChangeActividad;

  @override
  _CardActividadState createState() => _CardActividadState();
}

class _CardActividadState extends State<CardActividad> {

  bool _enviandoMatchLike = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        if(widget.onOpen != null){
          widget.onOpen!();
          return;
        }

        // TODO : eliminar onChangeIngreso y usar provider (o algo parecido) para actualizar los estados globalmente
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => ActividadPage(
              actividad: widget.actividad,
              onChangeIngreso: (Actividad actividad){
                // No hace nada si ya no existe la actividad (por ej. si se actualizó Inicio automáticamente)
                setState(() {
                  widget.actividad = actividad;
                });
              },
            )
        ));
      },
      child: _contenido(),
    );
  }

  Widget _contenido(){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: constants.grey, width: 0.5,),
        color: Colors.white,
      ),
      //padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 4,), // bottom es menor, porque el boton inferior tiene un margen agregado
      padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 12,),
      child: Stack(children: [
        Column(children: [
          Row(
            children: [
              /*
              Text(widget.actividad.getPrivacidadTipoString(),
                style: TextStyle(color: constants.grey, fontSize: 12,),
              ),
              */
              if(widget.actividad.distanciaTexto != null)
                Text("${widget.actividad.distanciaTexto ?? '' } • ",
                  style: const TextStyle(color: constants.greyLight, fontSize: 12,),
                ),
              Text(widget.actividad.fecha,
                style: const TextStyle(color: constants.greyLight, fontSize: 12,),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.end,
          ),
          const SizedBox(height: 28,),
          Align(
            alignment: Alignment.center,
            child: Text(widget.actividad.titulo,
              style: TextStyle(color: constants.blackGeneral, fontSize: 18,
                height: 1.3, fontWeight: FontWeight.w500,),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28,),

          Row(children: [
            const SizedBox(width: 4,),
            GestureDetector(
              onTap: (){
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserPage(usuario: widget.actividad.creadores[0].toUsuario(),)),
                );
              },
              child: SizedBox(
                width: (15 * widget.actividad.creadores.length) + 18,
                height: 24,
                child: Stack(
                  children: [
                    Container(),
                    for (int i=(widget.actividad.creadores.length-1); i>=0; i--)
                      Positioned(
                        left: (15 * i).toDouble(),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: constants.greyLight, width: 0.5,),
                          ),
                          height: 24,
                          width: 24,
                          child: CircleAvatar(
                            // TODO : cambiar valor de greyBackgroundImage para cambiar en todos
                            //backgroundColor: constants.greyBackgroundImage,
                            backgroundColor: const Color(0xFFFAFAFA),
                            backgroundImage: CachedNetworkImageProvider(widget.actividad.creadores[i].foto),
                            //radius: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if(widget.actividad.creadores.length == 1)
              Expanded(
                child: GestureDetector(
                  onTap: (){
                    Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserPage(usuario: widget.actividad.creadores[0].toUsuario(),)),
                    );
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Text(_getTextCocreadores(),
                      style: const TextStyle(color: constants.grey, fontSize: 12,),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            if(widget.actividad.creadores.length != 1)
              Expanded(
                child: Text(_getTextCocreadores(),
                  style: const TextStyle(color: constants.grey, fontSize: 12,),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            /*ActividadBotonLike(
              actividad: widget.actividad,
              onChange: (){
                setState(() {});
              },
            ),
            Text(widget.actividad.likesCount > 0 ? "${widget.actividad.likesCount}" : "",
              style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
            ),*/
          ],),

          const SizedBox(height: 16,),

          Row(children: [
            ActividadBotonLike(
              actividad: widget.actividad,
              onChange: (){
                setState(() {});
              },
            ),
            Text(widget.actividad.likesCount > 0 ? "${widget.actividad.likesCount}" : "",
              style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
            ),
            const SizedBox(width: 8,),
            ActividadBotonEnviar(actividad: widget.actividad, fromPantalla: ActividadBotonEnviarFromPantalla.card_actividad,),

            const Spacer(),

            Stack(children: [
              /*Container(
                width: 120,
                child: ActividadBotonEntrar(actividad: widget.actividad),
              ),*/
              ActividadBotonEntrar(actividad: widget.actividad,),

              if(widget.showTooltipUnirse && widget.actividad.ingresoEstado == ActividadIngresoEstado.NO_INTEGRANTE && !widget.actividad.isAutor)
                Positioned(
                  child: Container(
                    decoration: ShapeDecoration(
                      shape: _CustomShapeBorder(),
                      color: Colors.grey[700]?.withOpacity(0.9),
                    ),
                    constraints: const BoxConstraints(maxWidth: 200,),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8,),
                    child: const Text("Únete y forma parte del chat grupal para conocer a los participantes.",
                      style: TextStyle(color: Colors.white, fontSize: 12,),
                    ),
                  ),
                  bottom: 56,
                  right: 0,
                ),
            ], clipBehavior: Clip.none,),
            const SizedBox(width: 8,),
          ],),

          /*Row(children: [
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                width: 120,
                child: _buildMatchLike(),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Stack(children: [
                Container(
                  width: 120,
                  child: ActividadBotonEntrar(actividad: widget.actividad),
                ),

                if(widget.showTooltipUnirse && widget.actividad.ingresoEstado == ActividadIngresoEstado.NO_INTEGRANTE && !widget.actividad.isAutor)
                  Positioned(
                    child: Container(
                      decoration: ShapeDecoration(
                        shape: _CustomShapeBorder(),
                        color: Colors.grey[700]?.withOpacity(0.9),
                      ),
                      constraints: const BoxConstraints(maxWidth: 200,),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8,),
                      child: const Text("Únete y forma parte del chat grupal para conocer a los participantes.",
                        style: TextStyle(color: Colors.white, fontSize: 12,),
                      ),
                    ),
                    bottom: 56,
                    right: 0,
                  ),
              ], clipBehavior: Clip.none,),
            ),
          ], mainAxisAlignment: MainAxisAlignment.spaceEvenly,),*/

        ],
        crossAxisAlignment: CrossAxisAlignment.start,),
      ]),
    );
  }

  String _getTextCocreadores(){
    String creadoresNombre = "";

    if(widget.actividad.creadores.length == 1){

      creadoresNombre = widget.actividad.creadores[0].nombre;

    } else if(widget.actividad.creadores.length >= 1){

      creadoresNombre = widget.actividad.creadores[0].nombre;
      for(int i = 1; i < (widget.actividad.creadores.length-1); i++){
        creadoresNombre += ", "+widget.actividad.creadores[i].nombre;
      }
      creadoresNombre += " y "+widget.actividad.creadores[widget.actividad.creadores.length-1].nombre;

    }

    return creadoresNombre;
  }

  Widget _buildMatchLike(){

    if(!widget.actividad.isAutor && widget.actividad.ingresoEstado == ActividadIngresoEstado.INTEGRANTE && (widget.actividad.isMatch ?? false)){
      return TextButton.icon(
        onPressed: (){},
        icon: const Icon(Icons.check, size: 16,),
        label: const Text("Fuiste seleccionado", style: TextStyle(fontSize: 8),),
        style: TextButton.styleFrom(
          //shape: const StadiumBorder(),
          primary: Colors.lightGreen,
        ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
      );
    }

    if(!widget.actividad.isAutor && widget.actividad.ingresoEstado != ActividadIngresoEstado.INTEGRANTE
        && widget.actividad.ingresoEstado != ActividadIngresoEstado.EXPULSADO){

      if(widget.actividad.isMatch ?? false){

        return TextButton.icon(
          onPressed: (){},
          icon: const Icon(Icons.check, size: 16,),
          label: const Text("Fuiste seleccionado", style: TextStyle(fontSize: 8),),
          style: TextButton.styleFrom(
            //shape: const StadiumBorder(),
            primary: Colors.lightGreen,
          ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
        );

      } else {

        if(widget.actividad.isMatchLiked ?? false){
          return TextButton.icon(
            onPressed: (){},
            icon: const Icon(Icons.thumb_up_rounded, size: 16,),
            label: const Text("Te unirás si estás seleccionado", style: TextStyle(fontSize: 8),),
            style: TextButton.styleFrom(
              //shape: const StadiumBorder(),
              primary: Colors.lightGreen,
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          );
        } else {
          return OutlinedButton.icon(
            onPressed: _enviandoMatchLike ? null : () => _enviarMatchLike(),
            icon: const Icon(Icons.thumb_up_outlined, size: 16,),
            label: const Text("Verificar seleccionado", style: TextStyle(fontSize: 8),),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              primary: Colors.lightGreen,
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          );
        }

      }

    }

    return Container();
  }

  Future<void> _enviarMatchLike() async {
    setState(() {
      _enviandoMatchLike = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadEnviarMatchLikeActividad,
      body: {
        "actividad_id": widget.actividad.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        bool isMatch = datosJson['data']['is_match'];

        if(isMatch){
          widget.actividad.isMatchLiked = true;

          widget.actividad.isMatch = true;
          widget.actividad.ingresoEstado = ActividadIngresoEstado.INTEGRANTE;
          widget.actividad.chat = Chat(
              id: datosJson['data']['chat']['id'].toString(),
              tipo: ChatTipo.GRUPAL,
              numMensajesPendientes: null,
              actividadChat: widget.actividad
          );

          // Actualiza la actividad que abrio este widget
          if(widget.onChangeActividad != null) widget.onChangeActividad!(widget.actividad);

          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ChatPage(chat: widget.actividad.chat, isFromMatch: true,),
          ));

        } else {
          widget.actividad.isMatchLiked = true;

          // Actualiza la actividad que abrio este widget
          if(widget.onChangeActividad != null) widget.onChangeActividad!(widget.actividad);
        }

      } else {
        if(datosJson['error_tipo'] == 'tiene_match_like'){

          widget.actividad.isMatchLiked = true;

          // Actualiza la actividad que abrio este widget
          if(widget.onChangeActividad != null) widget.onChangeActividad!(widget.actividad);

        } else if(datosJson['error_tipo'] == 'limite_match_likes'){

          //Navigator.pop(context);
          _showSnackBar("Alcanzaste el límite de actividades para seleccionar por hoy.");

        } else if(datosJson['error_tipo'] == 'limite_integrantes'){

          _showDialogLimiteIntegrantes();

        } else {
          _showSnackBar("Se produjo un error inesperado");
        }
      }
    }

    setState(() {
      _enviandoMatchLike = false;
    });
  }

  void _showDialogLimiteIntegrantes(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text("Has sido seleccionado anteriormente por el creador de esta actividad, pero el chat grupal ya está lleno. No pueden unirse más usuarios.",
                style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),),
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

class _CustomShapeBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(10)))
      ..moveTo(rect.left + rect.width - 30 - 10, rect.bottom)
      ..lineTo(rect.left + rect.width - 30, rect.bottom + 10)
      ..lineTo(rect.left + rect.width - 30 + 10, rect.bottom);

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return _CustomShapeBorder();
  }
}