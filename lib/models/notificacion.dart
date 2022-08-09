import 'package:nuevoproyectouno/models/actividad.dart';
import 'package:nuevoproyectouno/models/chat.dart';
import 'package:nuevoproyectouno/models/usuario.dart';

enum NotificacionTipo {
  INDEFINIDO,
  ACTIVIDAD_INGRESO_SOLICITUD,
  ACTIVIDAD_INGRESO_ACEPTADO,
  ACTIVIDAD_CREADOR,
  STICKER_ENVIADO,
  CONTACTO_SOLICITUD,
  CONTACTO_NUEVO
}

class Notificacion {
  final String id;
  final NotificacionTipo tipo;
  final Usuario autorUsuario;
  final String fecha;
  final Actividad? actividad;
  final Chat? chat;

  bool isNuevo;

  Notificacion({required this.id, required this.tipo, required this.autorUsuario, required this.fecha,
      this.actividad, this.chat, this.isNuevo = false});

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
    } else {
      return NotificacionTipo.INDEFINIDO;
    }
  }
}