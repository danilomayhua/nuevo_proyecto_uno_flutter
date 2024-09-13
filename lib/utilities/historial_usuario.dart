import 'package:tenfo/models/signup_permisos_estado.dart';
import 'package:tenfo/widgets/actividad_boton_enviar.dart';

class HistorialUsuario {

  static const String _crearActividadPasoDos = "/crear-actividad/paso-dos";
  static const String _crearActividadCocreadoresInformacion = "/crear-actividad/cocreadores-informacion";
  static const String _crearActividadBuscador = "/crear-actividad/buscador";
  static const String _crearActividadBuscadorCodigoInformacion = "/crear-actividad/buscador/codigo-informacion";
  static const String _crearActividadBuscadorResultado = "/crear-actividad/buscador/resultado";
  static const String _crearActividadCocreadoresInvitarAmigo = "/crear-actividad/cocreadores-invitar-amigo";

  static const String _contactosInvitarAmigo = "/contactos/invitar-amigo";

  static const String _contactosSugerenciasInvitarAmigo = "/contactos-sugerencias/invitar-amigo";
  static const String _contactosSugerenciasInvitarAmigosWhatsapp = "/contactos-sugerencias/invitar-amigos-whatsapp";
  static const String _contactosSugerenciasPermisoContactos = "/contactos-sugerencias/permiso-telefono-contactos";
  static const String _contactosSugerenciasOmitir = "/contactos-sugerencias/omitir";

  static const String _perfilInvitarAmigo = "/perfil/invitar-amigo";

  static const String _seleccionarCrearTipo = "/crear/seleccionar-tipo";

  static const String _agregarFoto = "/agregar-foto";
  static const String _agregarFotoOmitir = "/agregar-foto/omitir";

  static const String _actividadInvitarAmigo = "/actividad/invitar-amigo";
  static const String _actividadCocreadoresInvitarAmigo = "/actividad/cocreadores-invitar-amigo";

  static const String _actividadEnviarWhatsapp = "/actividad-enviar/whatsapp";
  static const String _actividadEnviarCopiar = "/actividad-enviar/copiar";
  static const String _actividadEnviarCompartir = "/actividad-enviar/compartir";

  static const String _actividadPageEnviarWhatsapp = "/actividad-page-enviar/whatsapp";
  static const String _actividadPageEnviarCopiar = "/actividad-page-enviar/copiar";
  static const String _actividadPageEnviarCompartir = "/actividad-page-enviar/compartir";

  static const String _chatActividadEnviarWhatsapp = "/chat-actividad-enviar/whatsapp";
  static const String _chatActividadEnviarCopiar = "/chat-actividad-enviar/copiar";
  static const String _chatActividadEnviarCompartir = "/chat-actividad-enviar/compartir";

  static const String _bandejaChatsNotificaciones = "/bandeja-chats/notificaciones-push";
  static const String _bandejaChatsNotificacionesActivar = "/bandeja-chats/notificaciones-push/activar";

  static const String _homeNotificaciones = "/home/notificaciones-push";


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

