import 'package:tenfo/models/actividad_requisito.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/usuario.dart';

enum ActividadPrivacidadTipo {PUBLICO, PRIVADO, REQUISITOS}
enum ActividadIngresoEstado {NO_INTEGRANTE, PENDIENTE, REQUISITO_RECHAZADO, INTEGRANTE, EXPULSADO}

class ActividadCreador {
  final String id;
  final String nombre;
  final String nombreCompleto;
  final String username;
  final String foto;

  ActividadCreador({required this.id, required this.nombre, required this.nombreCompleto,
    required this.username, required this.foto,});

  Usuario toUsuario(){
    return Usuario(id: id, nombre: nombreCompleto, username: username, foto: foto);
  }
}

class Actividad {
  final String id;
  final String titulo;
  final String? descripcion;
  final String fecha;
  final ActividadPrivacidadTipo privacidadTipo;
  final String interes;
  bool isLiked;
  int likesCount;
  final List<ActividadCreador> creadores;
  ActividadIngresoEstado ingresoEstado;

  final bool isAutor;

  bool? isMatchLiked;
  bool? isMatch;

  String? distanciaTexto;

  List<ActividadRequisito> requisitosPreguntas;
  bool requisitosEnviado;

  Chat? chat;

  Actividad({required this.id, required this.titulo, required this.descripcion,
      required this.fecha, required this.privacidadTipo, required this.interes,
      required this.creadores, required this.ingresoEstado, required this.isLiked,
      required this.likesCount, required this.isAutor,
      this.isMatchLiked, this.isMatch, this.distanciaTexto,
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

    for(ActividadCreador creador in creadores){
      if(sessionId == creador.id){
        isCreador = true;
        break;
      }
    }

    return isCreador;
  }
}