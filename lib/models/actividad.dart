import 'package:nuevoproyectouno/models/actividad_requisito.dart';
import 'package:nuevoproyectouno/models/chat.dart';
import 'package:nuevoproyectouno/models/usuario.dart';

enum ActividadPrivacidadTipo {PUBLICO, PRIVADO, REQUISITOS}
enum ActividadIngresoEstado {NO_INTEGRANTE, PENDIENTE, REQUISITO_RECHAZADO, INTEGRANTE, EXPULSADO}

class Actividad {
  final String id;
  final String titulo;
  final String? descripcion;
  final String fecha;
  final ActividadPrivacidadTipo privacidadTipo;
  final String interes;
  final List<Usuario> creadores;
  ActividadIngresoEstado ingresoEstado;

  final bool isAutor;

  List<ActividadRequisito> requisitosPreguntas;
  bool requisitosEnviado;

  Chat? chat;

  Actividad({required this.id, required this.titulo, required this.descripcion,
      required this.fecha, required this.privacidadTipo, required this.interes,
      required this.creadores, required this.ingresoEstado, required this.isAutor,
      this.chat, this.requisitosPreguntas = const [], this.requisitosEnviado = false});

  static ActividadPrivacidadTipo getActividadPrivacidadTipoFromString(String tipoString){
    if(tipoString == "PUBLICO"){
      return ActividadPrivacidadTipo.PUBLICO;
    } else if(tipoString == "PRIVADO"){
      return ActividadPrivacidadTipo.PRIVADO;
    } else {
      return ActividadPrivacidadTipo.PUBLICO;
    }
  }

  static String getActividadPrivacidadTipoToString(ActividadPrivacidadTipo tipo){
    if(tipo == ActividadPrivacidadTipo.PUBLICO){
      return "PUBLICO";
    } else if(tipo == ActividadPrivacidadTipo.PRIVADO){
      return "PRIVADO";
    } else {
      return "PUBLICO";
    }
  }

  static ActividadIngresoEstado getActividadIngresoEstadoFromString(String tipoString){
    if(tipoString == "INTEGRANTE"){
      return ActividadIngresoEstado.INTEGRANTE;
    } else if(tipoString == "NO_INTEGRANTE"){
      return ActividadIngresoEstado.NO_INTEGRANTE;
    } else if(tipoString == "PENDIENTE"){
      return ActividadIngresoEstado.PENDIENTE;
    } else if(tipoString == "EXPULSADO"){
      return ActividadIngresoEstado.EXPULSADO;
    } else {
      return ActividadIngresoEstado.NO_INTEGRANTE;
    }
  }

  String getPrivacidadTipoString(){
    if(privacidadTipo == ActividadPrivacidadTipo.PUBLICO){
      return "Público";
    } else if(privacidadTipo == ActividadPrivacidadTipo.PRIVADO){
      return "Privado";
    } else if(privacidadTipo == ActividadPrivacidadTipo.REQUISITOS){
      return "Requisitos";
    } else {
      return "";
    }
  }

  bool getIsCreador(String sessionId){
    bool isCreador = false;

    for(Usuario creador in creadores){
      if(sessionId == creador.id){
        isCreador = true;
        break;
      }
    }

    return isCreador;
  }
}