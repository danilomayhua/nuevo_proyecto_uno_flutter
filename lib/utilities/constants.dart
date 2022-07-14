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

const String urlBase = "http://192.168.0.8:3000";
const String urlBaseWebSocket = "ws://192.168.0.8:3000/chat";

const String urlLogin = "/api/login";

const String urlHomeActividades = "/api/home/actividades";
const String urlHomeCambiarIntereses = "/api/home/cambiar-intereses";

const String urlVerActividad = "/api/actividad/ver";
const String urlCrearActividad = "/api/actividad/crear";
const String urlEliminarActividad = "/api/actividad/eliminar";

const String urlActividadBuscadorCocreador = "/api/actividad/buscador-agregar-cocreador";

const String urlActividadUnirse = "/api/actividad/unirse";
const String urlActividadCancelarSolicitud = "/api/actividad/cancelar-solicitud-unirse";
const String urlActividadAceptarSolicitud = "/api/actividad/aceptar-solicitud-unirse";
const String urlActividadConfirmarCocreador = "/api/actividad/confirmar-cocreador";
const String urlActividadSolicitudes = "/api/actividad/solicitudes";

const String urlBandejaChats = "/api/bandeja-chats";

const String urlChatMensajes = "/api/chat/ver-mensajes";
const String urlChatIndividualVaciar = "/api/chat/vaciar-chat-individual";
const String urlChatGrupalEliminar = "/api/chat/eliminar-chat-grupal";

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

const String urlCambiarDescripcion = "/api/perfil/cambiar-descripcion";
const String urlCambiarInstagram = "/api/perfil/cambiar-instagram";

const String urlBuscador = "/api/buscador/ver-resultados";

const String urlMisActividades = "/api/actividades-creadas/ver";
const String urlMisActividadesNoVisibles = "/api/actividades-creadas/no-visibles";



