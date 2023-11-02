import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/icon_universidad_verificada.dart';

class CardDisponibilidad extends StatefulWidget {
  CardDisponibilidad({Key? key, required this.disponibilidad, this.isCreadorActividadVisible}) : super(key: key);

  Disponibilidad disponibilidad;
  bool? isCreadorActividadVisible;

  @override
  _CardDisponibilidadState createState() => _CardDisponibilidadState();
}

class _CardDisponibilidadState extends State<CardDisponibilidad> {

  bool _enviandoEliminarDisponibilidad = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        _showDialogDisponibilidad();
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
      padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 12,),
      child: Row(children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: constants.greyLight, width: 0.5,),
          ),
          height: 20,
          width: 20,
          child: CircleAvatar(
            backgroundColor: constants.greyBackgroundImage,
            backgroundImage: NetworkImage(widget.disponibilidad.creador.foto),
          ),
        ),

        const SizedBox(width: 12,),

        Expanded(child: Column(children: [

          Row(children: [

            Flexible(child: Row(children: [
              Flexible(
                child: Text(widget.disponibilidad.creador.nombre,
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4,),
              if(widget.disponibilidad.creador.isVerificadoUniversidad)
                const IconUniversidadVerificada(size: 12),
              const SizedBox(width: 4,),
            ],)),

            Text(widget.disponibilidad.fecha,
              style: const TextStyle(color: constants.greyLight, fontSize: 12,),
              maxLines: 1,
            ),

          ], mainAxisAlignment: MainAxisAlignment.spaceBetween,),

          const SizedBox(height: 4,),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.disponibilidad.texto,
              style: const TextStyle(color: constants.blackGeneral, fontSize: 14,
                height: 1.3, fontWeight: FontWeight.w500,),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),

        ],)),
      ],),
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
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: constants.greyLight, width: 0.5,),
                ),
                height: 25,
                width: 25,
                child: CircleAvatar(
                  backgroundColor: constants.greyBackgroundImage,
                  backgroundImage: NetworkImage(widget.disponibilidad.creador.foto),
                ),
              ),

              const SizedBox(width: 12,),

              Expanded(child: Column(children: [
                //const SizedBox(height: 4,),

                Row(children: [

                  Flexible(child: Row(children: [
                    Flexible(
                      child: Text(widget.disponibilidad.creador.nombre,
                        style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4,),
                    if(widget.disponibilidad.creador.isVerificadoUniversidad)
                      GestureDetector(
                        onTap: (){
                          _showDialogUniversidadVerificada();
                        },
                        child: const IconUniversidadVerificada(size: 16),
                      ),
                    const SizedBox(width: 4,),
                  ],)),

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

            Text((widget.isCreadorActividadVisible ?? false) || widget.disponibilidad.isAutor
                ? "Esto es un estado de visualización."
                : "Esto es un estado de visualización. Crea una actividad para que "
                "otros usuarios como ${widget.disponibilidad.creador.nombre} puedan unirse.",
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
                        builder: (context) => const CrearActividadPage(),
                      ));
                    },
                    child: const Text("Crear actividad"),
                    style: ElevatedButton.styleFrom(
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


  void _showDialogOpciones(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        content: Column(children: [
          ListTile(
            title: const Text("Eliminar visualización"),
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
          title: const Text('¿Eliminar visualización?', style: TextStyle(fontSize: 16),),
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

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}