class SignupPermisosEstado {
  bool isPermisoUbicacionAceptado;
  bool isPermisoTelefonoContactosAceptado;
  bool isPermisoNotificacionesAceptado;

  bool isRequierePermisoNotificaciones;

  SignupPermisosEstado({
    required this.isPermisoUbicacionAceptado,
    required this.isPermisoTelefonoContactosAceptado,
    required this.isPermisoNotificacionesAceptado,
    required this.isRequierePermisoNotificaciones,
  });
}