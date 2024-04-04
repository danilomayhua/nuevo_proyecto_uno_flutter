class HistorialNoUsuario {

  static const String _registroUniversidadElegir = "/registro/universidad/elegir";
  static const String _registroPerfilCancelar = "/registro/perfil/cancelar";


  /// En SignupUniversity, cuando elige una universidad
  static Map<String, dynamic> getRegistroUniversidadElegir(String universidadId){
    return {
      "evento": _registroUniversidadElegir,
      "datos_adicionales": {
        "universidad_id": universidadId,
      }
    };
  }

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