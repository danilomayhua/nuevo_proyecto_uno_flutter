class SignupPermisosEstado {
  bool isPermisoUbicacionAceptado;
  bool isPermisoNotificacionesAceptado;

  bool isRequierePermisoNotificaciones;

  SignupPermisosEstado({
    required this.isPermisoUbicacionAceptado,
    required this.isPermisoNotificacionesAceptado,
    required this.isRequierePermisoNotificaciones,
  });
}