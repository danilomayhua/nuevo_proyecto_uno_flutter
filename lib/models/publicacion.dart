import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/sugerencia_usuario.dart';

enum PublicacionTipo {
  ACTIVIDAD,
  DISPONIBILIDAD,
  SUGERENCIA_USUARIO,
  INDEFINIDO,
}

class Publicacion {
  final PublicacionTipo tipo;
  Actividad? actividad;
  Disponibilidad? disponibilidad;
  SugerenciaUsuario? sugerenciaUsuario;

  Publicacion({required this.tipo, this.actividad, this.disponibilidad, this.sugerenciaUsuario});

  static PublicacionTipo getPublicacionTipoFromString(String tipoString){
    if(tipoString == "ACTIVIDAD"){
      return PublicacionTipo.ACTIVIDAD;
    } else if(tipoString == "DISPONIBILIDAD"){
      return PublicacionTipo.DISPONIBILIDAD;
    } else if(tipoString == "SUGERENCIA_USUARIO"){
      return PublicacionTipo.SUGERENCIA_USUARIO;
    } else {
      return PublicacionTipo.INDEFINIDO;
    }
  }
}