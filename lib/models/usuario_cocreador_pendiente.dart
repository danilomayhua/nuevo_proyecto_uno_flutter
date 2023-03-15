import 'package:tenfo/models/usuario.dart';

enum UsuarioCocreadorPendienteTipo {
  INVITADO_DIRECTO,
  INVITADO_EXTERNO
}

class UsuarioCocreadorPendiente {
  final UsuarioCocreadorPendienteTipo tipo;
  final Usuario? usuario;
  final String? invitacionCodigo;

  UsuarioCocreadorPendiente({required this.tipo, this.usuario, this.invitacionCodigo});

  static UsuarioCocreadorPendienteTipo getUsuarioCocreadorPendienteTipoFromString(String tipoString){
    if(tipoString == "INVITADO_EXTERNO"){
      return UsuarioCocreadorPendienteTipo.INVITADO_EXTERNO;
    } else {
      return UsuarioCocreadorPendienteTipo.INVITADO_DIRECTO;
    }
  }
}