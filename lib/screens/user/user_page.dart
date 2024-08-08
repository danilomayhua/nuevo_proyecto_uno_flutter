import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_perfil.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/canjear_stickers/canjear_stickers_page.dart';
import 'package:tenfo/screens/chat/chat_page.dart';
import 'package:tenfo/screens/comprar_suscripcion/comprar_suscripcion_page.dart';
import 'package:tenfo/screens/contactos_mutuos/contactos_mutuos_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/settings/settings_page.dart';
import 'package:tenfo/screens/verificar_universidad/verificar_universidad_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/share_utils.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:tenfo/utilities/universidades.dart';
import 'package:tenfo/widgets/dialog_enviar_sticker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/widgets/icon_universidad_verificada.dart';
import 'package:url_launcher/url_launcher.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key, required this.usuario, this.isFromProfile = false, this.compartenGrupoChatId, this.routeUsername}) : super(key: key);

  final Usuario? usuario;
  final bool isFromProfile;
  final String? compartenGrupoChatId;
  final String? routeUsername;

  @override
  State<UserPage> createState() => _UserPageState();
}

enum _PopupMenuOption { bloquearUsuario, desbloquearUsuario }

class _UserPageState extends State<UserPage> {

  late UsuarioPerfil _usuarioPerfil;

  bool _isloadingRouteUsername = false;

  bool _loadingPerfil = false;
  bool _enviandoBotonContacto = false;

  List<Sticker> _stickersRecibidos = [];

  UsuarioSesion? _usuarioSesion = null;

  final TextEditingController _descripcionController = TextEditingController();
  bool _enviandoDescripcion = false;

  final RegExp _regExpInstagram = RegExp(r'^(?!.*\.\.)(?!.*\.$)[^\W][\w.]{0,29}$');
  final TextEditingController _instagramController = TextEditingController();
  String? _instagramErrorText;
  bool _enviandoInstagram = false;

  bool _enviandoFotoPerfil = false;

  @override
  void initState() {
    super.initState();

    if(widget.usuario == null){
      // Si widget.usuario es nulo, tiene que enviar widget.routeUsername
      _isloadingRouteUsername = true;

      // Verifica sesion siempre que viene desde un route (deep linking)
      _verificarSesion();

      // No usar _usuarioPerfil hasta que cargue el usuario

      return;
    }

    _usuarioPerfil = UsuarioPerfil(
      id: widget.usuario!.id,
      nombre: widget.usuario!.nombre,
      username: widget.usuario!.username,
      foto: widget.usuario!.foto,
    );

    if(widget.isFromProfile){

      _actualizarUsuarioPerfilSesion();

      _cargarUsuario(null);

    } else {
      _cargarUsuario(null);
    }
  }

  Future<void> _verificarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(SharedPreferencesKeys.isLoggedIn) ?? false;

