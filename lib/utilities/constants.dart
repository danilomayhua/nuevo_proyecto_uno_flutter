import 'package:flutter/material.dart';

const Color blackGeneral = Color(0xFF424242);
const Color grey = Color(0xFF9e9e9e);
const Color greyLight = Color(0xFFbdbdbd);
const Color greyHighlight = Color(0xFF546E7A);
const Color greyBackgroundScreen = Color(0xFFFAFAFA);
const Color greyBackgroundImage = Color(0xFFE0E0E0);
const Color blueGeneral = Colors.blue;
const Color blueDisabled = Color(0xFF64b5f6);
const Color blueLight = Color(0xFF03A9F4);
const Color redAviso = Colors.red;
const Color greenLightBackground = Color(0xFFE3F0D3);

final usernameColors = [
  Colors.amber[900],
  Colors.blue[500],
  Colors.blueGrey[500],
  Colors.brown[500],
  Colors.cyan[600],
  Colors.deepOrange[500],
  Colors.deepPurple[500],
  Colors.green[500],
  Colors.grey[600],
  Colors.indigo[500],
  Colors.lightBlue[600],
  Colors.lightGreen[700],
  Colors.orange[800],
  Colors.pink[500],
  Colors.purple[500],
  Colors.red[500],
  Colors.teal[500],
];

//const String urlBase = "http://192.168.1.6:3000";
const String urlBase = "https://tenfo.app:3000";
//const String urlBaseWebSocket = "ws://192.168.1.6:3000/chat";
const String urlBaseWebSocket = "wss://tenfo.app:3000/chat";

const String urlLogin = "/api/autenticacion/login";
const String urlLogout = "/api/autenticacion/logout";

const String urlRestablecerContrasenaEnviarCodigo = "/api/autenticacion/enviar-codigo-restablecer-contrasena";
const String urlRestablecerContrasenaVerificarCodigo = "/api/autenticacion/verificar-codigo-restablecer-contrasena";
const String urlRestablecerContrasena = "/api/autenticacion/restablecer-contrasena";

const String urlRegistroEnviarCodigo = "/api/registro/enviar-codigo-email";
const String urlRegistroVerificarCodigo = "/api/registro/verificar-codigo-email";
const String urlRegistroUsuario = "/api/registro/crear-usuario";
const String urlRegistroVerificarInvitacion = "/api/registro/verificar-invitacion-codigo";
const String urlRegistroTelefonoEnviarCodigo = "/api/registro/enviar-codigo-telefono";
const String urlRegistroTelefonoVerificarCodigo = "/api/registro/verificar-codigo-telefono";
const String urlRegistroUsuarioConTelefono = "/api/registro/crear-usuario-con-telefono";
const String urlRegistroSolicitarUniversidad = "/api/registro/solicitar-universidad";
const String urlRegistroVerificarUbicacion = "/api/registro/verificar-ubicacion";
const String urlRegistroBuscarUniversidades = "/api/registro/buscar-lista-universidad";

const String urlGuardarFirebaseToken = "/api/firebase/actualizar-token";

const String urlHomeVerActividades = "/api/home/actividades-y-disponibilidades";
const String urlHomeCambiarIntereses = "/api/home/cambiar-intereses";

const String urlVerActividad = "/api/actividad/ver";
const String urlCrearActividad = "/api/actividad/crear";
const String urlEliminarActividad = "/api/actividad/eliminar";
const String urlReportarActividad = "/api/actividad/reportar";

const String urlActividadSugerenciasTitulo = "/api/actividad/sugerencias-crear-actividad";
const String urlActividadBuscadorCocreador = "/api/actividad/buscador-agregar-cocreador";
const String urlActividadCodigoCocreadorExterno = "/api/actividad/codigo-cocreador-externo";
const String urlActividadCrearInvitacionCreador = "/api/actividad/crear-invitacion-creador";
const String urlActividadCrearInvitacionCreadorActividadCreada = "/api/actividad/crear-invitacion-creador-actividad-creada";

const String urlActividadUnirse = "/api/actividad/unirse";
const String urlActividadCancelarSolicitud = "/api/actividad/cancelar-solicitud-unirse";
const String urlActividadAceptarSolicitud = "/api/actividad/aceptar-solicitud-unirse";
const String urlActividadConfirmarCocreador = "/api/actividad/confirmar-cocreador";
const String urlActividadConfirmarCocreadorInvitacion = "/api/actividad/confirmar-cocreador-invitacion";
const String urlActividadSolicitudes = "/api/actividad/solicitudes";

const String urlActividadEnviarMatchLikeActividad = "/api/actividad/enviar-match-like-actividad";
const String urlActividadEnviarMatchLikeIntegrante = "/api/actividad/enviar-match-like-integrante";
const String urlActividadVerDisponibilidadesParaMatchLike = "/api/actividad/ver-disponibilidades-para-match-like";

const String urlActividadInvitacionActividadesParaInvitar = "/api/actividad-invitacion/actividades-para-invitar";
const String urlActividadInvitacionInvitar = "/api/actividad-invitacion/invitar";

const String urlCrearDisponibilidad = "/api/disponibilidad/crear";
const String urlEliminarDisponibilidad = "/api/disponibilidad/eliminar";