  /// En CrearActividad, cuando obtiene resultado del buscador de cocreador
  static Map<String, dynamic> getCrearActividadCocreadoresInvitarAmigo(String numero){
    return {
      "evento": _crearActividadCocreadoresInvitarAmigo,
      "datos_adicionales": {
        "telefono_contacto_numero" : numero,
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

  /// En ContactosSugerencias o en SignupFriends, cuando invita a un amigo
  static Map<String, dynamic> getContactosSugerenciasInvitarAmigo(String numero, {bool isFromSignup = false}){
    return {
      "evento": _contactosSugerenciasInvitarAmigo,
      "datos_adicionales": {
        "telefono_contacto_numero" : numero,
        "enviado_desde": isFromSignup ? "registro" : "agregar-amigos",
      }
    };
  }

  /// En ContactosSugerencias o en SignupFriends, cuando invita en general en whatsapp
  static Map<String, dynamic> getContactosSugerenciasInvitarAmigosWhatsapp({bool isFromSignup = false}){
    return {
      "evento": _contactosSugerenciasInvitarAmigosWhatsapp,
      "datos_adicionales": {
        "enviado_desde": isFromSignup ? "registro" : "agregar-amigos",
      }
    };
  }

  /// En SignupFriends, cuando aparece popup permiso Contactos
  static Map<String, dynamic> getContactosSugerenciasPermisoContactos(bool isAceptado){
    return {
      "evento": _contactosSugerenciasPermisoContactos,
      "datos_adicionales": {
        "permiso_telefono_contactos_aceptado": isAceptado ? "SI" : "NO",
      }
    };
  }

  /// En SignupFriends, cuando avanza sin invitar o agregar amigos
  static Map<String, dynamic> getContactosSugerenciasOmitir(){
    return {
      "evento": _contactosSugerenciasOmitir,
      "datos_adicionales": {}
    };
  }

  /// En Perfil, cuando presiona compartir
  static Map<String, dynamic> getPerfilInvitarAmigo(){
    return {
      "evento": _perfilInvitarAmigo,
      "datos_adicionales": {}
    };
  }

  /// En SeleccionarCrearTipo, cuando ingresa a la pantalla
  static Map<String, dynamic> getSeleccionarCrearTipo({bool isFromSignup = false}){
    return {
      "evento": _seleccionarCrearTipo,
      "datos_adicionales": {
        "enviado_desde": isFromSignup ? "registro" : "principal",
      }
    };
  }

  /// En SignupPicture, cuando ingresa a la pantalla
  static Map<String, dynamic> getAgregarFoto(SignupPermisosEstado? signupPermisosEstado){

    if(signupPermisosEstado != null){
      // Envia estos datos cuando ingresa la primera vez en el registro
      return {
        "evento": _agregarFoto,
        "datos_adicionales": {
          "permiso_ubicacion_aceptado": signupPermisosEstado.isPermisoUbicacionAceptado ? "SI" : "NO",
          "permiso_telefono_contactos_aceptado": signupPermisosEstado.isPermisoTelefonoContactosAceptado ? "SI" : "NO",
          "permiso_notificaciones_aceptado": signupPermisosEstado.isPermisoNotificacionesAceptado ? "SI" : "NO",
          "requiere_permiso_notificaciones": signupPermisosEstado.isRequierePermisoNotificaciones ? "SI" : "NO",
        }
      };
    } else {
      return {
        "evento": _agregarFoto,
        "datos_adicionales": {}
      };
    }

  }

  /// En SignupPicture, cuando omite el agregar una foto de perfil
  static Map<String, dynamic> getAgregarFotoOmitir(){
    return {
      "evento": _agregarFotoOmitir,
      "datos_adicionales": {}
    };
  }

  /// En Actividad, cuando invita a un amigo
  static Map<String, dynamic> getActividadInvitarAmigo(String actividadId, {bool isIntegrante = false}){
    return {
      "evento": _actividadInvitarAmigo,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": isIntegrante ? "actividad-integrante" : "actividad-no-integrante",
      }
    };
  }

  /// En Actividad, cuando invita a un amigo a cocreadores
  static Map<String, dynamic> getActividadCocreadoresInvitarAmigo(String actividadId){
    return {
      "evento": _actividadCocreadoresInvitarAmigo,
      "datos_adicionales": {
        "actividad_id": actividadId,
      }
    };
  }

  /// En boton ActividadEnviar, cuando elige whatsapp
  static Map<String, dynamic> getActividadEnviarWhatsapp(String actividadId, {ActividadBotonEnviarFromPantalla? fromPantalla}){
    return {
      "evento": _actividadEnviarWhatsapp,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": (fromPantalla == null) ? null : fromPantalla.name,
      }
    };
  }

  /// En boton ActividadEnviar, cuando elige copiar link
  static Map<String, dynamic> getActividadEnviarCopiar(String actividadId, {ActividadBotonEnviarFromPantalla? fromPantalla}){
    return {
      "evento": _actividadEnviarCopiar,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": (fromPantalla == null) ? null : fromPantalla.name,
      }
    };
  }

