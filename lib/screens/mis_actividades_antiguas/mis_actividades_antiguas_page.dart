import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/card_actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MisActividadesAntiguasPage extends StatefulWidget {
  const MisActividadesAntiguasPage({Key? key}) : super(key: key);

  @override
  State<MisActividadesAntiguasPage> createState() => _MisActividadesAntiguasPageState();
}

class _MisActividadesAntiguasPageState extends State<MisActividadesAntiguasPage> {

  List<Actividad> _actividades = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingActividades = false;
  bool _verMasActividades = false;
  String _ultimoActividades = "false";

  @override
  void initState() {
    super.initState();

    _cargarMisActividadesNoVisibles();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingActividades && _verMasActividades){
          _cargarMisActividadesNoVisibles();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis actividades"),
      ),
      body: (_actividades.isEmpty) ? Center(

        child: _loadingActividades ? CircularProgressIndicator() : const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Aquí se mostrarán tus actividades que ya no estén visibles en Inicio. Las actividades dejan de estar visibles pasadas las 48 horas.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ),

      ) : ListView.builder(
        controller: _scrollController,
        itemCount: _actividades.length + 2, // +1 mostrar texto cabecera, +1 mostrar cargando
        itemBuilder: (context, index){
          if(index == 0){
            return _buildTextoCabecera();
          }

          index = index - 1;

          if(index == _actividades.length){
            return _buildLoadingActividades();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: CardActividad(actividad: _actividades[index]),
          );
        },
      ),
    );
  }

  Widget _buildTextoCabecera(){
    return const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
      child: Text("Las actividades dejan de estar visibles pasadas las 48 horas. Estas actividades ya no están visibles en Inicio para ningún usuario.",
        style: TextStyle(color: constants.grey, fontSize: 12,),
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

  Future<void> _cargarMisActividadesNoVisibles() async {
    setState(() {
      _loadingActividades = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlMisActividadesNoVisibles,
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

          _actividades.add(actividad);

        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingActividades = false;
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