const String urlDisponibilidadSugerencias = "/api/disponibilidad/sugerencias-crear-disponibilidad";

const String urlLikeActividadAgregar = "/api/like-actividad/agregar-like";
const String urlLikeActividadQuitar = "/api/like-actividad/quitar-like";

const String urlEnviarSuperlike = "/api/superlike/dar-superlike";
const String urlSuperlikesRecibidos = "/api/superlike/ver-superlikes";

const String urlBandejaChats = "/api/bandeja-chats";

const String urlChatMensajes = "/api/chat/ver-mensajes";
const String urlChatIndividualVaciar = "/api/chat/vaciar-chat-individual";
const String urlChatGrupalEliminar = "/api/chat/eliminar-chat-grupal";

const String urlChatSugerencias = "/api/chat/sugerencias-enviar-mensaje";

const String urlChatGrupalInformacion = "/api/chat/ver-informacion";
const String urlChatGrupalCambiarLink = "/api/chat/cambiar-encuentro-link";
const String urlChatGrupalCambiarFecha = "/api/chat/cambiar-encuentro-fecha";

const String urlChatGrupalSalir = "/api/chat/salir-chat-grupal";
const String urlChatEliminarIntegrante = "/api/chat/eliminar-integrante-chat-grupal";

const String urlUsuarioPerfil = "/api/usuario/ver";
const String urlUsuarioContactosMutuos = "/api/usuario/contactos-en-comun";

const String urlEnviarSolicitudContacto = "/api/usuario/enviar-solicitud-contacto";
const String urlCancelarSolicitudContacto = "/api/usuario/cancelar-solicitud-contacto";
const String urlAceptarContacto = "/api/usuario/aceptar-solicitud-contacto";
const String urlEliminarContacto = "/api/usuario/eliminar-contacto";

const String urlBloquearUsuario = "/api/usuario/bloquear";
const String urlDesbloquearUsuario = "/api/usuario/desbloquear";

const String urlEnviarVisitaUsuarioInstagram = "/api/visita-usuario/visitar-instagram";
const String urlVisitasUsuarioInstagram = "/api/visita-usuario/ver-visitas-instagram";

const String urlCompraIapVerificarSuscripcion = "/api/compra-iap/verificar-suscripcion";

const String urlStickersEnVenta = "/api/compra/ver-stickers-disponibles";
const String urlCrearCompra = "/api/compra/crear";
const String urlVerificarCompra = "/api/compra/verificar-pagado";

const String urlStickersDisponiblesEnvio = "/api/sticker/ver-stock";
const String urlEnviarStickerChatIndividual = "/api/sticker/enviar-chat-individual";
const String urlEnviarStickerChatGrupal = "/api/sticker/enviar-chat-grupal";

const String urlRetiroStickersDisponibles = "/api/retiro/ver-stickers-recibidos";
const String urlRetiroStickersCanjeados = "/api/retiro/ver-stickers-canjeados";
const String urlCrearRetiro = "/api/retiro/crear";

const String urlMisContactos = "/api/perfil/contactos";
const String urlUsuariosBloqueados = "/api/perfil/usuarios-bloqueados";
const String urlSugerenciasTelefonoContactos = "/api/perfil/sugerencias-telefono-contactos";

const String urlCambiarDescripcion = "/api/perfil/cambiar-descripcion";
const String urlCambiarInstagram = "/api/perfil/cambiar-instagram";
const String urlCambiarFotoPerfil = "/api/perfil/cambiar-foto";

const String urlConfiguracionEmailEnviarCodigo = "/api/configuracion-cuenta/email-enviar-codigo";
const String urlConfiguracionEmailVerificarCodigo = "/api/configuracion-cuenta/email-verificar-codigo";

const String urlConfiguracionCambiarUsername = "/api/configuracion-cuenta/cambiar-username";
const String urlConfiguracionCambiarNombre = "/api/configuracion-cuenta/cambiar-nombre";
const String urlConfiguracionCambiarNacimiento = "/api/configuracion-cuenta/cambiar-nacimiento";
const String urlConfiguracionCambiarContrasena = "/api/configuracion-cuenta/cambiar-contrasena";
const String urlConfiguracionEliminarCuenta = "/api/configuracion-cuenta/eliminar-cuenta";

const String urlInvitacionCantidadDisponible = "/api/invitacion/cantidad-disponible";
const String urlInvitacionHabilitarEmail = "/api/invitacion/habilitar-email";

const String urlCrearFeedback = "/api/feedback/crear";

const String urlBuscador = "/api/buscador/ver-resultados";

const String urlMisActividades = "/api/actividades-creadas/ver";
const String urlMisActividadesNoVisibles = "/api/actividades-creadas/no-visibles";

const String urlVerNotificaciones = "/api/notificaciones/ver";

const String urlNumeroPendientesNotificacionesAvisos = "/api/notificaciones/ver-numero-pendientes-y-avisos";

const String urlCrearHistorialUsuarioActivo = "/api/historial-usuario-activo/crear";

const String urlCrearHistorialNoUsuario = "/api/historial-no-usuario/crear";


const String urlExternoCotizacionBTC = "https://criptoya.com/api/lemoncash/btc/ars";

