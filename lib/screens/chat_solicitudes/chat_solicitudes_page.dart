import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_chat_solicitud.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class ChatSolicitudesPage extends StatefulWidget {
  const ChatSolicitudesPage({Key? key, required this.actividad, this.isFromActividad = false}) : super(key: key);

  final Actividad actividad;
  final bool isFromActividad;

  @override
  State<ChatSolicitudesPage> createState() => _ChatSolicitudesPageState();
}

class _ChatSolicitudesPageState extends State<ChatSolicitudesPage> {
  List<UsuarioChatSolicitud> _usuariosPendientes = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingUsuariosPendientes = false;
  bool _verMasUsuariosPendientes = false;
  String _ultimoUsuariosPendientes = "false";

  bool _enviandoAceptarSolicitud = false;
  String _usuarioIdEnviado = "";

  @override
  void initState() {
    super.initState();

    _loadingUsuariosPendientes = false;
    _verMasUsuariosPendientes = false;
    _ultimoUsuariosPendientes = "false";

    _cargarUsuariosPendientes();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingUsuariosPendientes && _verMasUsuariosPendientes){
          _cargarUsuariosPendientes();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitudes para unirse"),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildActividad()),

          (_usuariosPendientes.isEmpty && !_loadingUsuariosPendientes)
            ? SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const Text("No tienes solicitudes para unirse al chat grupal.",
                  style: TextStyle(color: constants.grey, fontSize: 14,),
                  textAlign: TextAlign.center,
                ),
              ),
            )

            : SliverList(delegate: SliverChildBuilderDelegate((context, index){

              if(index == _usuariosPendientes.length){
                return _buildLoadingUsuarios();
              }

              return _buildUsuarioPendiente(_usuariosPendientes[index], index);

            }, childCount: _usuariosPendientes.length + 1,)),
        ],
      ),
    );
  }

  Widget _buildActividad(){
    return GestureDetector(
      onTap: (){
        /*if(!widget.isFromActividad){
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => ActividadPage(actividad: widget.actividad)
          ));
        };*/
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: constants.grey),
          color: Colors.white,
        ),
        margin: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 24,),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16,),
        child: Column(children: [
          Text(widget.actividad.titulo,
            style: const TextStyle(color: constants.blackGeneral, fontSize: 18, height: 1.3,),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          /*
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(widget.actividad.descripcion ?? "",
              style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.4,),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          */
        ], crossAxisAlignment: CrossAxisAlignment.start),
      ),
    );
  }

  Widget _buildUsuarioPendiente(UsuarioChatSolicitud usuarioPendiente, index){
    Usuario usuario = usuarioPendiente.usuario;

    return ListTile(
      title: Text(usuario.nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(usuario.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: CachedNetworkImageProvider(usuario.foto),
      ),
      trailing: !usuarioPendiente.aceptado // No es necesario
          ? OutlinedButton(
            onPressed: (!_enviandoAceptarSolicitud)
                ? () => _aceptarSolicitudUnirse(usuarioPendiente, index)
                : (_usuarioIdEnviado == usuarioPendiente.usuario.id) ? null : (){},
            child: const Text("Aceptar", style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              primary: constants.blackGeneral,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8,),
            ),
          )
          : OutlinedButton(
            onPressed: (){},
            child: const Text("Aceptado", style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              primary: constants.blueGeneral,
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Colors.transparent, width: 0.5,),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8,),
            ),
          ),
      onTap: (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UserPage(usuario: usuario,)),
        );
      },
    );
  }

  Widget _buildLoadingUsuarios(){
    if(_loadingUsuariosPendientes){
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

  Future<void> _cargarUsuariosPendientes() async {
    setState(() {
      _loadingUsuariosPendientes = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlActividadSolicitudes,
      queryParams: {
        "actividad_id": widget.actividad.id,
        "ultimo_id": _ultimoUsuariosPendientes
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoUsuariosPendientes = datosJson['data']['ultimo_id'].toString();
        _verMasUsuariosPendientes = datosJson['data']['ver_mas'];

        List<dynamic> usuarios = datosJson['data']['usuarios'];
        for (var element in usuarios) {

          Usuario usuario = Usuario(
            id: element['id'],
            nombre: element['nombre_completo'],
            username: element['username'],
            foto: constants.urlBase + element['foto_url'],
          );

          _usuariosPendientes.add(UsuarioChatSolicitud(
            usuario: usuario,
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingUsuariosPendientes = false;
    });
  }

  Future<void> _aceptarSolicitudUnirse(UsuarioChatSolicitud usuarioPendiente, index) async {
    setState(() {
      _enviandoAceptarSolicitud = true;
      _usuarioIdEnviado = usuarioPendiente.usuario.id;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadAceptarSolicitud,
      body: {
        "actividad_id": widget.actividad.id,
        "usuario_id": usuarioPendiente.usuario.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        usuarioPendiente.aceptado = true; // No es necesario
        _usuariosPendientes.removeAt(index);

      } else {

        if(datosJson['error_tipo'] == 'limite_integrantes'){
          _showDialogGrupoLleno();
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoAceptarSolicitud = false;
      _usuarioIdEnviado = "";
    });
  }

  void _showDialogGrupoLleno(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        title: const Text("Grupo lleno"),
        content: const Text("El chat grupal alcanzó el límite de integrantes. No pueden ingresar más usuarios.",
          //textAlign: TextAlign.center,
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