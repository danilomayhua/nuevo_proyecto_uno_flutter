class DisponibilidadCreador {
  final String id;
  final String foto;
  final String nombre;
  bool isVerificadoUniversidad = false;
  String? verificadoUniversidadNombre;

  DisponibilidadCreador({required this.id, required this.foto, required this.nombre,
    required this.isVerificadoUniversidad, required this.verificadoUniversidadNombre});
}

class Disponibilidad {
  final String id;
  final DisponibilidadCreador creador;
  final String texto;
  final String fecha;

  final bool isAutor;

  Disponibilidad({required this.id, required this.creador, required this.texto,
    required this.fecha, required this.isAutor});
}