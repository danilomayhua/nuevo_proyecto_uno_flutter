import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/actividad/actividad_page.dart';
import 'package:tenfo/screens/chat/chat_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:tenfo/widgets/actividad_boton_entrar.dart';
import 'package:tenfo/widgets/actividad_boton_like.dart';

class ScrollsnapCardActividad extends StatefulWidget {
  ScrollsnapCardActividad({Key? key, required this.actividad, this.onNextItem, this.onChangeActividad,
    this.showTooltipMatchLike = false}) : super(key: key);

  Actividad actividad;
  void Function()? onNextItem;
  void Function(Actividad)? onChangeActividad;
  bool showTooltipMatchLike;

  @override
  _ScrollsnapCardActividadState createState() => _ScrollsnapCardActividadState();
}

class _ScrollsnapCardActividadState extends State<ScrollsnapCardActividad> {

  bool _enviando = false;


  bool _hasShownTooltipMatchLike = false;
  bool _isAvailableTooltipMatchLike  = false;

  Future<void> _showTooltipMatchLike() async {
    await Future.delayed(const Duration(milliseconds: 500,));
    _isAvailableTooltipMatchLike = true;
    setState(() {});

    await Future.delayed(const Duration(seconds: 5,));
    _isAvailableTooltipMatchLike = false;
    if(mounted){
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showTooltipMatchLike && !_hasShownTooltipMatchLike) {
      _hasShownTooltipMatchLike = true;
      _showTooltipMatchLike();
    }

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
          const Text('Actividad',
            style: TextStyle(fontSize: 12, color: constants.greyLight,),
          ),
          Text(widget.actividad.fecha,
            style: const TextStyle(color: constants.greyLight, fontSize: 12,),
            maxLines: 1,
          ),
        ], mainAxisAlignment: MainAxisAlignment.spaceBetween,),

        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            const SizedBox(height: 40,),

            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ActividadPage(
                      actividad: widget.actividad,
                      onChangeIngreso: (Actividad actividad){
                        setState(() {
                          widget.actividad = actividad;
                        });

                        if(widget.onChangeActividad != null) widget.onChangeActividad!(widget.actividad);
                      },
                    )
                ));
              },
              child: Container(
                color: Colors.transparent, // Necesario para que GestureDetector tambien capture al presionar en espacios sin contenido
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(widget.actividad.titulo,
                      style: const TextStyle(color: constants.blackGeneral, fontSize: 20, height: 1.3, fontWeight: FontWeight.bold,),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 48,),

                  Row(children: [
                    const SizedBox(width: 8,),
                    SizedBox(
                      width: (15 * widget.actividad.creadores.length) + 10,
                      height: 20,
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
                                height: 20,
                                width: 20,
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFFFAFAFA),
                                  backgroundImage: CachedNetworkImageProvider(widget.actividad.creadores[i].foto),
                                  //radius: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(_getTextCocreadores(widget.actividad),
                        style: const TextStyle(color: constants.grey, fontSize: 12,),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],),

                  Row(children: [
                    const Spacer(),
                    ActividadBotonLike(
                      actividad: widget.actividad,
                      onChange: (){
                        setState(() {});
                      },
                    ),
                    Text(widget.actividad.likesCount > 0 ? "${widget.actividad.likesCount}" : "",
                      style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
                    ),
                  ],),
                ],),
              ),
            ),

            const SizedBox(height: 48,),

            Row(children: [

              if(!widget.actividad.isAutor
                  && widget.actividad.ingresoEstado != ActividadIngresoEstado.INTEGRANTE
                  && widget.actividad.ingresoEstado != ActividadIngresoEstado.EXPULSADO)
                ...[
                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40,),
                      width: 140,
                      child: (widget.actividad.isMatch ?? false)
                          ? _buildMatchExito()
                          : (widget.actividad.isMatchLiked ?? false)
                            ? _buildMatchLikeEnviado()
                            : _buildBotonMatchLike(),
                    ),
                  ),
                  const SizedBox(width: 16,),
                ],

              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40,),
                  width: 140,
                  child: ActividadBotonEntrar(actividad: widget.actividad),
                ),
              ),
            ], mainAxisAlignment: MainAxisAlignment.center,),

          ]),
        ),
      ],),
    );
  }

  String _getTextCocreadores(Actividad actividad){
    String creadoresNombre = "";

    if(actividad.creadores.length == 1){

      creadoresNombre = actividad.creadores[0].username;

    } else if(actividad.creadores.length >= 1){

      creadoresNombre = actividad.creadores[0].username;
      for(int i = 1; i < (actividad.creadores.length-1); i++){
        creadoresNombre += ", " + actividad.creadores[i].username;
      }
      creadoresNombre += " y " + actividad.creadores[actividad.creadores.length-1].username;

    }

    return creadoresNombre;
  }

  Widget _buildBotonMatchLike(){
    return Stack(children: [

      OutlinedButton.icon(
        onPressed: _enviando ? null : () => _enviarMatchLike(),
        icon: const Icon(Icons.thumb_up_rounded, size: 16,),
        label: const Text("Unirme si estoy seleccionado", style: TextStyle(fontSize: 12),),
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          primary: Colors.lightGreen,
        ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
      ),

      if(_isAvailableTooltipMatchLike)
        Positioned(
          child: Container(
            decoration: ShapeDecoration(
              shape: _CustomShapeBorder(),
              color: Colors.grey[700]?.withOpacity(0.8),
            ),
            constraints: const BoxConstraints(maxWidth: 220,),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8,),
            child: const Text("Únete solo si fuiste seleccionado. No se notificará que intentaste unirte si aún no estás seleccionado.",
              style: TextStyle(color: Colors.white, fontSize: 12,),
            ),
          ),
          //bottom: 56,
          top: 56,
          left: 0,
        ),

    ], clipBehavior: Clip.none,);
  }

  Widget _buildMatchExito(){
    return TextButton(
      onPressed: (){},
      child: const Text("🤝 Seleccionados", style: TextStyle(fontSize: 14),),
      style: TextButton.styleFrom(
        //shape: const StadiumBorder(),
        primary: Colors.lightGreen,
      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
    );
  }

  Widget _buildMatchLikeEnviado(){
    return TextButton.icon(
      onPressed: (){},
      icon: const Icon(Icons.thumb_up_rounded, size: 16,),
      label: const Text("Te unirás si estás seleccionado", style: TextStyle(fontSize: 12),),
      style: TextButton.styleFrom(
        //shape: const StadiumBorder(),
        primary: Colors.lightGreen,
      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
    );
  }

  Future<void> _enviarMatchLike() async {
    setState(() {
      _enviando = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);


    // Tooltip de ayuda a los usuarios nuevos para enviar match like a actividad. Actualiza valor para no volver a mostrar.
    bool isShowedMatchLike = prefs.getBool(SharedPreferencesKeys.isShowedAyudaActividadMatchLike) ?? false;
    if(!isShowedMatchLike){
      prefs.setBool(SharedPreferencesKeys.isShowedAyudaActividadMatchLike, true);
    }


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


          /*
          // Si tiene demora el request y sigue bajando, esto haria que baje de más
          if(widget.onNextItem != null){
            widget.onNextItem!();
          }
          */
        }

      } else {
        if(datosJson['error_tipo'] == 'tiene_match_like'){

          widget.actividad.isMatchLiked = true;

          // Actualiza la actividad que abrio este widget
          if(widget.onChangeActividad != null) widget.onChangeActividad!(widget.actividad);

        } else if(datosJson['error_tipo'] == 'limite_match_likes'){

          Navigator.pop(context);
          _showSnackBar("Alcanzaste el límite de actividades para seleccionar por hoy.");

        } else if(datosJson['error_tipo'] == 'limite_integrantes'){

          _showDialogLimiteIntegrantes();

        } else {
          _showSnackBar("Se produjo un error inesperado");
        }
      }
    }

    setState(() {
      _enviando = false;
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
      ..moveTo(rect.left + 35, rect.top)
      ..lineTo(rect.left + 25, rect.top - 10)
      ..lineTo(rect.left + 15, rect.top);

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return _CustomShapeBorder();
  }
}
