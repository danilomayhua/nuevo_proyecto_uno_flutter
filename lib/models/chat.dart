import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/mensaje.dart';
import 'package:tenfo/models/usuario.dart';

enum ChatTipo {INDIVIDUAL, GRUPAL}

class Chat {
  final String id;
  /// Puede ser 'INDIVIDUAL' o 'GRUPAL'
  final ChatTipo tipo;

  int? numMensajesPendientes;

  Mensaje? ultimoMensaje;

  final Actividad? actividadChat;

  final Usuario? usuarioChat;

  Chat({required this.id, required this.tipo, required this.numMensajesPendientes,
      this.actividadChat, this.usuarioChat, this.ultimoMensaje});

  static ChatTipo getChatTipoFromString(String tipoString){
    if(tipoString == "INDIVIDUAL"){
      return ChatTipo.INDIVIDUAL;
    } else if(tipoString == "GRUPAL"){
      return ChatTipo.GRUPAL;
    } else {
      return ChatTipo.INDIVIDUAL;
    }
  }
}