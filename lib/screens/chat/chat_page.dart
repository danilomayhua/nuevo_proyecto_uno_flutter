import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/mensaje.dart';
import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/chat/widgets/chat_app_bar.dart';
import 'package:tenfo/screens/chat/widgets/message_bubble.dart';
import 'package:tenfo/screens/chat/widgets/message_entry.dart';
import 'package:tenfo/screens/chat_info/chat_info_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/firebase_notificaciones.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  ChatPage({Key? key, required this.chat, this.chatIndividualUsuario, this.compartenGrupoChatId, this.isFromMatch = false}) : super(key: key);

  Chat? chat;
  final Usuario? chatIndividualUsuario;
  final String? compartenGrupoChatId;
  final bool isFromMatch;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {

  UsuarioSesion? _usuarioSesion = null;

  bool _isChatGroup = false;
  String _chatTitle = "";
  String? _chatSubtitle;
  String? _profilePictureUrl;

  WebSocket? _webSocket;

  final List<Mensaje> _messageList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _areThereMoreMessages = false;
  String _lastMessageId = "false";

  bool _enviandoEliminarChat = false;

  final GlobalKey<MessageEntryState> _keyMessageEntry = GlobalKey();
  final GlobalKey<ChatAppBarState> _keyChatAppBar = GlobalKey();

  @override
  void initState() {
    super.initState();

    _isChatGroup = widget.chat == null ? false : (widget.chat!.tipo == ChatTipo.GRUPAL);
    _chatTitle = _isChatGroup
        ? widget.chat!.actividadChat!.titulo
        : (widget.chat == null) ? widget.chatIndividualUsuario!.nombre : widget.chat!.usuarioChat!.nombre;
    _chatSubtitle = null;
    _profilePictureUrl = _isChatGroup
        ? null
        : (widget.chat == null) ? widget.chatIndividualUsuario!.foto : widget.chat!.usuarioChat!.foto;

    setState(() {});
    
    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange && !_isLoading && _areThereMoreMessages) {
        try {
          _loadMessages();
        } on Exception catch (exception, stackTrace) {
          print('An error ocurred!\nError: $exception\nStackTrace: $stackTrace');
          _showSnackBar('Se produjo un error inesperado');
          setState(() => _isLoading = false);
        }
      }
    });

    _connectWithWebSocket()
        .then((value) => _loadMessages())
        .then((value){
          if(_isChatGroup){
            _updateUnreadGroupMessages();
          } else {
            _updateUnreadPrivateMessages();
          }
      });


    if(_isChatGroup && widget.isFromMatch){
      // Se tiene que usar los snackBar despues de ejecutarse el widget
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _showSnackBar("El creador de esta actividad te seleccionó anteriormente ¡Te uniste a la actividad!");
      });
    }


    // Si es igual a null, cuando se crea widget.chat se actualiza chatAbiertoAhora
    if(widget.chat != null) FirebaseNotificaciones().chatAbiertoAhora = widget.chat;
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    _webSocket?.close();

    FirebaseNotificaciones().chatAbiertoAhora = null;
    WidgetsBinding.instance?.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /*
    En Android, FirebaseNotificaciones() en background es una
    diferente instancia, por lo tanto chatAbiertoAhora es igual a null.
    Tal vez en iOS si es necesario el siguiente switch.
    */

    // TODO : No cambia AppLifecycleState cuando se abre otro page (push). Esto se podria arreglar con RouteAware.
    switch (state) {
      case AppLifecycleState.resumed:
        if(widget.chat != null) FirebaseNotificaciones().chatAbiertoAhora = widget.chat;
        break;

      case AppLifecycleState.inactive:
        break;

      case AppLifecycleState.hidden:
        break;

      case AppLifecycleState.paused:
        FirebaseNotificaciones().chatAbiertoAhora = null;
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        key: _keyChatAppBar,
        isGroup: _isChatGroup,
        title: _chatTitle,
        subtitle: _chatSubtitle ?? "Toca para ver Info. del grupo",
        profilePictureUrl: _profilePictureUrl,
        onChatInfoRequested: (){
          if(_isChatGroup){
            Navigator.push(context,
              MaterialPageRoute(
                builder: (context) => ChatInfoPage(chat: widget.chat!,),
              ),
            );
          } else {
            Navigator.push(context,
              MaterialPageRoute(
                builder: (context) => UserPage(usuario: (widget.chat == null) ? widget.chatIndividualUsuario! : widget.chat!.usuarioChat!,),
              ),
            );
          }
        },
        onPopupMenuItemSelected: (value){
          if(value == PopupMenuOption.DELETE_CHAT){
            _showDialogEliminarChat();
          }
        },
      ),
      body: SafeArea(child: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemBuilder: (context, index){
              if (_isLoading && index == _messageList.length) {
                return const Padding(
                  child: Center(child: CircularProgressIndicator()),
                  padding: EdgeInsets.all(8),
                );
              }

              return MessageBubble(
                isGroup: _isChatGroup,
                message: _messageList[index],
                nextMessage: index == _messageList.length - 1 ? null : _messageList[index + 1],
                previousMessage: index == 0 ? null : _messageList[index - 1],
                onProfileRequested: (Usuario usuario) => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (context) => UserPage(usuario: usuario, compartenGrupoChatId: _isChatGroup ? widget.chat!.id : null,),
                  ),
                ),
              );
            },
            itemCount: _isLoading ? _messageList.length + 1 : _messageList.length,
            reverse: true,
            shrinkWrap: true,
          ),
        ),
        MessageEntry(
          key: _keyMessageEntry,
          onSendMessageRequested: _handleSendMessageRequest,
        ),
      ]),),
    );
  }

  void _showDialogEliminarChat(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Eliminar chat?'),
          content: const Text('Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: _enviandoEliminarChat ? null : () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar'),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
              onPressed: _enviandoEliminarChat ? null : () => _isChatGroup
                  ? _eliminarChatGrupal(setStateDialog)
                  : _vaciarChatIndividual(setStateDialog),
            ),
          ],
        );
      });
    });
  }

  Future<void> _vaciarChatIndividual(setStateDialog) async {
    setStateDialog(() {
      _enviandoEliminarChat = true;
    });

    if(widget.chat == null){
      // No tiene mensajes el chat
      setStateDialog(() {_enviandoEliminarChat = false;});
      Navigator.of(context).pop();
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlChatIndividualVaciar,
      body: {
        "chat_id": widget.chat!.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _messageList.clear();

        Navigator.of(context).pop();
        setState(() {});

      } else {
        Navigator.of(context).pop();

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoEliminarChat = false;
    });
  }

  Future<void> _eliminarChatGrupal(setStateDialog) async {
    setStateDialog(() {
      _enviandoEliminarChat = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlChatGrupalEliminar,
      body: {
        "chat_id": widget.chat!.id
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
        Navigator.of(context).pop();

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoEliminarChat = false;
    });
  }

  Future<void> _connectWithWebSocket() async {
    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    _webSocket = await WebSocket.connect(
      constants.urlBaseWebSocket,
      headers: {
        'Authorization': 'Bearer ${_usuarioSesion!.authToken}'
      },
    );

    _webSocket!.listen((data) async {
      Map<String, dynamic> response = json.decode(data);

      switch (response['type']) {
        case 'conectado':
          _handleConnectionEvent();
          break;
        case 'chat_grupal_mensaje':
          _handleGroupMessage(response['data']);
          break;
        case 'chat_individual_mensaje':
          _handlePrivateMessage(response['data']);
          break;
        case 'chat_no_disponible':
          _handleChatNotAvailable(response['data']);
          break;
      }
    });

    setState(() => _isLoading = false);
  }

  void _updateUnreadGroupMessages() {
    if (_messageList.length <= 0) return;

    _webSocket!.add(json.encode({
      'type': 'chat_actualizar_visto',
      'data': {
        'chat': {'id': widget.chat!.id},
        'mensaje': {'fecha': _messageList[0].fechaCompleto}
      }
    }));
  }

  void _updateUnreadPrivateMessages() {
    if (_messageList.length <= 0) return;

    if(widget.chat != null){
      _webSocket!.add(json.encode({
        'type': 'chat_actualizar_visto',
        'data': {
          'chat': {'id': widget.chat!.id},
          'mensaje': {'fecha': _messageList[0].fechaCompleto}
        }
      }));
    }
  }

  void _handleConnectionEvent() {
    if(_isChatGroup){
      _webSocket!.add(json.encode({
        'type': 'chat_grupal_conectar',
        'data': {
          'chat': {'id': widget.chat!.id}
        },
      }));
    }
  }

  void _handleGroupMessage(Map<String, dynamic> data) {
    Usuario autorUsuario = Usuario(
      id: data['mensaje']['autor_usuario']['id'],
      nombre: data['mensaje']['autor_usuario']['nombre_completo'],
      username: data['mensaje']['autor_usuario']['username'],
      foto: constants.urlBase + data['mensaje']['autor_usuario']['foto_url'],
    );

    if(data['mensaje']['encuentro_fecha'] != null){
      _chatSubtitle = Mensaje.grupoEncuentroFechaToText(data['mensaje']['encuentro_fecha'].toString());
    }

    Usuario? eliminadoUsuario;
    if(data['mensaje']['eliminado_usuario'] != null){
      eliminadoUsuario = Usuario(
        id: data['mensaje']['eliminado_usuario']['id'],
        nombre: data['mensaje']['eliminado_usuario']['nombre_completo'],
        username: data['mensaje']['eliminado_usuario']['username'],
        foto: constants.urlBase + data['mensaje']['eliminado_usuario']['foto_url'],
      );

      if(data['mensaje']['eliminado_usuario']['id'] == _usuarioSesion!.id){
        if(_keyMessageEntry.currentState != null){
          _keyMessageEntry.currentState!.userBlocked();
        }
        if(_keyChatAppBar.currentState != null){
          _keyChatAppBar.currentState!.setIsIntegrante(false);
        }
      }
    }

    MensajePropinaSticker? propinaSticker;
    if(data['mensaje']['usuario_sticker_recibido'] != null){
      propinaSticker = MensajePropinaSticker(
        sticker: Sticker(
          id: data['mensaje']['usuario_sticker_recibido']['sticker']['id'].toString(),
          cantidadSatoshis: data['mensaje']['usuario_sticker_recibido']['sticker']['valor_satoshis'],
        ),
        isRecibido: data['mensaje']['usuario_sticker_recibido']['usuario']['id'] == _usuarioSesion!.id,
      );
    }

    setState(() => _messageList.insert(0,
      Mensaje(
        id: data['mensaje']['id'].toString(),
        tipo: Mensaje.getMensajeTipoFromString(data['mensaje']['tipo']),
        fecha: data['mensaje']['fecha_texto'],
        fechaCompleto: data['mensaje']['fecha'].toString(),
        contenido: data['mensaje']['texto'],
        autorUsuario: autorUsuario,
        isEntrante: _usuarioSesion!.id != data['mensaje']['autor_usuario']['id'],
        grupoEliminadoUsuario: eliminadoUsuario,
        grupoEncuentroFecha: data['mensaje']['encuentro_fecha'].toString(),
        propinaSticker: propinaSticker,
      ),
    ));

    _updateUnreadGroupMessages();
  }

  void _handlePrivateMessage(Map<String, dynamic> data) {

    if(widget.chat == null){
      if(_crearChatDesdeMensajeIndividual(data) == false) return;
    }

    if(data['chat']['id'].toString() != widget.chat!.id) return;

    Usuario autorUsuario;
    if(_usuarioSesion!.id != data['mensaje']['autor_usuario']['id']){
      autorUsuario = widget.chat!.usuarioChat!;
    } else {
      autorUsuario = Usuario(
        id: _usuarioSesion!.id,
        nombre: _usuarioSesion!.nombre_completo,
        username: _usuarioSesion!.username,
        foto: _usuarioSesion!.foto,
      );
    }

    MensajePropinaSticker? propinaSticker;
    if(data['mensaje']['usuario_sticker_recibido'] != null){
      propinaSticker = MensajePropinaSticker(
        sticker: Sticker(
          id: data['mensaje']['usuario_sticker_recibido']['sticker']['id'].toString(),
          cantidadSatoshis: data['mensaje']['usuario_sticker_recibido']['sticker']['valor_satoshis'],
        ),
        isRecibido: data['mensaje']['usuario_sticker_recibido']['usuario']['id'] == _usuarioSesion!.id,
      );
    }

    setState(() => _messageList.insert(0,
      Mensaje(
        id: data['mensaje']['id'].toString(),
        tipo: Mensaje.getMensajeTipoFromString(data['mensaje']['tipo']),
        fecha: data['mensaje']['fecha_texto'],
        fechaCompleto: data['mensaje']['fecha'].toString(),
        contenido: data['mensaje']['texto'],
        autorUsuario: autorUsuario,
        isEntrante: _usuarioSesion!.id != data['mensaje']['autor_usuario']['id'],
        propinaSticker: propinaSticker,
      ),
    ));

    if(_usuarioSesion!.id != data['mensaje']['autor_usuario']['id']) _updateUnreadPrivateMessages();
  }

  bool _crearChatDesdeMensajeIndividual(Map<String, dynamic> data){
    if(widget.chat == null){
      if((data['receptor_usuario']['id'] == _usuarioSesion!.id && data['mensaje']['autor_usuario']['id'] == widget.chatIndividualUsuario!.id) ||
          (data['mensaje']['autor_usuario']['id'] == _usuarioSesion!.id && data['receptor_usuario']['id'] == widget.chatIndividualUsuario!.id)){

        widget.chat = Chat(
            id: data['chat']['id'].toString(),
            tipo: ChatTipo.INDIVIDUAL,
            numMensajesPendientes: null,
            usuarioChat: widget.chatIndividualUsuario
        );

        FirebaseNotificaciones().chatAbiertoAhora = widget.chat;

        return true;

      } else {
        // No es un mensaje del chat actual
        return false;
      }
    } else {
      return true;
    }
  }

  void _handleChatNotAvailable(Map<String, dynamic> data){
    if(widget.chatIndividualUsuario?.id != null){
      if(data['receptor_usuario']['id'] == widget.chatIndividualUsuario!.id){
        if(_keyMessageEntry.currentState != null){
          _keyMessageEntry.currentState!.userBlocked();
        }
      }
    }
  }

  void _handleSendMessageRequest(String text) {
    if(_isChatGroup) {
      _webSocket?.add(json.encode({
        'type': 'chat_grupal_mensaje',
        'data': {
          'chat': {'id': widget.chat!.id},
          'mensaje': {'texto': text},
        },
      }));
    } else {

      String? chatId = widget.chat?.id;
      String? usuarioId = widget.chatIndividualUsuario?.id;

      _webSocket?.add(json.encode({
        'type': 'chat_individual_mensaje',
        'data': {
          'chat': {
            'id': chatId,
          },
          'receptor_usuario': {
            'id': usuarioId,
          },
          'mensaje': {'texto': text},
          'comparten_grupo_chat_id': widget.compartenGrupoChatId,
        },
      }));

    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);


    String chatId = "";
    String usuarioId = "";

    if(!_isChatGroup && widget.chat == null){
      chatId = "false";
      usuarioId = widget.chatIndividualUsuario!.id;
    } else {
      chatId = widget.chat!.id;
    }

    var response = await HttpService.httpGet(
      url: constants.urlChatMensajes,
      queryParams: {
        "chat_id": chatId,
        "usuario_id": usuarioId,
        "ultimo_id": _lastMessageId
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _lastMessageId = datosJson['data']['ultimo_id'].toString();
        _areThereMoreMessages = datosJson['data']['ver_mas'];

        if(!_isChatGroup){

          if(widget.chat == null && datosJson['data']['chat_id'] != null){

            // Si no existe 'chat_id', devuelve 'mensajes' vacio

            widget.chat = Chat(
                id: datosJson['data']['chat_id'].toString(),
                tipo: ChatTipo.INDIVIDUAL,
                numMensajesPendientes: null,
                usuarioChat: widget.chatIndividualUsuario
            );

            FirebaseNotificaciones().chatAbiertoAhora = widget.chat;

          }

          if(datosJson['data']['is_chat_bloqueado'] != null && datosJson['data']['is_chat_bloqueado'] == true){
            if(_keyMessageEntry.currentState != null){
              _keyMessageEntry.currentState!.userBlocked();
            }
          }

        } else {

          if(datosJson['data']['encuentro_fecha'] != null){
            _chatSubtitle = Mensaje.grupoEncuentroFechaToText(datosJson['data']['encuentro_fecha'].toString());
          }

          if(datosJson['data']['is_integrante'] != null && datosJson['data']['is_integrante'] == false){
            if(_keyMessageEntry.currentState != null){
              _keyMessageEntry.currentState!.userBlocked();
            }
            if(_keyChatAppBar.currentState != null){
              _keyChatAppBar.currentState!.setIsIntegrante(false);
            }
          }

          if(datosJson['data']['is_habilitado_sugerencias'] != null && datosJson['data']['is_habilitado_sugerencias'] == true){
            if(_keyMessageEntry.currentState != null){
              _keyMessageEntry.currentState!.setShowSugerencias(true, chatId);
            }
          }

        }

        List<dynamic> mensajes = datosJson['data']['mensajes'];
        for (var element in mensajes) {

          Usuario autorUsuario;

          Usuario? eliminadoUsuario;
          String? encuentroFecha;
          MensajePropinaSticker? propinaSticker;

          if(!_isChatGroup){

            if(element['is_entrante']){
              autorUsuario = widget.chat!.usuarioChat!;
            } else {
              autorUsuario = Usuario(
                id: usuarioSesion.id,
                nombre: usuarioSesion.nombre_completo,
                username: usuarioSesion.username,
                foto: usuarioSesion.foto,
              );
            }

            encuentroFecha = null;

          } else {
            autorUsuario = Usuario(
              id: element['autor_usuario']['id'],
              nombre: element['autor_usuario']['nombre_completo'],
              username: element['autor_usuario']['username'],
              foto: constants.urlBase + element['autor_usuario']['foto_url'],
            );
            encuentroFecha = element['encuentro_fecha'].toString();
          }

          if(element['eliminado_usuario'] != null){
            eliminadoUsuario = Usuario(
              id: element['eliminado_usuario']['id'],
              nombre: element['eliminado_usuario']['nombre_completo'],
              username: element['eliminado_usuario']['username'],
              foto: constants.urlBase + element['eliminado_usuario']['foto_url'],
            );
          }

          if(element['usuario_sticker_recibido'] != null){
            propinaSticker = MensajePropinaSticker(
              sticker: Sticker(
                id: element['usuario_sticker_recibido']['sticker']['id'].toString(),
                cantidadSatoshis: element['usuario_sticker_recibido']['sticker']['valor_satoshis'],
              ),
              isRecibido: element['usuario_sticker_recibido']['usuario']['id'] == usuarioSesion.id,
            );
          }

          _messageList.add(Mensaje(
            id: element['id'].toString(),
            tipo: Mensaje.getMensajeTipoFromString(element['tipo']),
            fecha: element['fecha_texto'],
            fechaCompleto: element['fecha'].toString(),
            contenido: element['texto'],
            autorUsuario: autorUsuario,
            isEntrante: element['is_entrante'],
            grupoEliminadoUsuario: eliminadoUsuario,
            grupoEncuentroFecha: encuentroFecha,
            propinaSticker: propinaSticker,
          ));

        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() => _isLoading = false);
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}