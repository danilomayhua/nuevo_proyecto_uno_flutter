import 'package:tenfo/models/usuario.dart';

class UsuarioChatSolicitud {
  final Usuario usuario;
  bool aceptado;

  UsuarioChatSolicitud({required this.usuario, this.aceptado = false});
}