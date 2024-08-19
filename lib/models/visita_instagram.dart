import 'package:tenfo/models/usuario.dart';

class VisitaInstagramAutor {
  final String id;
  final String nombre;
  final String nombreCompleto;
  final String username;
  final String foto;
  final String edad;
  final String? universidadNombre;
  bool isVerificadoUniversidad = false;
  String? verificadoUniversidadNombre;

  VisitaInstagramAutor({required this.id, required this.nombre, required this.nombreCompleto,
    required this.username, required this.foto, required this.edad, required this.universidadNombre,
    required this.isVerificadoUniversidad, required this.verificadoUniversidadNombre});

  Usuario toUsuario(){
    return Usuario(id: id, nombre: nombreCompleto, username: username, foto: foto);
  }
}

class VisitaInstagramPrevisualizacionAutor {
  final String edad;
  final String? universidadNombre;
  bool isVerificadoUniversidad = false;
  String? verificadoUniversidadNombre;

  VisitaInstagramPrevisualizacionAutor({required this.edad, required this.universidadNombre,
    required this.isVerificadoUniversidad, required this.verificadoUniversidadNombre});
}

class VisitaInstagram {
  final VisitaInstagramAutor? autor;
  final VisitaInstagramPrevisualizacionAutor? previsualizacionAutor;
  final String fecha;

  bool isNuevo;

  VisitaInstagram({required this.autor, required this.previsualizacionAutor,
    required this.fecha, required this.isNuevo});
}