    if(!isLoggedIn){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) => const WelcomePage()
      ), (route) => false);

      return;
    }

    _cargarUsuario(widget.routeUsername ?? "");
  }

  @override
  Widget build(BuildContext context) {

    if(_isloadingRouteUsername){
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.routeUsername ?? ""),
        ),
        body: Center(
          child: _loadingPerfil ? const CircularProgressIndicator() : Container(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Flexible(
            child: Text(_usuarioPerfil.username, overflow: TextOverflow.ellipsis,),
          ),
          if(_usuarioPerfil.isVerificadoUniversidad)
            ...[
              const SizedBox(width: 6,),
              GestureDetector(
                onTap: (){
                  _showDialogUniversidadVerificada();
                },
                child: const IconUniversidadVerificada(size: 20),
              ),
            ],
        ],),
        actions: [

          if(widget.isFromProfile)
            ...[

              if(_usuarioSesion != null && _usuarioSesion!.isAdmin)
                IconButton(
                  icon: const Icon(Icons.store_outlined),
                  onPressed: () async {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const ComprarSuscripcionPage()
                    ));
                  },
                ),

              // Solo puede verificar si no tiene email
              if(_usuarioSesion != null && _usuarioSesion!.email == null)
                IconButton(
                  icon: const Icon(Icons.school_outlined),
                  onPressed: () async {
                    _showDialogVerificarse();
                  },
                ),

              IconButton(
                icon: const Icon(Icons.manage_accounts_outlined),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => SettingsPage(usuario: _usuarioPerfil)
                  ));

                  // Actualiza los datos, por si hubo algun cambio
                  _actualizarUsuarioPerfilSesion();
                },
              ),
            ],

          if(!widget.isFromProfile && !_isUsuarioSesion() && _usuarioPerfil.contactoEstado != null
              && _usuarioPerfil.contactoEstado != UsuarioPerfilContactoEstado.BLOQUEO_RECIBIDO)
            PopupMenuButton<_PopupMenuOption>(
              onSelected: (_PopupMenuOption result) {
                if(result == _PopupMenuOption.bloquearUsuario){
                  _showDialogBloquearUsuario();
                } else if(result == _PopupMenuOption.desbloquearUsuario){
                  _showDialogDesbloquearUsuario();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<_PopupMenuOption>>[
                _usuarioPerfil.contactoEstado != UsuarioPerfilContactoEstado.BLOQUEO_ENVIADO
                    ? const PopupMenuItem<_PopupMenuOption>(
                      value: _PopupMenuOption.bloquearUsuario,
                      child: Text('Bloquear usuario'),
                    )
                    : const PopupMenuItem<_PopupMenuOption>(
                      value: _PopupMenuOption.desbloquearUsuario,
                      child: Text('Desbloquear usuario'),
                    ),
              ],
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          _buildSeccionDatos(),
          if(!widget.isFromProfile && !_isUsuarioSesion() && !_isUsuarioBloqueado())
            _buildSeccionBotones(),
        ],
      ),
    );
  }

  void _showDialogUniversidadVerificada(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            RichText(
              textAlign: TextAlign.left,
              text: const TextSpan(
                style: TextStyle(color: constants.blackGeneral, fontSize: 16, fontWeight: FontWeight.bold,),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8,),
                      child: IconUniversidadVerificada(size: 25),
                    ),
                  ),
                  TextSpan(
                    text: "Universidad verificada",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16,),
            Text("Este perfil cuenta con un correo verificado de la ${_usuarioPerfil.verificadoUniversidadNombre ?? ""}. Los perfiles sin esta insignia "
                "corresponden a usuarios que no utilizaron un correo de estudiante.",
              style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
              textAlign: TextAlign.left,
            ),
          ], mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      );
    });
  }

  void _actualizarUsuarioPerfilSesion(){
    SharedPreferences.getInstance().then((prefs){

      // Estos datos se pudieron haber cargado desde _cargarUsuario (por ahora no estan guardados en UsuarioSesion)
      bool isVerificadoUniversidad = _usuarioPerfil.isVerificadoUniversidad;
      String? verificadoUniversidadNombre = _usuarioPerfil.verificadoUniversidadNombre;

      UsuarioPerfilUniversidad? usuarioPerfilUniversidad = _usuarioPerfil.universidad;


      _usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _usuarioPerfil = UsuarioPerfil(
        id: _usuarioSesion!.id,
        nombre: _usuarioSesion!.nombre_completo,
        username: _usuarioSesion!.username,
        foto: _usuarioSesion!.foto,
      );

      _usuarioPerfil.descripcion = _usuarioSesion!.descripcion;
      _usuarioPerfil.instagram = _usuarioSesion!.instagram;

      if(usuarioPerfilUniversidad == null && _usuarioSesion!.universidad_id != null){
        // Solo los usuarios nuevos tienen universidad_id en UsuarioSesion
        String universidadId = _usuarioSesion!.universidad_id!;
        usuarioPerfilUniversidad = UsuarioPerfilUniversidad(id: universidadId, nombre: Universidades.getNombre(universidadId),);
      }
      _usuarioPerfil.universidad = usuarioPerfilUniversidad;

      _usuarioPerfil.isVerificadoUniversidad = isVerificadoUniversidad;
      _usuarioPerfil.verificadoUniversidadNombre = verificadoUniversidadNombre;

      setState(() {});
    });
  }

  bool _isUsuarioSesion(){
    if(_usuarioSesion != null && _usuarioSesion!.id == _usuarioPerfil.id){
      return true;
    } else {
      return false;
    }
  }

  bool _isUsuarioBloqueado(){
    if(_usuarioPerfil.contactoEstado != UsuarioPerfilContactoEstado.BLOQUEO_RECIBIDO
        && _usuarioPerfil.contactoEstado != UsuarioPerfilContactoEstado.BLOQUEO_ENVIADO){
      return false;
    } else {
      return true;
    }
  }

  Widget _buildSeccionDatos(){
    return SliverToBoxAdapter(
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 16),
            child: widget.isFromProfile
              ? GestureDetector(
                onTap: _enviandoFotoPerfil ? null : () => _showDialogCambiarFoto(),
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: CachedNetworkImageProvider(_usuarioPerfil.foto),
                  backgroundColor: Colors.transparent,
                  child: _enviandoFotoPerfil ? const CircularProgressIndicator() : null,
                ),
              )
              : CircleAvatar(
                radius: 80,
                backgroundImage: CachedNetworkImageProvider(_usuarioPerfil.foto),
                backgroundColor: Colors.transparent,
              ),
          ),
          Padding(
              padding: EdgeInsets.all(16),
              child: Text(_usuarioPerfil.nombre,
                style: TextStyle(color: constants.blackGeneral, fontSize: 28),
                textAlign: TextAlign.center,
              )
          ),

          if(_usuarioPerfil.descripcion != null)
            Padding(
              padding: EdgeInsets.only(top: 0, right: 16, bottom: 16, left: 16),
              child: Text(_usuarioPerfil.descripcion!,
                style: TextStyle(color: constants.grey, fontSize: 16, height: 1.3,),
                textAlign: TextAlign.center,
              ),
            ),
          if(widget.isFromProfile && _usuarioSesion != null && _usuarioPerfil.descripcion == null)
            GestureDetector(
              onTap: (){
                _showDialogCambiarDescripcion();
              },
              child: const Padding(
                padding: EdgeInsets.only(top: 0, right: 16, bottom: 16, left: 16),
                child: Text("Agregar descripción",
                  style: TextStyle(color: constants.blueGeneral, fontSize: 12),
                ),
              ),
            ),

          Container(
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(color: constants.greyLight),
            height: 1,
            width: 200,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16,),
            child: Column(
              children: [
                const SizedBox(height: 32, width: double.maxFinite,),

                if(_usuarioPerfil.universidad != null)
                  ...[
                    Row(children: [
                      const Icon(Icons.school_outlined, size: 20, color: constants.blackGeneral,),
                      const SizedBox(width: 8,),
                      Text(_usuarioPerfil.universidad!.nombre,
                        style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
                      ),
                    ]),
                  ],

                const SizedBox(height: 8,),

                if(_usuarioPerfil.instagram != null || widget.isFromProfile)
                  ...[
                    if(_usuarioPerfil.instagram != null)
                      InkWell(
                        onTap: () async {
                          String urlString = "https://www.instagram.com/${_usuarioPerfil.instagram}";
                          Uri url = Uri.parse(urlString);

                          try {
                            await launchUrl(url, mode: LaunchMode.externalApplication,);
                          } catch (e){
                            throw 'Could not launch $urlString';
                          }
                        },
                        child: Row(children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8,),
                            height: 18,
                            width: 18,
                            child: Image.asset("assets/instagram_logo.png"),
                          ),
                          const SizedBox(width: 8,),
                          Text(_usuarioPerfil.instagram!,
                            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                          ),
                          const SizedBox(width: 16,),
                        ], mainAxisSize: MainAxisSize.min,),
                      ),

                    if(widget.isFromProfile && _usuarioSesion != null && _usuarioPerfil.instagram == null)
                      InkWell(
                        onTap: (){
                          _showDialogCambiarInstagram();
                        },
                        child: Row(children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8,),
                            height: 18,
                            width: 18,
                            child: Image.asset("assets/instagram_logo.png"),
                          ),
                          const SizedBox(width: 8,),
                          const Text("Agregar instagram",
                            style: TextStyle(color: constants.blueGeneral, fontSize: 12,),
                          ),
                          const SizedBox(width: 16,),
                        ], mainAxisSize: MainAxisSize.min,),
                      ),

                    const SizedBox(height: 8,),
                  ],


                if(widget.isFromProfile && _usuarioSesion != null)
                  ...[
                    const SizedBox(height: 48,),
                    Row(children: [

                      /*
                      // Solo puede verificar si no tiene email
                      if(_usuarioSesion!.email == null)
                        ...[
                          Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                            child: OutlinedButton.icon(
                              onPressed: (){
                                _showDialogVerificarse();
                              },
                              icon: const IconUniversidadVerificada(size: 20, isEnabled: false,),
                              label: const Text("Verifícate",
                                style: TextStyle(fontSize: 14,),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: const StadiumBorder(),
                                primary: Colors.blueGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16,),
                        ],
                      */

                      Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                        child: OutlinedButton.icon(
                          onPressed: (){
                            ShareUtils.shareProfile(_usuarioSesion);

                            // Envia historial del usuario
                            _enviarHistorialUsuario(HistorialUsuario.getPerfilInvitarAmigo());
                          },
                          icon: const Icon(Icons.ios_share, size: 20,),
                          label: const Text("Compartir perfil",
                            style: TextStyle(fontSize: 14,),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            primary: Colors.blueGrey,
                          ),
                        ),
                      ),

                    ], mainAxisAlignment: MainAxisAlignment.center,),
                    const SizedBox(height: 16,),
                  ],

                if(_loadingPerfil)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if(!widget.isFromProfile && !_isUsuarioSesion())
                  _buildBotonContacto(),

                if(!widget.isFromProfile && !_isUsuarioSesion() && !_isUsuarioBloqueado() && _usuarioPerfil.contactosMutuos != null)
                  ...[
                    /*
                    if(_usuarioPerfil.contactosMutuos!.isEmpty)
                      const Text("No hay amigos en común", style: TextStyle(color: constants.grey, fontSize: 12),),
                    */

                    if(_usuarioPerfil.contactosMutuos!.isNotEmpty)
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => ContactosMutuosPage(usuario: _usuarioPerfil),
                          ));
                        },
                        child: Row(
                          children: [
                            SizedBox(
                              width: (15 * _usuarioPerfil.contactosMutuos!.length) + 10,
                              height: 20,
                              child: Stack(
                                children: [
                                  Container(),
                                  for (int i=(_usuarioPerfil.contactosMutuos!.length-1); i>=0; i--)
                                    Positioned(
                                      left: (15 * i).toDouble(),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: constants.grey),
                                        ),
                                        height: 20,
                                        width: 20,
                                        child: CircleAvatar(
                                          backgroundColor: constants.greyBackgroundImage,
                                          backgroundImage: CachedNetworkImageProvider(_usuarioPerfil.contactosMutuos![i].foto),
                                          //radius: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text("${_usuarioPerfil.totalContactosMutuos} amigos en común",
                              style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                  ],

                if(_stickersRecibidos.isNotEmpty)
                  ...[
                    SizedBox(height: widget.isFromProfile ? 24 : 32),
                    const Text("Últimos stickers recibidos", style: TextStyle(color: constants.blackGeneral)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _stickersRecibidos.length,
                        itemBuilder: (context, index){

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  height: 36,
                                  width: 40,
                                  padding: const EdgeInsets.symmetric(vertical: 4,),
                                  margin: const EdgeInsets.only(right: 4),
                                  child: _stickersRecibidos[index].getImageAssetName() != null
                                      ? Image.asset(_stickersRecibidos[index].getImageAssetName()!)
                                      : null,
                                ),
                                Text((_stickersRecibidos[index].numeroDisponibles ?? 0) > 1
                                    ? "×${_stickersRecibidos[index].numeroDisponibles}"
                                    : "",
                                  style: const TextStyle(
                                    color: constants.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );

                        },
                      ),
                    ),
                    if(widget.isFromProfile)
                      Container(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => CanjearStickersPage(),
                            ));
                          },
                          child: const Text("Canjear stickers",),
                        ),
                      ),
                  ],

                const SizedBox(height: 16),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
        ],
      ),
    );
  }

  void _showDialogVerificarse(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [

            const IconUniversidadVerificada(size: 40,),
            const SizedBox(height: 8,),
            const Text("Verifica tu universidad",
              style: TextStyle(color: constants.blackGeneral, fontSize: 18, fontWeight: FontWeight.bold,),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16,),

            const Text("Ayúdanos a proteger la comunidad verificando que eres tú con el correo "
                "universitario. Esto agregará la insignia de Universidad Verificada en tu perfil y le dará más validez al perfil.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const VerificarUniversidadPage(),
                  ));

                  if(result == true){
                    _usuarioPerfil.isVerificadoUniversidad = true;
                    _usuarioPerfil.verificadoUniversidadNombre = _usuarioPerfil.universidad?.nombre;

                    _actualizarUsuarioPerfilSesion();

                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Continuar"),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),

          ], mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Por ahora no"),
          ),
        ],
      );
    });
  }

  Widget _buildBotonContacto(){
    switch(_usuarioPerfil.contactoEstado){
      case UsuarioPerfilContactoEstado.CONECTADOS:
        return TextButton.icon(
          onPressed: _enviandoBotonContacto ? null : () => _showDialogEliminarContacto(),
          icon: const Icon(Icons.people_alt_outlined, size: 18,),
          label: const Text("Son amigos",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal,),
          ),
          style: TextButton.styleFrom(
            primary: constants.blackGeneral,
            padding: EdgeInsets.all(0),
          ),
        );
        break;
      case UsuarioPerfilContactoEstado.NO_CONECTADOS:
        return TextButton.icon(
          onPressed: _enviandoBotonContacto ? null : () => _agregarContacto(),
          icon: const Icon(Icons.person_add, size: 18,),
          label: const Text("Agregar a amigos", style: TextStyle(fontSize: 12,)),
          style: TextButton.styleFrom(
            primary: constants.blackGeneral,
            padding: EdgeInsets.all(0),
          ),
        );
        break;
      case UsuarioPerfilContactoEstado.SOLICITUD_ENVIADO:
        return TextButton.icon(
          onPressed: _enviandoBotonContacto ? null : () => _showDialogCancelarSolicitudContacto(),
          icon: const Icon(Icons.people_alt_outlined, size: 18,),
          label: const Text("Solicitud de amigos enviada",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal,),
          ),
          style: TextButton.styleFrom(
            primary: constants.blackGeneral,
            padding: EdgeInsets.all(0),
          ),
        );
        break;
      case UsuarioPerfilContactoEstado.SOLICITUD_RECIBIDO:
        return TextButton.icon(
          onPressed: _enviandoBotonContacto ? null : () => _aceptarSolicitudContacto(),
          icon: const Icon(Icons.person_add, size: 18,),
          label: const Text("Aceptar solicitud de amigos", style: TextStyle(fontSize: 12,)),
          style: TextButton.styleFrom(
            primary: constants.blackGeneral,
            padding: EdgeInsets.all(0),
          ),
        );
        break;
      case UsuarioPerfilContactoEstado.BLOQUEO_ENVIADO:
        return Container();
        break;
      case UsuarioPerfilContactoEstado.BLOQUEO_RECIBIDO:
        return Container();
        break;
      default:
        return Container();
    }
  }

  Widget _buildSeccionBotones(){
    if(_usuarioPerfil.contactoEstado == null){
      return SliverToBoxAdapter(child: Container());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 24, right: 16, bottom: 24,),
        alignment: Alignment.bottomCenter,
        child: Row(children: [
          OutlinedButton.icon(
            onPressed: (){
              if(_usuarioPerfil.contactoEstado == UsuarioPerfilContactoEstado.CONECTADOS || widget.compartenGrupoChatId != null){
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ChatPage(chat: null, chatIndividualUsuario: _usuarioPerfil, compartenGrupoChatId: widget.compartenGrupoChatId,),
                ));
              } else {
                _showDialogMensajeBloqueado();
              }
            },
            icon: _usuarioPerfil.contactoEstado == UsuarioPerfilContactoEstado.CONECTADOS || widget.compartenGrupoChatId != null
                ? const Icon(Icons.near_me)
                : const Icon(Icons.lock_outline),
            label: const Text('Enviar mensaje', style: TextStyle(fontSize: 16),),
            style: OutlinedButton.styleFrom(
              primary: constants.blueGeneral,
              backgroundColor: Colors.white,
              side: const BorderSide(color: constants.blueGeneral, width: 0.5,),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16,),
            ),
            /*
            label: Text('Mensaje', style: TextStyle(fontSize: 18)),
            style: OutlinedButton.styleFrom(
              //primary: constants.blueGeneral,
              backgroundColor: Colors.white,
              shape: StadiumBorder(),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16,),
              //Restar a Width = (48{tres margenes de 16} / 2) + 4{margen agregado} = 28
              fixedSize: Size.fromWidth((MediaQuery.of(context).size.width * 0.50) - 28),
            ),
            */
          ),
          /*
          SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: (){
              _showDialogEnviarSticker();
            },
            icon: const Icon(CupertinoIcons.bitcoin),
            label: Text(Platform.isIOS ? 'Propina' : 'Sticker', style: TextStyle(fontSize: 18)),
            /*label: Text('Sticker-Propina',
              style: TextStyle(fontSize: 16, height: 1),
            ),*/
            style: OutlinedButton.styleFrom(
              primary: Colors.white,
              backgroundColor: constants.blueGeneral,
              shape: StadiumBorder(),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16,),
              //Restar a Width = (48(tres margenes de 16) / 2) + 4(margen agregado) = 28
              fixedSize: Size.fromWidth((MediaQuery.of(context).size.width * 0.50) - 28),
            ),
          ),
          */
        ], mainAxisAlignment: MainAxisAlignment.center,),
      ),
    );
  }

  void _showDialogMensajeBloqueado(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("Solo puedes enviar mensajes privados a usuarios agregados como amigos o que estén participando en una misma actividad.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
              textAlign: TextAlign.left,
            ),
          ], mainAxisSize: MainAxisSize.min,),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      );
    });
  }

  void _showDialogEliminarContacto(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('¿Quieres eliminar a esta persona de tus amigos?'),
          content: const Text('También serás eliminado de su lista de amigos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: (){
                _eliminarContacto();
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar', style: TextStyle(color: constants.redAviso),),
            ),
          ],
        );
      });
    });
  }

  void _showDialogCancelarSolicitudContacto(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('¿Quieres eliminar la solicitud de amigos?'),
          //content: const Text(''),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: (){
                _cancelarSolicitudContacto();
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar solicitud'),
            ),
          ],
        );
      });
    });
  }

  void _showDialogCambiarFoto(){
    showModalBottomSheet(context: context, builder: (context){
      return SafeArea(child: Container(
        color: Colors.white,
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Cambiar foto de perfil'),
            onTap: () {
              Navigator.of(context).pop();
              _galleryPhoto();
            },
          ),
        ],),
      ),);
    });
  }

  void _showDialogCambiarDescripcion(){
    _descripcionController.text = '';

    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(children: [
              SizedBox(width: double.maxFinite,),
              TextField(
                //autofocus: true,
                controller: _descripcionController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Por ej. ¿Qué estás estudiando?",
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(fontSize: 12,),
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ], mainAxisSize: MainAxisSize.min,),
          ),
          actions: [
            TextButton(
              onPressed: _enviandoDescripcion ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _enviandoDescripcion ? null : () => _cambiarDescripcion(setStateDialog),
              child: const Text('Agregar'),
            ),
          ],
        );
      });
    });
  }

  void _showDialogCambiarInstagram(){
    _instagramController.text = "";
    _instagramErrorText = null;

    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(children: [
              SizedBox(width: double.maxFinite,),
              TextField(
                //autofocus: true,
                controller: _instagramController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Ingresa tu usuario de instagram",
                  counterText: '',
                  border: OutlineInputBorder(),
                  errorText: _instagramErrorText,
                ),
                maxLength: 35,
                style: const TextStyle(fontSize: 12,),
              ),
            ], mainAxisSize: MainAxisSize.min,),
          ),
          actions: [
            TextButton(
              onPressed: _enviandoInstagram ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _enviandoInstagram ? null : () => _cambiarInstagram(setStateDialog),
              child: const Text('Agregar'),
            ),
          ],
        );
      });
    });
  }

  Future<void> _cargarUsuario(String? username) async {
    setState(() {
      _loadingPerfil = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => {_usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs)});

    Map<String, String> queryParams = {};
    if(username != null){
      // Ingreso desde routeUsername
      queryParams = {
        "username": username
      };
    } else {
      queryParams = {
        "usuario_id": _usuarioPerfil.id
      };
    }

    var response = await HttpService.httpGet(
      url: constants.urlUsuarioPerfil,
      queryParams: queryParams,
      usuarioSesion: _usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){
        var datosUsuario = datosJson['data']['usuario'];

        _usuarioPerfil = UsuarioPerfil(
          id: datosUsuario['id'],
          nombre: datosUsuario['nombre_completo'],
          username: datosUsuario['username'],
          foto: constants.urlBase + datosUsuario['foto_url'],
        );

        if(datosUsuario['universidad'] != null){
          _usuarioPerfil.universidad = UsuarioPerfilUniversidad(
            id: datosUsuario['universidad']['id'].toString(),
            nombre: datosUsuario['universidad']['nombre'],
          );
        }

        _usuarioPerfil.descripcion = datosUsuario['descripcion'];
        _usuarioPerfil.instagram = datosUsuario['instagram'];
        _usuarioPerfil.contactoEstado = UsuarioPerfil.getUsuarioPerfilContactoEstadoFromString(datosUsuario['contacto_estado']);

        _usuarioPerfil.isVerificadoUniversidad = datosUsuario['is_verificado_universidad'];
        _usuarioPerfil.verificadoUniversidadNombre = datosUsuario['verificado_universidad_nombre'];

        List<Usuario> contactosMutuos = [];
        datosJson['data']['contactos_mutuos_vista_previa'].forEach((usuario){
          contactosMutuos.add(Usuario(
            id: usuario['id'],
            nombre: usuario['nombre_completo'],
            username: usuario['username'],
            foto: constants.urlBase + usuario['foto_url'],
          ));
        });
        _usuarioPerfil.contactosMutuos = contactosMutuos;
        _usuarioPerfil.totalContactosMutuos = datosJson['data']['total_contactos_mutuos'];

        datosUsuario['stickers_recibidos'].forEach((sticker){
          _stickersRecibidos.add(Sticker(
            id: sticker['id'].toString(),
            cantidadSatoshis: 0,
            numeroDisponibles: sticker['cantidad_recibido'],
          ));
        });


        if(widget.isFromProfile){
          // Por si hubo un error en almacenar en sesion local al cambiar foto
          if(_usuarioSesion!.foto != _usuarioPerfil.foto){
            _usuarioSesion!.foto = _usuarioPerfil.foto;
          }

          // Actualiza el valor para los usuarios viejos que no tenian este valor
          _usuarioSesion!.isUsuarioSinFoto = datosUsuario['is_usuario_sin_foto'];

          prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(_usuarioSesion!));
        }


        // Cambia el Scaffold si ingreso desde routeUsername
        _isloadingRouteUsername = false;

      } else {

        if(datosJson['error_tipo'] == 'deshabilitado'){
          _showSnackBar("Usuario deshabilitado.");
        } else if(datosJson['error_tipo'] == 'usuario_inexistente'){
          _showSnackBar("El usuario no existe.");
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    if(!mounted) return;
    setState(() {
      _loadingPerfil = false;
    });
  }

  Future<void> _eliminarContacto() async {
    setState(() {
      _enviandoBotonContacto = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlEliminarContacto,
      body: {
        "usuario_id": _usuarioPerfil.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _usuarioPerfil.contactoEstado = UsuarioPerfilContactoEstado.NO_CONECTADOS;

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoBotonContacto = false;
    });
  }

  Future<void> _agregarContacto() async {
    setState(() {
      _enviandoBotonContacto = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlEnviarSolicitudContacto,
      body: {
        "usuario_id": _usuarioPerfil.id,
        "enviado_desde" : "usuario_perfil",
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _usuarioPerfil.contactoEstado = UsuarioPerfilContactoEstado.SOLICITUD_ENVIADO;

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoBotonContacto = false;
    });
  }

  Future<void> _cancelarSolicitudContacto() async {
    setState(() {
      _enviandoBotonContacto = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCancelarSolicitudContacto,
      body: {
        "usuario_id": _usuarioPerfil.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _usuarioPerfil.contactoEstado = UsuarioPerfilContactoEstado.NO_CONECTADOS;

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoBotonContacto = false;
    });
  }

  Future<void> _aceptarSolicitudContacto() async {
    setState(() {
      _enviandoBotonContacto = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlAceptarContacto,
      body: {
        "usuario_id": _usuarioPerfil.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _usuarioPerfil.contactoEstado = UsuarioPerfilContactoEstado.CONECTADOS;

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoBotonContacto = false;
    });
  }

  void _showDialogEnviarSticker(){
    showDialog(context: context, builder: (context) {
      return DialogEnviarSticker(isGroup: false, usuario: _usuarioPerfil);
    });
  }

  void _showDialogBloquearUsuario(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Deseas bloquear a este usuario?'),
          content: const Text('No podrá ver tu perfil ni enviarte mensajes.'),
          actions: [
            TextButton(
              onPressed: _enviandoBotonContacto ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _enviandoBotonContacto ? null : () => _bloquearUsuario(setStateDialog),
              child: const Text('Bloquear'),
            ),
          ],
        );
      });
    });
  }

  void _showDialogDesbloquearUsuario(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Deseas desbloquear este usuario?'),
          actions: [
            TextButton(
              onPressed: _enviandoBotonContacto ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _enviandoBotonContacto ? null : () => _desbloquearUsuario(setStateDialog),
              child: const Text('Desbloquear'),
            ),
          ],
        );
      });
    });
  }

  Future<void> _bloquearUsuario(setStateDialog) async {
    setStateDialog(() {
      _enviandoBotonContacto = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlBloquearUsuario,
      body: {
        "usuario_id": _usuarioPerfil.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) => const PrincipalPage()
        ), (route) => false);

      } else {
        Navigator.of(context).pop();

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoBotonContacto = false;
    });
  }

  Future<void> _desbloquearUsuario(setStateDialog) async {
    setStateDialog(() {
      _enviandoBotonContacto = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlDesbloquearUsuario,
      body: {
        "usuario_id": _usuarioPerfil.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) => const PrincipalPage()
        ), (route) => false);

      } else {
        Navigator.of(context).pop();

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoBotonContacto = false;
    });
  }

  Future<void> _cambiarDescripcion(setStateDialog) async {
    setStateDialog(() {
      _enviandoDescripcion = true;
    });

    _descripcionController.text = _descripcionController.text.trim();
    String descripcion = _descripcionController.text;
    if(descripcion == ''){
      setStateDialog(() {_enviandoDescripcion = false;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCambiarDescripcion,
      body: {
        "descripcion": descripcion
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _usuarioPerfil.descripcion = descripcion;
        setState(() {});

        usuarioSesion.descripcion = descripcion == "" ? null : descripcion;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoDescripcion = false;
    });

    Navigator.of(context).pop();
  }

  Future<void> _cambiarInstagram(setStateDialog) async {
    _instagramErrorText = null;

    setStateDialog(() {
      _enviandoInstagram = true;
    });

    String instagram = _instagramController.text.trim();
    if(instagram.length > 0 && instagram[0] == '@'){
      instagram = instagram.substring(1);
    }
    _instagramController.text = instagram;
    if(!_regExpInstagram.hasMatch(instagram)){
      _instagramErrorText = 'Usuario no válido';
      setStateDialog(() {_enviandoInstagram = false;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCambiarInstagram,
      body: {
        "instagram": instagram
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _usuarioPerfil.instagram = instagram;
        setState(() {});

        usuarioSesion.instagram = instagram == "" ? null : instagram;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoInstagram = false;
    });

    Navigator.of(context).pop();
  }


  Future<void> _galleryPhoto() async {
    XFile? image;

    try {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch(e) {
      if(e is PlatformException && e.code == 'photo_access_denied'){
        _showSnackBar("Los permisos están denegados. Permite el acceso a la galería desde Ajustes en la app.");
        return;
      } else {
        //
      }
    }

    if (image != null) {
      _enviandoFotoPerfil = true;
      setState(() {});

      _cropImage(image);
    }
  }

  Future<void> _cropImage(XFile image) async {

    int imageLength = await image.length();
    int limit = 3000000; // 3MB aprox

    File? fileCropped;

    if(imageLength > limit){
      fileCropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1,),
        cropStyle: CropStyle.circle,
        compressQuality: 50,
      );
    } else {
      fileCropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1,),
        cropStyle: CropStyle.circle,
      );
    }

    if(fileCropped == null){
      _enviandoFotoPerfil = false;
      setState(() {});
      return;
    }

    int fileCroppedLength = fileCropped.lengthSync();
    if(fileCroppedLength > limit){

      _showSnackBar("La imagen es muy pesada. Por favor elija otra.");
      _enviandoFotoPerfil = false;
      setState(() {});

    } else {
      _guardarFoto(fileCropped);
    }
  }

  Future<void> _guardarFoto(File imageFile) async {
    setState(() {
      _enviandoFotoPerfil = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpMultipart(
      url: constants.urlCambiarFotoPerfil,
      field: 'foto_perfil',
      file: imageFile,
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        String fotoUrl = constants.urlBase + datosJson['data']['foto_url_nuevo'];

        _usuarioPerfil.foto = fotoUrl;
        setState(() {});

        // Al cambiar la logica aqui, cambiar tambien en SignupPicturePage
        usuarioSesion.foto = fotoUrl;
        usuarioSesion.isUsuarioSinFoto = false;
        await prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoFotoPerfil = false;
    });
  }

  Future<void> _enviarHistorialUsuario(Map<String, dynamic> historialUsuario) async {
    //setState(() {});

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCrearHistorialUsuarioActivo,
      body: {
        "historiales_usuario_activo": [historialUsuario],
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){
        //
      } else {
        //_showSnackBar("Se produjo un error inesperado");
      }
    }

    //setState(() {});
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}