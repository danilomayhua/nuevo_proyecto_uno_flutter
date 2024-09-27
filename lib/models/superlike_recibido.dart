import 'package:tenfo/models/usuario.dart';

class SuperlikeRecibidoAutor {
  final String id;
  final String nombre;
  final String nombreCompleto;
  final String username;
  final String foto;
  final String edad;
  final String? universidadNombre;
  bool isVerificadoUniversidad = false;
  String? verificadoUniversidadNombre;

  SuperlikeRecibidoAutor({required this.id, required this.nombre, required this.nombreCompleto,
    required this.username, required this.foto, required this.edad, required this.universidadNombre,
    required this.isVerificadoUniversidad, required this.verificadoUniversidadNombre});

  Usuario toUsuario(){
    return Usuario(id: id, nombre: nombreCompleto, username: username, foto: foto);
  }
}

class SuperlikeRecibidoPrevisualizacionAutor {
  final String edad;
  final String? universidadNombre;
  bool isVerificadoUniversidad = false;
  String? verificadoUniversidadNombre;

  SuperlikeRecibidoPrevisualizacionAutor({required this.edad, required this.universidadNombre,
    required this.isVerificadoUniversidad, required this.verificadoUniversidadNombre});
}

class SuperlikeRecibido {
  final SuperlikeRecibidoAutor? autor;
  final SuperlikeRecibidoPrevisualizacionAutor? previsualizacionAutor;
  final String fecha;

  final String? texto;

  bool isNuevo;

  SuperlikeRecibido({required this.autor, required this.previsualizacionAutor,
    required this.fecha, required this.isNuevo, this.texto});
}