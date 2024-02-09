import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/mensaje.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/chat/chat_page.dart';
import 'package:tenfo/services/firebase_notificaciones.dart';
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

  bool _isNotificacionesPushHabilitado = true;

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

    FirebaseNotificaciones().limpiarLocalNotificationChats();

    _verificarNotificacionesPush();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Mensajes"),
      ),
      body: (_chats.isEmpty) ? Center(
        child: _loadingChats ? const CircularProgressIndicator() : Column(children: [

          if(!_isNotificacionesPushHabilitado)
            _buildEnableNotifications(),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text("Aquí aparecerán los chats de actividades a las que te unas.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),

        ], mainAxisAlignment: MainAxisAlignment.center,),
      ) : RefreshIndicator(
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
          itemCount: _chats.length + 2, // +1 mostrar boton notificaciones, +1 mostrar cargando
          itemBuilder: (context, index){
            if(index == 0){
              if(!_isNotificacionesPushHabilitado){
                return _buildEnableNotifications();
              } else {
                return Container();
              }
            }
            index = index - 1;

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
        backgroundImage: CachedNetworkImageProvider(chat.usuarioChat!.foto),
      ) : const CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: null,
        child: Icon(Icons.groups, color: constants.blackGeneral,),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(chat.ultimoMensaje == null ? "" : chat.ultimoMensaje!.fecha,
            style: TextStyle(color: constants.grey, fontSize: 12,),
          ),
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
      onTap: () async {
        await Navigator.push(context,
          MaterialPageRoute(
            builder: (context) => ChatPage(chat: chat),
          ),
        );

        // TODO : actualizar ultimoMensaje solamente si se envio/recibio un mensaje en ChatPage
        chat.ultimoMensaje = null;
        chat.numMensajesPendientes = 0;
        setState(() {});
      },
    );
  }

  Widget _buildSubtitleChat(Chat chat){
    String msg = "";
    if(chat.ultimoMensaje == null){
      msg = "";
    } else if(chat.ultimoMensaje!.tipo == MensajeTipo.NORMAL){
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


  Future<void> _verificarNotificacionesPush() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
      if(settings.authorizationStatus != AuthorizationStatus.authorized){
        _isNotificacionesPushHabilitado = false;
      }
    } catch(e){
      // Captura error, por si surge algun posible error con FirebaseMessaging
    }

    setState(() {});
  }

  Widget _buildEnableNotifications(){
    return Column(children: [
      const SizedBox(height: 16,),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Row(children: [
          const Icon(Icons.notifications, size: 24, color: constants.grey,),
          const SizedBox(width: 12,),
          Expanded(child: Text(
            'Permite las notificaciones para enterarte cuando ingreses a una actividad, '
                'cuando alguien ingrese a tus actividades o cuando te agregan nuevos amigos.',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.2,
            ),
          ),),
        ], crossAxisAlignment: CrossAxisAlignment.start,),
      ),
      const SizedBox(height: 8,),
      Container(
        //constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
        //width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: ElevatedButton(
          onPressed: () {
            _habilitarNotificacionesPush();
          },
          child: const Text('Activar'),
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
          ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
        ),
      ),
      const SizedBox(height: 16,),
      const Divider(color: constants.greyLight, height: 0.5,),
      const SizedBox(height: 16,),
    ], mainAxisSize: MainAxisSize.min,);
  }

  Future<void> _habilitarNotificacionesPush() async {
    try {
      // Permisos para iOS y para Android 13+
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();

      if(settings.authorizationStatus != AuthorizationStatus.authorized){
        _showSnackBar("Los permisos están denegados. Permite las notificaciones desde Ajustes en la app.");
        return;
      }
    } catch(e){
      // Captura error, por si surge algun posible error con FirebaseMessaging
    }

    _isNotificacionesPushHabilitado = true;
    setState(() {});
  }


  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}