  /// En boton ActividadEnviar, cuando elige compartir
  static Map<String, dynamic> getActividadEnviarCompartir(String actividadId, {ActividadBotonEnviarFromPantalla? fromPantalla}){
    return {
      "evento": _actividadEnviarCompartir,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": (fromPantalla == null) ? null : fromPantalla.name,
      }
    };
  }

  /// En Actividad, cuando elige invitar mediante whatsapp
  static Map<String, dynamic> getActividadPageEnviarWhatsapp(String actividadId, {bool isAutor = false}){
    return {
      "evento": _actividadPageEnviarWhatsapp,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": isAutor ? "actividad-autor" : "actividad-integrante",
      }
    };
  }

  /// En Actividad, cuando elige invitar mediante copiar link
  static Map<String, dynamic> getActividadPageEnviarCopiar(String actividadId, {bool isAutor = false}){
    return {
      "evento": _actividadPageEnviarCopiar,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": isAutor ? "actividad-autor" : "actividad-integrante",
      }
    };
  }

  /// En Actividad, cuando elige invitar mediante compartir
  static Map<String, dynamic> getActividadPageEnviarCompartir(String actividadId, {bool isAutor = false}){
    return {
      "evento": _actividadPageEnviarCompartir,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": isAutor ? "actividad-autor" : "actividad-integrante",
      }
    };
  }

  /// En ChatGrupal, cuando elige invitar mediante whatsapp
  static Map<String, dynamic> getChatActividadEnviarWhatsapp(String actividadId, {bool isAutor = false}){
    return {
      "evento": _chatActividadEnviarWhatsapp,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": isAutor ? "chat-actividad-autor" : "chat-actividad-integrante",
      }
    };
  }

  /// En ChatGrupal, cuando elige invitar mediante copiar link
  static Map<String, dynamic> getChatActividadEnviarCopiar(String actividadId, {bool isAutor = false}){
    return {
      "evento": _chatActividadEnviarCopiar,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": isAutor ? "chat-actividad-autor" : "chat-actividad-integrante",
      }
    };
  }

  /// En ChatGrupal, cuando elige invitar mediante compartir
  static Map<String, dynamic> getChatActividadEnviarCompartir(String actividadId, {bool isAutor = false}){
    return {
      "evento": _chatActividadEnviarCompartir,
      "datos_adicionales": {
        "actividad_id": actividadId,
        "enviado_desde": isAutor ? "chat-actividad-autor" : "chat-actividad-integrante",
      }
    };
  }

  /// En Mensajes, cuando aparece popup notificaciones push
  static Map<String, dynamic> getBandejaChatsNotificaciones(bool isAceptado){
    return {
      "evento": _bandejaChatsNotificaciones,
      "datos_adicionales": {
        "permiso_notificaciones_aceptado": isAceptado ? "SI" : "NO",
      }
    };
  }

  /// En Mensajes, cuando acepta las notificaciones push
  static Map<String, dynamic> getBandejaChatsNotificacionesActivar(bool isAceptado){
    return {
      "evento": _bandejaChatsNotificacionesActivar,
      "datos_adicionales": {
        "permiso_notificaciones_aceptado": isAceptado ? "SI" : "NO",
      }
    };
  }

  /// En Home, cuando aparece popup notificaciones push
  static Map<String, dynamic> getHomeNotificaciones(bool isAceptado){
    return {
      "evento": _homeNotificaciones,
      "datos_adicionales": {
        "permiso_notificaciones_aceptado": isAceptado ? "SI" : "NO",
      }
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