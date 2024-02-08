import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/notificacion.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/actividad/actividad_page.dart';
import 'package:tenfo/screens/chat/chat_page.dart';
import 'package:tenfo/screens/chat_solicitudes/chat_solicitudes_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/firebase_notificaciones.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({Key? key}) : super(key: key);

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {

  List<Notificacion> _notificaciones = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingNotificaciones = false;
  bool _verMasNotificaciones = false;
  String _ultimoNotificaciones = "false";

  @override
  void initState() {
    super.initState();

    _cargarNotificaciones();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingNotificaciones && _verMasNotificaciones){
          _cargarNotificaciones();
        }
      }
    });

    FirebaseNotificaciones().limpiarLocalNotificationGenerales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
      ),
      body: (_notificaciones.isEmpty) ? Center(

        child: _loadingNotificaciones ? CircularProgressIndicator() : const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("No tienes notificaciones aún.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ),

      ) : ListView.builder(
        controller: _scrollController,
        itemCount: _notificaciones.length + 1, // +1 mostrar cargando
        itemBuilder: (context, index){
          if(index == _notificaciones.length){
            return _buildLoadingNotificaciones();
          }

          return _buildNotificacion(_notificaciones[index]);
        },
      ),
    );
  }

  Widget _buildNotificacion(Notificacion notificacion){

    String texto = "";
    Icon? iconFoto = null;
    void Function() onTap = (){};

    if(notificacion.tipo == NotificacionTipo.ACTIVIDAD_INGRESO_SOLICITUD){

      texto = '${notificacion.autorUsuario!.nombre} envió una solicitud para entrar a tu actividad.';
      onTap = (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => ChatSolicitudesPage(actividad: notificacion.actividad!,)),
        );
      };

    } else if(notificacion.tipo == NotificacionTipo.ACTIVIDAD_INGRESO_ACEPTADO){

      texto = 'Fuiste aceptado en la actividad: "${notificacion.actividad!.titulo}".';
      iconFoto = Icon(Icons.groups, color: constants.blackGeneral,);
      onTap = (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => ActividadPage(actividad: notificacion.actividad!,)),
        );
      };

    } else if(notificacion.tipo == NotificacionTipo.ACTIVIDAD_CREADOR){

      texto = '${notificacion.autorUsuario!.nombre} te agregó como cocreador de una actividad. Tienes que confirmar para ser parte.';
      onTap = (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => ActividadPage(actividad: notificacion.actividad!,)),
        );
      };

    } else if(notificacion.tipo == NotificacionTipo.STICKER_ENVIADO){

      if(notificacion.chat!.tipo == ChatTipo.GRUPAL){
        texto = '${notificacion.autorUsuario!.nombre} envió un sticker al chat grupal donde eres cocreador ¡Tú lo recibiste!';
      } else {
        texto = '¡${notificacion.autorUsuario!.nombre} te envió un sticker!';
      }
      iconFoto = Icon(CupertinoIcons.bitcoin, color: constants.blackGeneral,);
      onTap = (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => ChatPage(chat: notificacion.chat!,)),
        );
      };

    } else if(notificacion.tipo == NotificacionTipo.CONTACTO_SOLICITUD){

      texto = '${notificacion.autorUsuario!.nombre} te envió una solicitud de amigos.';
      onTap = (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UserPage(usuario: notificacion.autorUsuario!,)),
        );
      };

    } else if(notificacion.tipo == NotificacionTipo.CONTACTO_NUEVO){

      texto = '${notificacion.autorUsuario!.nombre} aceptó tu solicitud de amigos.';
      onTap = (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UserPage(usuario: notificacion.autorUsuario!,)),
        );
      };

    } else if(notificacion.tipo == NotificacionTipo.AVISO_PERSONALIZADO){

      texto = notificacion.avisoPersonalizado ?? "";
      iconFoto = Icon(Icons.error_outline, color: constants.blackGeneral,);
      onTap = (){
        if(notificacion.avisoPersonalizado != null) _showDialogAvisoPersonalizado(notificacion.avisoPersonalizado!);
      };

    } else {
      texto = 'Tienes que actualizar la versión para ver esta notificación.';
    }


    return Ink(
      color: notificacion.isNuevo ? Colors.black12 : null,
      child: ListTile(
        title: Text(texto,
          style: TextStyle(
            fontSize: 14,
            color: constants.blackGeneral,
            fontWeight: notificacion.isNuevo ? FontWeight.bold : null,
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundColor: constants.greyBackgroundImage,
          backgroundImage: iconFoto == null ? CachedNetworkImageProvider(notificacion.autorUsuario!.foto) : null,
          child: iconFoto == null ? null : iconFoto,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(notificacion.fecha,
              style: TextStyle(fontSize: 10, color: constants.grey,),
            ),
          ],
        ),
        onTap: onTap,
        minVerticalPadding: 16,
      ),
    );
  }

  Widget _buildLoadingNotificaciones(){
    if(_loadingNotificaciones){
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

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _loadingNotificaciones = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlVerNotificaciones,
      queryParams: {
        "ultimo_id": _ultimoNotificaciones
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoNotificaciones = datosJson['data']['ultimo_id'].toString();
        _verMasNotificaciones = datosJson['data']['ver_mas'];

        List<dynamic> notificaciones = datosJson['data']['notificaciones'];
        for (var element in notificaciones) {

          Actividad? actividad;
          if(element['actividad'] != null){
            actividad = Actividad(
              id: element['actividad']['id'],
              titulo: element['actividad']['titulo'],
              descripcion: element['actividad']['descripcion'],
              fecha: element['actividad']['fecha_texto'],
              privacidadTipo: Actividad.getActividadPrivacidadTipoFromString(element['actividad']['privacidad_tipo']),
              interes: element['actividad']['interes_id'].toString(),
              isAutor: element['actividad']['autor_usuario_id'] == usuarioSesion.id,

              // Los siguientes datos de Actividad no son usados (no son los datos reales)
              creadores: [],
              ingresoEstado: ActividadIngresoEstado.INTEGRANTE,
            );
          }

          Chat? chat;
          if(element['chat'] != null){

            Actividad? actividadChat;
            if(element['chat']['actividad'] != null){
              actividadChat = Actividad(
                id: element['chat']['actividad']['id'],
                titulo: element['chat']['actividad']['titulo'],

                // Los siguientes datos de Actividad no son usados (no son los datos reales)
                descripcion: "",
                fecha: "",
                privacidadTipo: ActividadPrivacidadTipo.PUBLICO,
                interes: "",
                creadores: [],
                ingresoEstado: ActividadIngresoEstado.INTEGRANTE,
                isAutor: false,
              );
            }

            Usuario? usuarioChat;
            if(element['chat']['usuario'] != null){
              usuarioChat = Usuario(
                id: element['chat']['usuario']['id'],
                nombre: element['chat']['usuario']['nombre_completo'],
                username: element['chat']['usuario']['username'],
                foto: constants.urlBase + element['chat']['usuario']['foto_url'],
              );
            }

            chat = Chat(
              id: element['chat']['id'].toString(),
              tipo: Chat.getChatTipoFromString(element['chat']['tipo']),
              numMensajesPendientes: 0,
              actividadChat: actividadChat,
              usuarioChat: usuarioChat,
            );
          }

          String? avisoPersonalizado;
          if(element['aviso_personalizado'] != null){
            avisoPersonalizado = element['aviso_personalizado'];
          }


          Usuario? autorUsuario;
          if(element['autor_usuario'] != null){
            autorUsuario = Usuario(
              id: element['autor_usuario']['id'],
              nombre: element['autor_usuario']['nombre_completo'],
              username: element['autor_usuario']['username'],
              foto: constants.urlBase + element['autor_usuario']['foto_url'],
            );
          }

          _notificaciones.add(Notificacion(
            id: element['id'].toString(),
            tipo: Notificacion.getNotificacionTipoFromString(element['tipo']),
            autorUsuario: autorUsuario,
            fecha: element['fecha_texto'],
            actividad: actividad,
            chat: chat,
            avisoPersonalizado: avisoPersonalizado,
            isNuevo: element['is_nuevo'],
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingNotificaciones = false;
    });
  }

  void _showDialogAvisoPersonalizado(String aviso){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            Text(aviso),
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