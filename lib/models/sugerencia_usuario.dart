import 'package:tenfo/models/usuario.dart';

class SugerenciaUsuario {
  final String id;
  final String nombre;
  final String nombreCompleto;
  final String username;
  final String foto;

  final String? universidadNombre;
  bool isVerificadoUniversidad = false;
  String? verificadoUniversidadNombre;

  bool? isMatchLiked;
  bool? isMatch;

  SugerenciaUsuario({required this.id, required this.nombre, required this.nombreCompleto,
    required this.username, required this.foto, required this.universidadNombre,
    required this.isVerificadoUniversidad, required this.verificadoUniversidadNombre,
    this.isMatchLiked, this.isMatch});

  Usuario toUsuario(){
    return Usuario(id: id, nombre: nombreCompleto, username: username, foto: foto);
  }
}