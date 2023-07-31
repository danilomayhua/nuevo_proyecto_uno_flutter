class HistorialUsuario {

  static const String _crearActividadPasoDos = "/crear-actividad/paso-dos";
  static const String _crearActividadCocreadoresInformacion = "/crear-actividad/cocreadores-informacion";
  static const String _crearActividadBuscador = "/crear-actividad/buscador";
  static const String _crearActividadBuscadorCodigoInformacion = "/crear-actividad/buscador/codigo-informacion";
  static const String _crearActividadBuscadorResultado = "/crear-actividad/buscador/resultado";

  static const String _contactosInvitarAmigo = "/contactos/invitar-amigo";


  /// En CrearActividad, cuando ingresa a la segunda pantalla
  static Map<String, dynamic> getCrearActividadPasoDos(){
    return {
      "evento": _crearActividadPasoDos,
      "datos_adicionales": {}
    };
  }

  /// En CrearActividad, cuando ingresa a "Más información" de Agregar Cocreadores
  static Map<String, dynamic> getCrearActividadCocreadoresInformacion(){
    return {
      "evento": _crearActividadCocreadoresInformacion,
      "datos_adicionales": {}
    };
  }

  /// En CrearActividad, cuando ingresa al buscador de cocreador
  static Map<String, dynamic> getCrearActividadBuscador(){
    return {
      "evento": _crearActividadBuscador,
      "datos_adicionales": {}
    };
  }

  /// En CrearActividad, cuando ingresa a "Mas informacion" del codigo de invitacion
  static Map<String, dynamic> getCrearActividadBuscadorCodigoInformacion(){
    return {
      "evento": _crearActividadBuscadorCodigoInformacion,
      "datos_adicionales": {}
    };
  }

  /// En CrearActividad, cuando obtiene resultado del buscador de cocreador
  static Map<String, dynamic> getCrearActividadBuscadorResultado(String texto, List<String>? resultadoUsuariosId){
    // Si resultadoUsuariosId es null, hubo un error al hacer la busqueda
    return {
      "evento": _crearActividadBuscadorResultado,
      "datos_adicionales": {
        "texto": texto,
        "resultado_usuarios_id": resultadoUsuariosId,
      }
    };
  }

  /// En Contactos, cuando invita a un amigo
  static Map<String, dynamic> getContactosInvitarAmigo(){
    return {
      "evento": _contactosInvitarAmigo,
      "datos_adicionales": {}
    };
  }

  static bool containsEvento(List<Map<String, dynamic>> historiales, Map<String, dynamic> historialBuscar){

    bool contieneEvento = false;

    for (var element in historiales) {
      if(element["evento"] == historialBuscar["evento"]){
        contieneEvento = true;
        break;
      }
    }

    return contieneEvento;
  }

}