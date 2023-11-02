import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/publicacion.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/mis_actividades_antiguas/mis_actividades_antiguas_page.dart';
import 'package:tenfo/screens/notificaciones/notificaciones_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/card_actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/widgets/card_disponibilidad.dart';

class MisActividadesPage extends StatefulWidget {
  const MisActividadesPage({Key? key, required this.showBadgeNotificaciones,
    required this.setShowBadge}) : super(key: key);

  final bool showBadgeNotificaciones;
  final void Function(bool) setShowBadge;

  @override
  State<MisActividadesPage> createState() => MisActividadesPageState();
}

class MisActividadesPageState extends State<MisActividadesPage> {

  List<Publicacion> _publicaciones = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingActividades = false;
  bool _verMasActividades = false;
  String _ultimoActividades = "false";

  bool _showBadgeNotificaciones = false;

  @override
  void initState() {
    super.initState();

    _showBadgeNotificaciones = widget.showBadgeNotificaciones;

    _cargarMisActividades();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingActividades && _verMasActividades){
          _cargarMisActividades();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Mis actividades"),
        actions: [
          Badge(
            child: IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotificacionesPage()));
                setState(() {
                  _showBadgeNotificaciones = false;
                });
                widget.setShowBadge(false);
              },
            ),
            showBadge: _showBadgeNotificaciones,
            badgeColor: constants.blueGeneral,
            padding: EdgeInsets.all(6),
            position: BadgePosition.topEnd(top: 12, end: 12,),
          ),
        ],
      ),
      body: (_publicaciones.isEmpty) ? Center(

        child: _loadingActividades ? CircularProgressIndicator() : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            const Text("No hay actividades tuyas visibles actualmente. Las actividades duran 48 horas visibles.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8,),
            _buildBotonVerAnteriores(),
          ], mainAxisSize: MainAxisSize.min,),
        ),

      ) : ListView.builder(
        controller: _scrollController,
        itemCount: _publicaciones.length + 2, // +1 mostrar texto cabecera, +1 mostrar cargando o boton
        itemBuilder: (context, index){
          if(index == 0){
            return _buildTextoCabecera();
          }

          index = index - 1;

          if(index == _publicaciones.length){

            if(_loadingActividades){
              return _buildLoadingActividades();
            } else {
              return Container(
                alignment: Alignment.center,
                child: _buildBotonVerAnteriores(),
              );
            }

          }

          if(_publicaciones[index].tipo == PublicacionTipo.ACTIVIDAD){
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: CardActividad(actividad: _publicaciones[index].actividad!),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: CardDisponibilidad(
                disponibilidad: _publicaciones[index].disponibilidad!,
                isCreadorActividadVisible: true, // No importa este valor real, ya que es el autor
              ),
            );
          }

        },
      ),
    );
  }

  Widget _buildTextoCabecera(){
    return const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
      child: Text("Aquí se muestran las visualizaciones y actividades donde eres cocreador. Estarán visibles solo 48 horas.",
        style: TextStyle(color: constants.grey, fontSize: 12,),
      ),
    );
  }

  Widget _buildBotonVerAnteriores(){
    return TextButton(
      onPressed: (){
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => MisActividadesAntiguasPage(),
        ));
      },
      child: const Text("Ver anteriores"),
      style: TextButton.styleFrom(
        textStyle: TextStyle(fontSize: 12,),
      ),
    );
  }

  Widget _buildLoadingActividades(){
    if(_loadingActividades){
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Container();
    }
  }

  Future<void> _cargarMisActividades() async {
    setState(() {
      _loadingActividades = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlMisActividades,
      queryParams: {
        "ultimo_id": _ultimoActividades
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoActividades = datosJson['data']['ultimo_id'].toString();
        _verMasActividades = datosJson['data']['ver_mas'];


        // Solo la primera vez que carga trae valores en disponibilidades
        List<Disponibilidad> disponibilidadList = [];
        List<dynamic> disponibilidades = datosJson['data']['disponibilidades'];
        for (var element in disponibilidades) {
          disponibilidadList.add(Disponibilidad(
            id: element['id'],
            creador: DisponibilidadCreador(
              id: element['creador']['id'],
              foto: constants.urlBase + element['creador']['foto_url'],
              nombre: element['creador']['nombre'],
              isVerificadoUniversidad: element['creador']['is_verificado_universidad'],
              verificadoUniversidadNombre: element['creador']['verificado_universidad_nombre'],
            ),
            texto: element['texto'],
            fecha: element['fecha_texto'],
            isAutor: element['creador']['id'] == usuarioSesion.id,
          ));
        }
        for (Disponibilidad element in disponibilidadList) {
          _publicaciones.add(Publicacion(tipo: PublicacionTipo.DISPONIBILIDAD, disponibilidad: element,));
        }


        List<Actividad> actividadList = [];
        List<dynamic> actividades = datosJson['data']['actividades'];
        for (var element in actividades) {

          List<Usuario> creadores = [];
          element['creadores'].forEach((usuario) {
            creadores.add(Usuario(
              id: usuario['id'],
              nombre: usuario['nombre_completo'],
              username: usuario['username'],
              foto: constants.urlBase + usuario['foto_url'],
            ));
          });

          Actividad actividad = Actividad(
            id: element['id'],
            titulo: element['titulo'],
            descripcion: element['descripcion'],
            fecha: element['fecha_texto'],
            privacidadTipo: Actividad.getActividadPrivacidadTipoFromString(element['privacidad_tipo']),
            interes: element['interes_id'].toString(),
            creadores: creadores,
            ingresoEstado: Actividad.getActividadIngresoEstadoFromString(element['ingreso_estado']),
            isAutor: element['autor_usuario_id'] == usuarioSesion.id,
          );

          if(element['chat'] != null){
            Chat chat = Chat(
              id: element['chat']['id'].toString(),
              tipo: ChatTipo.GRUPAL,
              numMensajesPendientes: null,
              actividadChat: actividad,
            );
            actividad.chat = chat;
          }

          actividadList.add(actividad);

        }
        for (Actividad element in actividadList) {
          _publicaciones.add(Publicacion(tipo: PublicacionTipo.ACTIVIDAD, actividad: element,));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingActividades = false;
    });
  }

  void setShowBadgeNotificaciones(bool value){
    setState(() {
      _showBadgeNotificaciones = value;
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