import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/screens/invitar_actividad/invitar_actividad_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/services/superlike_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/icon_universidad_verificada.dart';

class CardDisponibilidad extends StatefulWidget {
  CardDisponibilidad({Key? key, required this.disponibilidad, this.isCreadorActividadVisible,
    this.isAutorActividadVisible, this.onOpen, this.onChangeDisponibilidad, this.showTooltipSuperlike = false}) : super(key: key);

  Disponibilidad disponibilidad;
  bool? isCreadorActividadVisible;
  bool? isAutorActividadVisible;
  void Function()? onOpen;
  void Function(Disponibilidad)? onChangeDisponibilidad;
  bool showTooltipSuperlike;

  @override
  _CardDisponibilidadState createState() => _CardDisponibilidadState();
}

class _CardDisponibilidadState extends State<CardDisponibilidad> {

  bool _enviandoEliminarDisponibilidad = false;

  bool _enviandoMatchLike = false;

  bool _enviandoSuperlike = false;
  bool _superlikeEnviadoAhora = false;


  bool _hasShownTooltipSuperlike = false;
  bool _isAvailableTooltipSuperlike  = false;

  Future<void> _showTooltipSuperlike() async {
    //await Future.delayed(const Duration(milliseconds: 500,));
    await Future.delayed(const Duration(milliseconds: 100,));
    _isAvailableTooltipSuperlike = true;
    setState(() {});

    await Future.delayed(const Duration(seconds: 5,));
    _isAvailableTooltipSuperlike = false;
    if(mounted){
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showTooltipSuperlike && !_hasShownTooltipSuperlike) {
      _hasShownTooltipSuperlike = true;
      _showTooltipSuperlike();
    }

    return GestureDetector(
      onTap: (){
        if(widget.onOpen != null){
          widget.onOpen!();
          return;
        }

        _showDialogDisponibilidad2();
      },
      child: _contenido(),
    );
  }

