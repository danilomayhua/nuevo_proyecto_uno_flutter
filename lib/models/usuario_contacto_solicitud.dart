import 'package:tenfo/models/usuario.dart';

class UsuarioContactoSolicitud {
  final Usuario usuario;
  bool isEnviando;
  bool isSolicitudEnviado;

  UsuarioContactoSolicitud({required this.usuario, this.isEnviando = false, this.isSolicitudEnviado = false});
}