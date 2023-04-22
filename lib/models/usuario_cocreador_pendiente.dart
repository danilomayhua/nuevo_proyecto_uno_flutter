import 'package:tenfo/models/usuario.dart';

enum UsuarioCocreadorPendienteTipo {
  CREADOR_PENDIENTE,
  CREADOR_PENDIENTE_EXTERNO
}

class UsuarioCocreadorPendiente {
  final UsuarioCocreadorPendienteTipo tipo;
  final Usuario? usuario;
  final String? invitacionCodigo;

  UsuarioCocreadorPendiente({required this.tipo, this.usuario, this.invitacionCodigo});

  static UsuarioCocreadorPendienteTipo getUsuarioCocreadorPendienteTipoFromString(String tipoString){
    if(tipoString == "CREADOR_PENDIENTE_EXTERNO"){
      return UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE_EXTERNO;
    } else {
      return UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE;
    }
  }
}