  Widget _contenido(){
    return Container(
      decoration: const BoxDecoration(
        //borderRadius: BorderRadius.circular(10),
        //border: Border.all(color: constants.grey, width: 0.5,),
        color: Colors.white,
      ),
      padding: widget.disponibilidad.isAutor
          ? const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16,)
          : const EdgeInsets.only(left: 16, top: 24, right: 16, bottom: 24,),
      child: Row(children: [
        GestureDetector(
          onTap: (){
            // TODO : obtener los datos completos del usuario en disponibilidad.creador
            Navigator.push(context,
              MaterialPageRoute(builder: (context) => UserPage(
                usuario: Usuario(id: widget.disponibilidad.creador.id, nombre: "", username: "", foto: widget.disponibilidad.creador.foto,),
              )),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: constants.greyLight, width: 0.5,),
            ),
            height: 32,
            width: 32,
            child: CircleAvatar(
              //backgroundColor: constants.greyBackgroundImage,
              backgroundColor: const Color(0xFFFAFAFA),
              backgroundImage: CachedNetworkImageProvider(widget.disponibilidad.creador.foto),
            ),
          ),
        ),

        const SizedBox(width: 12,),

        Expanded(child: Column(children: [

          Row(children: [

            Flexible(child: GestureDetector(
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
                    style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4,),
                if(widget.disponibilidad.creador.isVerificadoUniversidad)
                  const IconUniversidadVerificada(size: 14),
                const SizedBox(width: 4,),
              ],),
            ),),

            Row(children: [
              if(widget.disponibilidad.distanciaTexto != null)
                Text("${widget.disponibilidad.distanciaTexto ?? '' } • ",
                  style: const TextStyle(color: constants.greyLight, fontSize: 12,),
                  maxLines: 1,
                ),
              Text(widget.disponibilidad.fecha,
                style: const TextStyle(color: constants.greyLight, fontSize: 12,),
                maxLines: 1,
              ),
            ], mainAxisSize: MainAxisSize.min,),

          ], mainAxisAlignment: MainAxisAlignment.spaceBetween,),

          const SizedBox(height: 8,),

          Row(children: [

            Flexible(child: Text(widget.disponibilidad.texto,
              style: const TextStyle(color: constants.blackGeneral, fontSize: 16,
                height: 1.3, fontWeight: FontWeight.w500,),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),),

            /*
            if((widget.isCreadorActividadVisible ?? false) && !widget.disponibilidad.isAutor)
              InkWell(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => InvitarActividadPage(invitacionDisponibilidadCreador: widget.disponibilidad.creador,),
                  ));
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 8,),
                  child: Icon(Icons.group_add_outlined, size: 24, color: constants.blueGeneral,),
                ),
              ),
             */

          ], mainAxisAlignment: MainAxisAlignment.spaceBetween,),

          const SizedBox(height: 8,),

          Row(children: [
            if(!(widget.isAutorActividadVisible ?? false) && !widget.disponibilidad.isAutor)
              OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => CrearActividadPage(
                      fromDisponibilidad: widget.disponibilidad,
                      fromPantalla: CrearActividadFromPantalla.card_disponibilidad,
                    ),
                  ));
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.add_rounded, size: 14,),
                  SizedBox(width: 2),
                  Text("Crear", style: TextStyle(fontSize: 10,),),
                ],),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8,),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  primary: Colors.lightBlue,
                  side: const BorderSide(width: 0.5, color: Colors.lightBlue),
                  minimumSize: const Size(0, 0),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),

            const SizedBox(width: 8),

            if(!widget.disponibilidad.creador.isSuperliked && !widget.disponibilidad.isAutor)
              Stack(children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.heart, size: 24, color: Colors.lightGreen,),
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
                      fromPantalla: SuperlikeServiceFromPantalla.card_disponibilidad,
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0,),
                ),
                if(_isAvailableTooltipSuperlike)
                  Positioned(
                    child: Container(
                      decoration: ShapeDecoration(
                        shape: _CustomShapeBorder(),
                        color: Colors.grey[700]?.withOpacity(0.9),
                      ),
                      constraints: const BoxConstraints(maxWidth: 160,),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8,),
                      child: Text((widget.isAutorActividadVisible ?? false)
                          ? "Envía Incentivos anónimos para que revise las actividades creadas"
                          : "Envía Incentivos anónimos para animar a crear una actividad",
                        style: const TextStyle(color: Colors.white, fontSize: 12,),
                      ),
                    ),
                    //bottom: 56,
                    bottom: 40,
                    right: 0,
                  ),
              ], clipBehavior: Clip.none,),
            if(widget.disponibilidad.creador.isSuperliked && !widget.disponibilidad.isAutor)
              IconButton(
                icon: _superlikeEnviadoAhora
                    ? const Icon(CupertinoIcons.heart_fill, size: 24, color: Colors.lightGreen,)
                    : const Icon(CupertinoIcons.heart, size: 24, color: constants.greyLight,),
                onPressed: (){
                  SuperlikeService.intentarPresionarSuperliked(
                    usuarioNombre: widget.disponibilidad.creador.nombre,
                    context: context,
                  );
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0,),
              ),
          ], mainAxisAlignment: MainAxisAlignment.end,),

          /*
          if((widget.isAutorActividadVisible ?? false) && !widget.disponibilidad.isAutor)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: (widget.disponibilidad.creador.isMatchLiked ?? false)
                    ? (){}
                    : _enviandoMatchLike ? null : () => _enviarMatchLike(),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon((widget.disponibilidad.creador.isMatchLiked ?? false)
                      ? Icons.thumb_up
                      : Icons.thumb_up_off_alt,
                    size: 16, color: Colors.lightGreen,),
                ],),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 0,),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(48, 36),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),
          */

        ],)),
      ], crossAxisAlignment: CrossAxisAlignment.start,),
    );
  }

  void _showDialogDisponibilidad(){
    showDialog(context: context, builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48,),
        child: SingleChildScrollView(child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16,),
          child: Column(children: [

            Row(children: [
              GestureDetector(
                onTap: (){
                  /*Navigator.pop(context);
                  _showDialogUsuarioDatos();*/

                  // TODO : obtener los datos completos del usuario en disponibilidad.creador
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserPage(
                      usuario: Usuario(id: widget.disponibilidad.creador.id, nombre: "", username: "", foto: widget.disponibilidad.creador.foto,),
                    )),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: constants.greyLight, width: 0.5,),
                  ),
                  height: 25,
                  width: 25,
                  child: CircleAvatar(
                    //backgroundColor: constants.greyBackgroundImage,
                    backgroundColor: const Color(0xFFFAFAFA),
                    backgroundImage: CachedNetworkImageProvider(widget.disponibilidad.creador.foto),
                  ),
                ),
              ),

              const SizedBox(width: 12,),

              Expanded(child: Column(children: [
                //const SizedBox(height: 4,),

                Row(children: [

                  Flexible(
                    child: GestureDetector(
                      onTap: (){
                        /*Navigator.pop(context);
                        _showDialogUsuarioDatos();*/

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
                            style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4,),
                        if(widget.disponibilidad.creador.isVerificadoUniversidad)
                          const IconUniversidadVerificada(size: 16),
                        const SizedBox(width: 4,),
                      ],),
                    ),
                  ),

                  Text(widget.disponibilidad.fecha,
                    style: const TextStyle(color: constants.grey, fontSize: 12,),
                    maxLines: 1,
                  ),

                  if(widget.disponibilidad.isAutor)
                    ...[
                      const SizedBox(width: 2,),
                      InkWell(
                        onTap: (){
                          _showDialogOpciones();
                        },
                        child: const Icon(Icons.more_horiz, color: Colors.black54,),
                      ),
                    ],

                ], mainAxisAlignment: MainAxisAlignment.spaceBetween,),

                const SizedBox(height: 16,),

                Text(widget.disponibilidad.texto,
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 16,
                    height: 1.3, fontWeight: FontWeight.w500,),
                  textAlign: TextAlign.left,
                ),

              ], mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,)),

            ], crossAxisAlignment: CrossAxisAlignment.start,),


            const SizedBox(height: 24,),

            if(!(widget.isCreadorActividadVisible ?? false) || widget.disponibilidad.isAutor)
              Text(widget.disponibilidad.isAutor
                  ? "Esto es un estado."
                  : "Esto es un estado. ¡Crea una actividad y envía una invitación a ${widget.disponibilidad.creador.nombre} para unirse!",
                style: const TextStyle(color: constants.blackGeneral, fontSize: 12, height: 1.3,),
                textAlign: TextAlign.center,
              ),

            if(!(widget.isCreadorActividadVisible ?? false) && !widget.disponibilidad.isAutor)
              ...[

                const SizedBox(height: 16,),

                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  child: ElevatedButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => CrearActividadPage(fromDisponibilidad: widget.disponibilidad,),
                      ));
                    },
                    child: const Text("Crear actividad"),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                  ),
                ),

              ],

            if((widget.isCreadorActividadVisible ?? false) && !widget.disponibilidad.isAutor)
              ...[
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  child: TextButton.icon(
                    onPressed: (){
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => InvitarActividadPage(invitacionDisponibilidadCreador: widget.disponibilidad.creador,),
                      ));
                    },
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text("Invitar a actividad"),
                    style: TextButton.styleFrom(
                      shape: const StadiumBorder(),
                    ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                  ),
                ),
              ],

            const SizedBox(height: 16,),

          ]),
        ),)
      );
    });
  }

  void _showDialogDisponibilidad2(){
    showDialog(context: context, builder: (context) {
      return Dialog(
          //insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48,),
          child: SingleChildScrollView(child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16,),
            child: Column(children: [

              if(widget.disponibilidad.isAutor)
                ...[
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: (){
                        _showDialogOpciones();
                      },
                      child: const Icon(Icons.more_horiz, color: Colors.black54,),
                    ),
                  ),
                ],

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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(widget.disponibilidad.texto,
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 18, height: 1.3, fontWeight: FontWeight.bold,),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24,),


              if(!(widget.isCreadorActividadVisible ?? false) && !widget.disponibilidad.isAutor)
                ...[
                  const SizedBox(height: 16,),
                  const Text("Crea una actividad y envía invitaciones:",
                    style: TextStyle(color: constants.grey, fontSize: 12, height: 1.3,),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16,),
                  Container(
                    constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                    child: TextButton.icon(
                      onPressed: (){
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => CrearActividadPage(fromDisponibilidad: widget.disponibilidad,),
                        ));
                      },
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text("Invitar"),
                      style: TextButton.styleFrom(
                        shape: const StadiumBorder(),
                      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                    ),
                  ),
                ],

              if((widget.isCreadorActividadVisible ?? false) && !widget.disponibilidad.isAutor)
                ...[
                  Container(
                    constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                    child: TextButton.icon(
                      onPressed: (){
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => InvitarActividadPage(invitacionDisponibilidadCreador: widget.disponibilidad.creador,),
                        ));
                      },
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text("Invitar a mi actividad"),
                      style: TextButton.styleFrom(
                        shape: const StadiumBorder(),
                      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                    ),
                  ),
                ],

              const SizedBox(height: 16,),

            ]),
          ),)
      );
    });
  }


  void _showDialogUniversidadVerificada(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            RichText(
              textAlign: TextAlign.left,
              text: const TextSpan(
                style: TextStyle(color: constants.blackGeneral, fontSize: 16, fontWeight: FontWeight.bold,),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8,),
                      child: IconUniversidadVerificada(size: 25),
                    ),
                  ),
                  TextSpan(
                    text: "Universidad verificada",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16,),
            Text("Este perfil cuenta con un correo verificado de la ${widget.disponibilidad.creador.verificadoUniversidadNombre ?? ""}.",
              style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
              textAlign: TextAlign.left,
            ),
          ], mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      );
    });
  }

  void _showDialogUsuarioDatos(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [

            const SizedBox(height: 16,),

            CircleAvatar(
              radius: 48,
              backgroundImage: CachedNetworkImageProvider(widget.disponibilidad.creador.foto),
              backgroundColor: Colors.transparent,
            ),

            const SizedBox(height: 16,),

            Row(children: [
              Flexible(
                child: Text(widget.disponibilidad.creador.nombre,
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 18,),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4,),
              if(widget.disponibilidad.creador.isVerificadoUniversidad)
                const IconUniversidadVerificada(size: 16),
              const SizedBox(width: 4,),
            ], mainAxisSize: MainAxisSize.min,),

            const SizedBox(height: 24,),

            if(widget.disponibilidad.creador.descripcion != null)
              ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(widget.disponibilidad.creador.descripcion ?? "",
                    style: const TextStyle(color: constants.grey, fontSize: 14, height: 1.3,),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 24,),
              ],

            if(widget.disponibilidad.creador.universidadNombre != null)
              ...[
                Row(children: [
                  const Icon(Icons.school_outlined, size: 20, color: constants.blackGeneral,),
                  const SizedBox(width: 8,),
                  Text(widget.disponibilidad.creador.universidadNombre ?? "",
                    style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
                  ),
                ],),
                const SizedBox(height: 16,),
              ],

          ], mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,),
        ),
      );
    });
  }


  void _showDialogOpciones(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        content: Column(children: [
          ListTile(
            title: const Text("Eliminar estado"),
            onTap: (){
              Navigator.of(context).pop();
              _showDialogEliminarActividad();
            },
          ),
        ], mainAxisSize: MainAxisSize.min,),
      );
    });
  }

  void _showDialogEliminarActividad(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Eliminar estado?', style: TextStyle(fontSize: 16),),
          // TODO : cambiar texto (si tiene otras publicaciones, este texto no tiene sentido)
          content: const Text('Al eliminar esta visualización, perderás la capacidad de ver las nuevas actividades que '
              'otros usuarios creen en el día. ¿Estás seguro de que deseas continuar?',
            style: TextStyle(fontSize: 14,),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: _enviandoEliminarDisponibilidad ? null : () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Eliminar'),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
              onPressed: _enviandoEliminarDisponibilidad ? null : () => _eliminarDisponibilidad(setStateDialog),
            ),
          ],
        );
      });
    });
  }

  Future<void> _eliminarDisponibilidad(setStateDialog) async {
    setStateDialog(() {
      _enviandoEliminarDisponibilidad = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlEliminarDisponibilidad,
      body: {
        "disponibilidad_id": widget.disponibilidad.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) => const PrincipalPage()
        ), (route) => false);

      } else {
        Navigator.pop(context);

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoEliminarDisponibilidad = false;
    });
  }


  Future<void> _enviarMatchLike() async {
    widget.disponibilidad.creador.isMatchLiked = true;

    setState(() {
      _enviandoMatchLike = true;
    });

    // Actualiza la disponibilidad que abrio este widget
    if(widget.onChangeDisponibilidad != null) widget.onChangeDisponibilidad!(widget.disponibilidad);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadEnviarMatchLikeIntegrante,
      body: {
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

          //Navigator.pop(context);
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

class _CustomShapeBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(10)))
      ..moveTo(rect.left + rect.width - 20 - 10, rect.bottom)
      ..lineTo(rect.left + rect.width - 20, rect.bottom + 10)
      ..lineTo(rect.left + rect.width - 20 + 10, rect.bottom);

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return _CustomShapeBorder();
  }
}