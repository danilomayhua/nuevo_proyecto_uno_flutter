import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/invitacion_actividad.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class InvitarActividadPage extends StatefulWidget {
  const InvitarActividadPage({Key? key, required this.invitacionDisponibilidadCreador}) : super(key: key);

  final DisponibilidadCreador invitacionDisponibilidadCreador;

  @override
  State<InvitarActividadPage> createState() => _InvitarActividadPageState();
}

class _InvitarActividadPageState extends State<InvitarActividadPage> {

  List<InvitacionActividad> _invitacionActividades = [];
  bool _loadingInvitacionActividades = false;

  String? _enviandoActividadId;

  @override
  void initState() {
    super.initState();

    _cargarInvitacionActividades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invitar a actividad"),
      ),
      body: _loadingInvitacionActividades ? const Center(child: CircularProgressIndicator()) : SafeArea(
        child: Column(children: [

          const SizedBox(height: 16,),

          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16,),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4,),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: constants.grey, width: 0.5,),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: constants.greyBackgroundImage,
                    backgroundImage: CachedNetworkImageProvider(widget.invitacionDisponibilidadCreador.foto),
                    radius: 16,
                  ),
                  const SizedBox(width: 8,),
                  Text(widget.invitacionDisponibilidadCreador.nombre, style: const TextStyle(fontSize: 14),),
                  const SizedBox(width: 8,),
                ],
                mainAxisSize: MainAxisSize.min,
              ),
            ),
          ),

          const SizedBox(height: 16,),

          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text("Selecciona una actividad para invitar:",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
              textAlign: TextAlign.left,
            ),
          ),

          const SizedBox(height: 16,),

          Expanded(child: ListView.builder(
            itemCount: _invitacionActividades.length,
            itemBuilder: (context, index){

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: _buildInvitacionActividad(_invitacionActividades[index]),
              );

            },
          )),

        ]),
      ),
    );
  }

  Widget _buildInvitacionActividad(InvitacionActividad invitacionActividad){
    return InkWell(
      onTap: _enviandoActividadId == null ? (){

        _invitar(invitacionActividad);

      } : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: constants.grey, width: 0.5,),
          color: Colors.white,
        ),
        padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 12,),
        child: Stack(children: [
          Column(children: [

            Row(children: [
              const Spacer(),
              SizedBox(
                width: (15 * invitacionActividad.creadores.length) + 10,
                height: 20,
                child: Stack(
                  children: [
                    Container(),
                    for (int i=(invitacionActividad.creadores.length-1); i>=0; i--)
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
                            backgroundColor: constants.greyBackgroundImage,
                            backgroundImage: CachedNetworkImageProvider(invitacionActividad.creadores[i].foto),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(invitacionActividad.fecha,
                style: const TextStyle(color: constants.greyLight, fontSize: 12,),
              ),
            ], mainAxisAlignment: MainAxisAlignment.end,),

            const SizedBox(height: 18,),

            Align(
              alignment: Alignment.center,
              child: Text(invitacionActividad.titulo,
                style: const TextStyle(color: constants.blackGeneral, fontSize: 16,
                  height: 1.3, /*fontWeight: FontWeight.w500,*/),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24,),

            Row(children: [
              if(_enviandoActividadId == invitacionActividad.actividadId)
                ...[
                    Container(
                    width: 24,
                    height: 24,
                    child: const CircularProgressIndicator(),
                  ),
                  const SizedBox(width: 16,),
                ],

              Align(
                alignment: Alignment.center,
                child: Text("Invitaciones ${invitacionActividad.invitacionesRealizadas}/${invitacionActividad.invitacionesTotal}",
                  style: const TextStyle(color: constants.blueGeneral, fontSize: 12, fontWeight: FontWeight.bold,),
                  textAlign: TextAlign.center,
                ),
              ),
            ], mainAxisAlignment: MainAxisAlignment.center,),

            const SizedBox(height: 8,),

          ], crossAxisAlignment: CrossAxisAlignment.start,),
        ]),
      ),
    );
  }

  Future<void> _cargarInvitacionActividades() async {
    setState(() {
      _loadingInvitacionActividades = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlActividadInvitacionActividadesParaInvitar,
      queryParams: {
        "usuario_id": widget.invitacionDisponibilidadCreador.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        List<dynamic> invitacionActividades = datosJson['data']['invitacion_actividades'];
        for (var element in invitacionActividades) {

          List<Usuario> creadores = [];
          element['creadores'].forEach((usuario) {
            creadores.add(Usuario(
              id: usuario['id'],
              nombre: usuario['nombre_completo'],
              username: usuario['username'],
              foto: constants.urlBase + usuario['foto_url'],
            ));
          });

          _invitacionActividades.add(InvitacionActividad(
            actividadId: element['id'],
            titulo: element['titulo'],
            fecha: element['fecha_texto'],
            creadores: creadores,
            isUsuarioInvitado: element['es_invitado'],
            invitacionesRealizadas: element['invitaciones_realizadas'],
            invitacionesTotal: element['invitaciones_total'],
          ));

        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingInvitacionActividades = false;
    });
  }

  Future<void> _invitar(InvitacionActividad invitacionActividad) async {
    setState(() {
      _enviandoActividadId = invitacionActividad.actividadId;
    });

    if(invitacionActividad.isUsuarioInvitado){
      _showDialogInvitacionRepetida();
      setState(() {_enviandoActividadId = null;});
      return;
    }
    if(invitacionActividad.invitacionesRealizadas >= invitacionActividad.invitacionesTotal){
      _showDialogInvitacionLimite();
      setState(() {_enviandoActividadId = null;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadInvitacionInvitar,
      body: {
        "actividad_id": invitacionActividad.actividadId,
        "usuario_id": widget.invitacionDisponibilidadCreador.id,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pop(context);
        _showSnackBar("¡Invitación enviada!");

      } else {
        if(datosJson['error_tipo'] == 'es_invitado'){

          _showDialogInvitacionRepetida();

        } else {
          _showSnackBar("Se produjo un error inesperado");
        }
      }
    }

    setState(() {
      _enviandoActividadId = null;
    });
  }

  void _showDialogInvitacionRepetida(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            Text("${widget.invitacionDisponibilidadCreador.nombre} ya recibió una invitación para esta actividad anteriormente.",
              style: const TextStyle(color: constants.blackGeneral, fontSize: 16, height: 1.3,),
              textAlign: TextAlign.left,
            ),
          ], mainAxisSize: MainAxisSize.min,),
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

  void _showDialogInvitacionLimite(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("Ya has alcanzado el límite de invitaciones para esta actividad.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16, height: 1.3,),
              textAlign: TextAlign.left,
            ),
          ], mainAxisSize: MainAxisSize.min,),
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

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}