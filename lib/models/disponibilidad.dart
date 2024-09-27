class DisponibilidadCreador {
  final String id;
  final String foto;
  final String nombre;
  final String? descripcion;
  final String? universidadNombre;
  bool isVerificadoUniversidad = false;
  String? verificadoUniversidadNombre;

  bool? isMatchLiked;
  bool? isMatch;

  bool isSuperliked;

  DisponibilidadCreador({required this.id, required this.foto, required this.nombre,
    required this.descripcion, required this.universidadNombre,
    required this.isVerificadoUniversidad, required this.verificadoUniversidadNombre,
    this.isMatchLiked, this.isMatch, required this.isSuperliked});
}

class Disponibilidad {
  final String id;
  final DisponibilidadCreador creador;
  final String texto;
  final String fecha;

  final bool isAutor;

  String? distanciaTexto;

  Disponibilidad({required this.id, required this.creador, required this.texto,
    required this.fecha, required this.isAutor, this.distanciaTexto});
}