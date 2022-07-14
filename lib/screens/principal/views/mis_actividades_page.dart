import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/models/actividad.dart';
import 'package:nuevoproyectouno/models/chat.dart';
import 'package:nuevoproyectouno/models/usuario.dart';
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/screens/mis_actividades_antiguas/mis_actividades_antiguas_page.dart';
import 'package:nuevoproyectouno/services/http_service.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:nuevoproyectouno/widgets/card_actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MisActividadesPage extends StatefulWidget {
  @override
  State<MisActividadesPage> createState() => _MisActividadesPageState();
}

class _MisActividadesPageState extends State<MisActividadesPage> {

  List<Actividad> _actividades = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingActividades = false;
  bool _verMasActividades = false;
  String _ultimoActividades = "false";

  @override
  void initState() {
    super.initState();

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
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              //Navigator.push(context, MaterialPageRoute(builder: (context) => InboxPage()));
            },
          ),
        ],
      ),
      body: (_actividades.isEmpty) ? Center(

        child: _loadingActividades ? CircularProgressIndicator() : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
                text: "No tienes actividades disponibles.\nCrea una ",
                children: [
                  WidgetSpan(
                    child: Icon(Icons.add_circle_outline, color: constants.blackGeneral,),
                    alignment: PlaceholderAlignment.middle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8,),
            _buildBotonVerAnteriores(),
          ], mainAxisSize: MainAxisSize.min,),
        ),

      ) : ListView.builder(
        controller: _scrollController,
        itemCount: _actividades.length + 2, // +1 mostrar texto cabecera, +1 mostrar cargando o boton
        itemBuilder: (context, index){
          if(index == 0){
            return _buildTextoCabecera();
          }

          index = index - 1;

          if(index == _actividades.length){

            if(_loadingActividades){
              return _buildLoadingActividades();
            } else {
              return Container(
                alignment: Alignment.center,
                child: _buildBotonVerAnteriores(),
              );
            }

          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: CardActividad(actividad: _actividades[index]),
          );
        },
      ),
    );
  }

  Widget _buildTextoCabecera(){
    return const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
      child: Text("Se muestran las actividades donde eres co-creador y que están visibles actualmente.",
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