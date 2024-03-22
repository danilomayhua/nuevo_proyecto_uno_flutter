class HistorialNoUsuario {

  static const String _registroPerfilCancelar = "/registro/perfil/cancelar";


  /// En SignupProfile, cuando abandona el registro
  static Map<String, dynamic> getRegistroPerfilCancelar(String registroPasoVisto, String? nombre, String? apellido,
      String? nacimiento, String? username, bool isContrasenaCompletado){
    return {
      "evento": _registroPerfilCancelar,
      "datos_adicionales": {
        "registro_paso_visto": registroPasoVisto,
        "nombre": nombre,
        "apellido": apellido,
        "nacimiento_fecha": nacimiento,
        "username": username,
        "contrasena_completado": isContrasenaCompletado ? "SI" : "NO",
      }
    };
  }

}