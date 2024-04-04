class PrevisualizacionActividadCreador {
  //final String id;
  final String foto;
  final String nombre;

  PrevisualizacionActividadCreador({required this.foto, required this.nombre});
}

class PrevisualizacionActividad {
  //final String id;
  final String titulo;
  final String fecha;
  final String fechaCompleto;
  final List<PrevisualizacionActividadCreador> creadores;

  PrevisualizacionActividad({required this.titulo, required this.fecha, required this.fechaCompleto,
    required this.creadores});
}