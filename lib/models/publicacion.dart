import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/disponibilidad.dart';

enum PublicacionTipo {
  ACTIVIDAD,
  DISPONIBILIDAD
}

class Publicacion {
  final PublicacionTipo tipo;
  Actividad? actividad;
  Disponibilidad? disponibilidad;

  Publicacion({required this.tipo, this.actividad, this.disponibilidad});

  static PublicacionTipo getPublicacionTipoFromString(String tipoString){
    if(tipoString == "ACTIVIDAD"){
      return PublicacionTipo.ACTIVIDAD;
    } else if(tipoString == "DISPONIBILIDAD"){
      return PublicacionTipo.DISPONIBILIDAD;
    } else {
      return PublicacionTipo.ACTIVIDAD;
    }
  }
}