import 'package:tenfo/models/usuario.dart';

class InvitacionActividad {
  final String actividadId;
  final String titulo;
  final String fecha;
  final List<Usuario> creadores;

  final bool isUsuarioInvitado;

  final int invitacionesRealizadas;
  final int invitacionesTotal;

  InvitacionActividad({required this.actividadId, required this.titulo, required this.fecha,
    required this.creadores, required this.isUsuarioInvitado, required this.invitacionesRealizadas,
    required this.invitacionesTotal,});
}