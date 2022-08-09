import 'package:tenfo/models/usuario.dart';

enum UsuarioChatIntegranteRol {
  ADMINISTRADOR,
  INTEGRANTE
}

class UsuarioChatIntegrante {
  final Usuario usuario;
  final UsuarioChatIntegranteRol rol;
  final bool isAutor;

  UsuarioChatIntegrante({required this.usuario, required this.rol,
      this.isAutor = false});

  static UsuarioChatIntegranteRol getUsuarioChatIntegranteRolFromString(String tipoString){
    if(tipoString == "ADMINISTRADOR"){
      return UsuarioChatIntegranteRol.ADMINISTRADOR;
    } else {
      return UsuarioChatIntegranteRol.INTEGRANTE;
    }
  }
}