import 'package:tenfo/models/usuario.dart';

enum UsuarioPerfilContactoEstado {
  CONECTADOS,
  NO_CONECTADOS,
  SOLICITUD_ENVIADO,
  SOLICITUD_RECIBIDO,
  BLOQUEO_ENVIADO,
  BLOQUEO_RECIBIDO
}

class UsuarioPerfilUniversidad {
  String id;
  String nombre;

  UsuarioPerfilUniversidad({required this.id, required this.nombre});
}

class UsuarioPerfil extends Usuario {

  UsuarioPerfilUniversidad? universidad;
  String? descripcion;
  String? instagram;
  UsuarioPerfilContactoEstado? contactoEstado;
  List<Usuario>? contactosMutuos;
  int? totalContactosMutuos;
  //String? activo;
  bool isVerificadoUniversidad = false;
  String? verificadoUniversidadNombre;

  bool isSuperliked = false;

  UsuarioPerfil({required String id, required String nombre,
    required String username, required String foto,})
      : super(id: id, nombre: nombre, username: username, foto: foto,);

  static UsuarioPerfilContactoEstado getUsuarioPerfilContactoEstadoFromString(String tipoString){
    if(tipoString == "CONECTADOS"){
      return UsuarioPerfilContactoEstado.CONECTADOS;
    } else if(tipoString == "NO_CONECTADOS"){
      return UsuarioPerfilContactoEstado.NO_CONECTADOS;
    } else if(tipoString == "SOLICITUD_ENVIADO"){
      return UsuarioPerfilContactoEstado.SOLICITUD_ENVIADO;
    } else if(tipoString == "SOLICITUD_RECIBIDO"){
      return UsuarioPerfilContactoEstado.SOLICITUD_RECIBIDO;
    } else if(tipoString == "BLOQUEO_ENVIADO"){
      return UsuarioPerfilContactoEstado.BLOQUEO_ENVIADO;
    } else if(tipoString == "BLOQUEO_RECIBIDO"){
      return UsuarioPerfilContactoEstado.BLOQUEO_RECIBIDO;
    } else {
      return UsuarioPerfilContactoEstado.NO_CONECTADOS;
    }
  }
}
