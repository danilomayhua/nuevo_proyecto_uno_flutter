import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/usuario.dart';

enum NotificacionTipo {
  INDEFINIDO,
  ACTIVIDAD_INGRESO_SOLICITUD,
  ACTIVIDAD_INGRESO_ACEPTADO,
  ACTIVIDAD_CREADOR,
  STICKER_ENVIADO,
  CONTACTO_SOLICITUD,
  CONTACTO_NUEVO,
  AVISO_PERSONALIZADO,
  ACTIVIDAD_INVITACION,
  ACTIVIDAD_LIKE,
  ACTIVIDAD_MATCH_LIKE_ENVIADO,
  USUARIO_MATCH_LIKE_ENVIADO,
  ACTIVIDAD_MATCH_LIKE_EXITO,
  USUARIO_MATCH_LIKE_EXITO,
}

class Notificacion {
  final String id;
  final NotificacionTipo tipo;
  final Usuario? autorUsuario;
  final String fecha;
  final Actividad? actividad;
  final Chat? chat;

  final int? cantidadMatchLike;

  final String? avisoPersonalizado;

  bool isNuevo;

  Notificacion({required this.id, required this.tipo, required this.autorUsuario, required this.fecha,
      this.actividad, this.chat,  this.cantidadMatchLike, this.avisoPersonalizado, this.isNuevo = false});

  static NotificacionTipo getNotificacionTipoFromString(String tipoString){
    if(tipoString == "ACTIVIDAD_INGRESO_SOLICITUD"){
      return NotificacionTipo.ACTIVIDAD_INGRESO_SOLICITUD;
    } else if(tipoString == "ACTIVIDAD_INGRESO_ACEPTADO"){
      return NotificacionTipo.ACTIVIDAD_INGRESO_ACEPTADO;
    } else if(tipoString == "ACTIVIDAD_CREADOR"){
      return NotificacionTipo.ACTIVIDAD_CREADOR;
    } else if(tipoString == "STICKER_ENVIADO"){
      return NotificacionTipo.STICKER_ENVIADO;
    } else if(tipoString == "CONTACTO_SOLICITUD"){
      return NotificacionTipo.CONTACTO_SOLICITUD;
    } else if(tipoString == "CONTACTO_NUEVO"){
      return NotificacionTipo.CONTACTO_NUEVO;
    } else if(tipoString == "AVISO_PERSONALIZADO"){
      return NotificacionTipo.AVISO_PERSONALIZADO;
    } else if(tipoString == "ACTIVIDAD_INVITACION"){
      return NotificacionTipo.ACTIVIDAD_INVITACION;
    } else if(tipoString == "ACTIVIDAD_LIKE"){
      return NotificacionTipo.ACTIVIDAD_LIKE;
    } else if(tipoString == "ACTIVIDAD_MATCH_LIKE_ENVIADO"){
      return NotificacionTipo.ACTIVIDAD_MATCH_LIKE_ENVIADO;
    } else if(tipoString == "USUARIO_MATCH_LIKE_ENVIADO"){
      return NotificacionTipo.USUARIO_MATCH_LIKE_ENVIADO;
    } else if(tipoString == "ACTIVIDAD_MATCH_LIKE_EXITO"){
      return NotificacionTipo.ACTIVIDAD_MATCH_LIKE_EXITO;
    } else if(tipoString == "USUARIO_MATCH_LIKE_EXITO"){
      return NotificacionTipo.USUARIO_MATCH_LIKE_EXITO;
    } else {
      return NotificacionTipo.INDEFINIDO;
    }
  }
}