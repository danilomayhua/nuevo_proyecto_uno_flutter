import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/mensaje.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/chat/chat_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class MensajesPage extends StatefulWidget {
  @override
  State<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends State<MensajesPage> {

  List<Chat> _chats = [];

  ScrollController _scrollController = ScrollController();
  bool _loadingChats = false;
  bool _verMasChats = false;
  String _ultimoChatId = "false";
  String _ultimoChatMensajeFecha = "false";
  
  bool _isOnRefresh = false;

  @override
  void initState() {
    super.initState();

    _loadingChats = false;
    _verMasChats = false;
    _ultimoChatId = "false";
    _ultimoChatMensajeFecha = "false";

    _cargarChats();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingChats && _verMasChats){
          _cargarChats();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Mensajes"),
      ),
      body: RefreshIndicator(
        backgroundColor: Colors.white,
        onRefresh: (){
          _chats = [];

          _loadingChats = false;
          _verMasChats = false;
          _ultimoChatId = "false";
          _ultimoChatMensajeFecha = "false";
          
          _isOnRefresh = true;

          return _cargarChats().then((value) => _isOnRefresh = false);
        },
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(), // Necesario para RefreshIndicator cuando hay pocos items
          itemCount: _chats.length + 1,
          itemBuilder: (context, index){
            if(index == _chats.length){
              return _buildLoadingChats();
            }

            return _buildChat(_chats[index]);
          },
        ),
      ),
    );
  }

  Widget _buildChat(Chat chat){
    return ListTile(
      title: Text(chat.tipo == ChatTipo.INDIVIDUAL ? chat.usuarioChat!.nombre : chat.actividadChat!.titulo,
        style: TextStyle(
          color: constants.blackGeneral,
          fontWeight: chat.numMensajesPendientes == 0 ? FontWeight.normal : FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitleChat(chat),
      leading: chat.tipo == ChatTipo.INDIVIDUAL ? CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: NetworkImage(chat.usuarioChat!.foto),
      ) : const CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: null,
        child: Icon(Icons.groups, color: constants.blackGeneral,),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(chat.ultimoMensaje!.fecha, style: TextStyle(color: constants.grey, fontSize: 12,),),
          const SizedBox(height: 4),
          Opacity(
            opacity: chat.numMensajesPendientes == 0 ? 0 : 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: constants.blueGeneral,
              ),
              child: Text(chat.numMensajesPendientes.toString(), style: TextStyle(fontSize: 11, color: Colors.white,),),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(context,
          MaterialPageRoute(
            builder: (context) => ChatPage(chat: chat),
          ),
        );
      },
    );
  }

  Widget _buildSubtitleChat(Chat chat){
    String msg = "";
    if(chat.ultimoMensaje!.tipo == MensajeTipo.NORMAL){
      msg = chat.ultimoMensaje!.contenido ?? ""; // Los MensajeTipo que no reconoce son devueltos como NORMAL (entonces puede no existir contenido)
    } else if(chat.ultimoMensaje!.tipo == MensajeTipo.GRUPO_INGRESO){
      msg = "Ingresó al chat.";
    } else if(chat.ultimoMensaje!.tipo == MensajeTipo.GRUPO_SALIDA){
      msg = "Salió del chat.";
    } else if(chat.ultimoMensaje!.tipo == MensajeTipo.GRUPO_ELIMINAR_USUARIO){
      msg = "Fue eliminado del chat.";
    } else if(chat.ultimoMensaje!.tipo == MensajeTipo.GRUPO_ENCUENTRO_FECHA){
      msg = "Cambió la fecha de encuentro.";
    } else if(chat.ultimoMensaje!.tipo == MensajeTipo.GRUPO_ENCUENTRO_LINK){
      msg = "Cambió el link de encuentro.";
    } else if(chat.ultimoMensaje!.tipo == MensajeTipo.PROPINA_STICKER){
      msg = "Envió un sticker.";
    }

    return Text(msg,
      style: TextStyle(
        fontWeight: chat.numMensajesPendientes == 0 ? FontWeight.normal : FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLoadingChats(){
    if(_loadingChats && !_isOnRefresh){
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

  Future<void> _cargarChats() async {
    setState(() {
      _loadingChats = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlBandejaChats,
      queryParams: {
        "ultimo_id": _ultimoChatId,
        "ultimo_mensaje_fecha": _ultimoChatMensajeFecha
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        datosJson = datosJson['data'];

        _ultimoChatId = datosJson['ultimo_id'].toString();
        _ultimoChatMensajeFecha = datosJson['ultimo_mensaje_fecha'].toString();
        _verMasChats = datosJson['ver_mas'];

        List<dynamic> chats = datosJson['chats'];
        for (var element in chats) {

          Usuario? usuario = null;
          Actividad? actividad = null;

          if(Chat.getChatTipoFromString(element['tipo']) == ChatTipo.GRUPAL){
            actividad = Actividad(
              id: element['actividad']['id'],
              titulo: element['actividad']['titulo'],

              // Los siguientes datos de Actividad no son usados (no son los datos reales)
              descripcion: "",
              fecha: "",
              privacidadTipo: ActividadPrivacidadTipo.PUBLICO,
              interes: "",
              creadores: [],
              ingresoEstado: ActividadIngresoEstado.INTEGRANTE,
              isAutor: false,
            );
          } else {
            usuario = Usuario(
              id: element['usuario']['id'],
              nombre: element['usuario']['nombre_completo'],
              username: element['usuario']['username'],
              foto: constants.urlBase + element['usuario']['foto_url'],
            );
          }

          _chats.add(Chat(
            id: element['id'].toString(),
            tipo: Chat.getChatTipoFromString(element['tipo']),
            numMensajesPendientes: element['mensajes_pendientes'],
            ultimoMensaje: Mensaje(
              id: element['ultimo_mensaje']['id'].toString(),
              tipo: Mensaje.getMensajeTipoFromString(element['ultimo_mensaje']['tipo']),
              fecha: element['ultimo_mensaje']['fecha_texto'],
              fechaCompleto: element['ultimo_mensaje']['fecha'].toString(),
              contenido: element['ultimo_mensaje']['texto'],

              // autorUsuario e isEntrante no son los datos reales (y estos no se toman en la bandeja)
              autorUsuario: Usuario(id: usuarioSesion.id, nombre: usuarioSesion.nombre_completo, username: usuarioSesion.username, foto: usuarioSesion.foto,),
              isEntrante: false,
            ),
            actividadChat: actividad,
            usuarioChat: usuario,
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingChats = false;
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