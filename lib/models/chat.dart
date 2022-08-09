import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/mensaje.dart';
import 'package:tenfo/models/usuario.dart';

enum ChatTipo {INDIVIDUAL, GRUPAL}

class Chat {
  final String id;
  /// Puede ser 'INDIVIDUAL' o 'GRUPAL'
  final ChatTipo tipo;

  final int? numMensajesPendientes;

  final Mensaje? ultimoMensaje;
  /*final String ultimoMensajeAutor;
  final String ultimoMensajeContenido;
  final String ultimoMensajeFecha;*/

  final Actividad? actividadChat;
  /*final String idPublicacionChat;
  final String descripcionPublicacionChat;*/

  final Usuario? usuarioChat;
  /*final String idUsuario;
  final String fotoUsuario;
  final String nombreUsuario;*/

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