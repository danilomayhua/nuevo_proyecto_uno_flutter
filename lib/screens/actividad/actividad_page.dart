import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/chat_solicitudes/chat_solicitudes_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/intereses.dart';
import 'package:tenfo/utilities/share_utils.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:tenfo/widgets/actividad_boton_entrar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/widgets/actividad_boton_like.dart';

class ActividadPage extends StatefulWidget {
  ActividadPage({Key? key, required this.actividad, this.reload = true,
    this.creadoresPendientes = const [], this.creadoresPendientesExternosCodigo = const [],
    this.onChangeIngreso, this.fromDisponibilidad,
    this.invitacionCodigo, this.routeInvitacionCreador, this.routeActividadId}) : super(key: key);

  Actividad? actividad;
  final bool reload;
  final List<Usuario> creadoresPendientes;
  final List<String> creadoresPendientesExternosCodigo;
  final void Function(Actividad)? onChangeIngreso;
  final Disponibilidad? fromDisponibilidad;
  final String? invitacionCodigo;
  final String? routeInvitacionCreador;
  final String? routeActividadId;

  @override
  State<ActividadPage> createState() => _ActividadPageState();
}

enum _PopupMenuOption { eliminarActividad, reportarActividad }

class _ActividadPageState extends State<ActividadPage> {

  UsuarioSesion? _usuarioSesion = null;

  bool _loadingActividad = false;
  bool _enviandoEliminarActividad = false;
  bool _enviandoReportarActividad = false;
  bool _enviandoConfirmarCocreador = false;

  bool _noMostrarActividad = false;

  bool _isCreadorPendiente = false;
  List<Usuario> _creadoresPendientes = [];
  List<String> _creadoresPendientesExternosCodigo = [];

  bool _enviandoInvitarDisponibilidad = false;

  String? _invitacionCodigo;
  bool _enviandoGenerarInvitacionCreador = false;

  bool _isFromInvitacionCreador = false;

  @override
  void initState() {
    super.initState();

    _creadoresPendientes = widget.creadoresPendientes;
    _creadoresPendientesExternosCodigo = widget.creadoresPendientesExternosCodigo;
    _invitacionCodigo = widget.invitacionCodigo;


    if(widget.actividad == null){
      // Si widget.actividad es nulo, tiene que enviar widget.routeInvitacionCreador o widget.routeActividadId
      _loadingActividad = true;
      if(widget.routeInvitacionCreador != null) _isFromInvitacionCreador = true;

      // Verifica sesion siempre que viene desde un route (deep linking)
      _verificarSesion();

      // Despues de verificar sesion, ejecutar lo de abajo

      return;
    }


    if(widget.reload){
      _cargarActividad(null, null);
    } else {

      // Cuando viene de CrearActividad siempre es reload = false
      if(widget.fromDisponibilidad != null) _showInvitarDisponibilidad(widget.fromDisponibilidad!);

    }

    SharedPreferences.getInstance().then((prefs){
      _usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);
      setState(() {});
    });
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


    String? invitacionCreador;
    String? actividadId;
    if(widget.routeInvitacionCreador != null){
      invitacionCreador = widget.routeInvitacionCreador;
      actividadId = null;
    } else {
      invitacionCreador = null;
      actividadId = widget.routeActividadId;
    }
    _cargarActividad(invitacionCreador, actividadId);

    SharedPreferences.getInstance().then((prefs){
      _usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Actividad"),
        actions: (!_loadingActividad && !_noMostrarActividad) ? [
          /*IconButton(
            icon: Icon(CupertinoIcons.arrowshape_turn_up_right),
            onPressed: (){
              _compartirActividad();
            },
          ),*/
          if(widget.actividad!.getIsCreador(_usuarioSesion != null ? _usuarioSesion!.id : "" ) && widget.actividad!.privacidadTipo == ActividadPrivacidadTipo.PRIVADO)
            IconButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ChatSolicitudesPage(actividad: widget.actividad!),
                ));
              },
              icon: const Icon(Icons.group_add_outlined),
            ),
          if(widget.actividad!.isAutor)
            PopupMenuButton<_PopupMenuOption>(
              onSelected: (_PopupMenuOption result) {
                if(result == _PopupMenuOption.eliminarActividad) {
                  _showDialogEliminarActividad();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<_PopupMenuOption>>[
                const PopupMenuItem<_PopupMenuOption>(
                  value: _PopupMenuOption.eliminarActividad,
                  child: Text('Eliminar actividad'),
                ),
              ],
            ),
          if(!widget.actividad!.isAutor)
            PopupMenuButton<_PopupMenuOption>(
              onSelected: (_PopupMenuOption result) {
                if(result == _PopupMenuOption.reportarActividad) {
                  _showDialogReportarActividad();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<_PopupMenuOption>>[
                const PopupMenuItem<_PopupMenuOption>(
                  value: _PopupMenuOption.reportarActividad,
                  child: Text('Reportar'),
                ),
              ],
            ),
        ] : [],
      ),
      body: _loadingActividad ? const Center(

        child: CircularProgressIndicator(),

      ) : _noMostrarActividad ? Container() : SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 16,),

          Row(children: [
            const SizedBox(width: 16,),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: constants.grey, width: 0.5,),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(children: [
                Text(Intereses.getNombre(widget.actividad!.interes),
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
                ),
                const SizedBox(width: 2,),
                Intereses.getIcon(widget.actividad!.interes, size: 16,),
              ], mainAxisSize: MainAxisSize.min,),
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: constants.grey, fontSize: 14,),
                text: widget.actividad!.getPrivacidadTipoString(),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        onPressed: (){
                          _showDialogAyudaTiposActividad();
                        },
                        icon: Icon(Icons.help_outline, color: constants.grey, size: 18,),
                        padding: EdgeInsets.all(0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(" • " + widget.actividad!.fecha,
              style: TextStyle(color: constants.greyLight, fontSize: 14,),
            ),
            const SizedBox(width: 16,),
          ],),

          const SizedBox(height: 24,),

          Container(
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16,),
            child: Text(widget.actividad!.titulo,
              style: const TextStyle(color: constants.blackGeneral, fontSize: 18,
                height: 1.3, fontWeight: FontWeight.w500,),
            ),
          ),
          /*
          Container(
            constraints: BoxConstraints(minHeight: 64),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16,),
            child: Text(widget.actividad.descripcion ?? "",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16, height: 1.4,),
            ),
          ),
          */
          const SizedBox(height: 24,),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16,),
            child: Row(children: [
              ActividadBotonLike(
                actividad: widget.actividad!,
                onChange: (){
                  setState(() {});

                  if(widget.onChangeIngreso != null) widget.onChangeIngreso!(widget.actividad!);
                },
              ),
              Text(widget.actividad!.likesCount > 0 ? "${widget.actividad!.likesCount}" : "",
                style: const TextStyle(color: constants.blackGeneral, fontSize: 14,),
              ),

              const Spacer(),

              ActividadBotonEntrar(
                actividad: widget.actividad!,
                onChangeIngreso: (){
                  if(widget.onChangeIngreso != null) widget.onChangeIngreso!(widget.actividad!);
                },
              ),
            ],),
          ),

          const SizedBox(height: 16,),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Cocreadores:", style: TextStyle(color: constants.blackGeneral),),
          ),
          ListView.builder(
            itemCount: widget.actividad!.creadores.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => ListTile(
              dense: true,
              title: Text(widget.actividad!.creadores[index].nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(widget.actividad!.creadores[index].username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: CircleAvatar(
                backgroundColor: constants.greyBackgroundImage,
                backgroundImage: CachedNetworkImageProvider(widget.actividad!.creadores[index].foto),
              ),
              onTap: (){
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserPage(usuario: widget.actividad!.creadores[index],)),
                );
              },
            ),
          ),

          const SizedBox(height: 16,),

          if(widget.actividad!.isAutor && (_creadoresPendientes.isNotEmpty || _creadoresPendientesExternosCodigo.isNotEmpty))
            Column(children: [
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 0,),
                child: Text("Cocreadores pendientes:", style: TextStyle(color: constants.blackGeneral),),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 12,),
                child: Text("Estos usuarios tienen que confirmar para ser parte de cocreadores. "
                    "Solo tú puedes ver esta lista.",
                  style: TextStyle(color: constants.grey, fontSize: 12,),
                  //textAlign: TextAlign.center,
                ),
              ),
              if(_creadoresPendientes.isNotEmpty)
                ListView.builder(
                  itemCount: _creadoresPendientes.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    title: Text(_creadoresPendientes[index].nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_creadoresPendientes[index].username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: constants.greyBackgroundImage,
                      backgroundImage: CachedNetworkImageProvider(_creadoresPendientes[index].foto),
                    ),
                    onTap: (){
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context) => UserPage(usuario: _creadoresPendientes[index],)),
                      );
                    },
                  ),
                ),
              if(_creadoresPendientesExternosCodigo.isNotEmpty)
                ListView.builder(
                  itemCount: _creadoresPendientesExternosCodigo.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    title: const Text("Invitado externo",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    subtitle: Text("Código: " + (_creadoresPendientesExternosCodigo[index].split('').join(' ')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: constants.greyBackgroundImage,
                      child: Icon(Icons.group, color: constants.blackGeneral,),
                    ),
                    onTap: (){
                      ShareUtils.shareActivityCocreatorCode(
                        _creadoresPendientesExternosCodigo[index],
                        widget.actividad!.titulo,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16,),
            ], crossAxisAlignment: CrossAxisAlignment.start,),


          if(!widget.actividad!.isAutor && !_isCreadorPendiente && !_isFromInvitacionCreador)
            Align(
              alignment: Alignment.center,
              child: widget.actividad!.ingresoEstado == ActividadIngresoEstado.INTEGRANTE
                  ? Container(
                    margin: const EdgeInsets.symmetric(vertical: 16,),
                    constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                    child: TextButton.icon(
                      onPressed: (){
                        ShareUtils.shareActivity(widget.actividad!.id);

                        // Envia historial del usuario
                        _enviarHistorialUsuario(HistorialUsuario.getActividadInvitarAmigo(widget.actividad!.id, isIntegrante: true,));
                      },
                      icon: const Icon(Icons.person_add_alt_outlined,),
                      label: const Text("Invitar amigo"),
                      style: TextButton.styleFrom(
                        shape: const StadiumBorder(),
                      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                    ),
                  )
                  : Column(children: [
                    const SizedBox(height: 48,),
                    const Text("Únete con tu grupo de amigos:", style: TextStyle(color: constants.blackGeneral, fontSize: 12,),),
                    const SizedBox(height: 8,),
                    Container(
                      constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                      child: ElevatedButton.icon(
                        onPressed: (){
                          ShareUtils.shareActivity(widget.actividad!.id);

                          // Envia historial del usuario
                          _enviarHistorialUsuario(HistorialUsuario.getActividadInvitarAmigo(widget.actividad!.id, isIntegrante: false,));
                        },
                        icon: const Icon(Icons.north, size: 20,),
                        label: const Text("Compartir enlace de actividad"),
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                        ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                      ),
                    ),
                    const SizedBox(height: 48,),
                  ]),
            ),

          if(widget.actividad!.isAutor)
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 24,),
                constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                child: ElevatedButton.icon(
                  onPressed: _enviandoGenerarInvitacionCreador ? null : () => _compartirInvitacionCreador(),
                  icon: const Icon(Icons.add_rounded, size: 18,),
                  label: const Text("Agregar cocreadores"),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),
              ),
            ),

          if(_isFromInvitacionCreador && !widget.actividad!.getIsCreador(_usuarioSesion?.id ?? "" ) && !_isCreadorPendiente)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: constants.grey),
                color: Colors.white,
              ),
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16,),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(children: [
                const Text("Fuiste invitado como cocreador de la actividad. "
                    "Tienes que confirmar para ser parte y tener los permisos de admin.",
                  style: TextStyle(color: constants.grey, fontSize: 12,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16,),
                OutlinedButton(
                  onPressed: _enviandoConfirmarCocreador ? null : () => _confirmarCocreadorInvitacion(),
                  child: const Text("Confirmar", style: TextStyle(fontWeight: FontWeight.normal,),),
                  style: OutlinedButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: constants.blueGeneral,
                    //onSurface: constants.grey,
                    side: const BorderSide(color: Colors.transparent, width: 0.5,),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],),
            ),

          if(_isCreadorPendiente)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: constants.grey),
                color: Colors.white,
              ),
              margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16,),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(children: [
                const Text("Fuiste agregado como cocreador de la actividad. "
                    "Tienes que confirmar para ser parte y tener los permisos de admin.",
                  style: TextStyle(color: constants.grey, fontSize: 12,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16,),
                OutlinedButton(
                  onPressed: _enviandoConfirmarCocreador ? null : () => _confirmarCocreador(),
                  child: const Text("Confirmar", style: TextStyle(fontWeight: FontWeight.normal,),),
                  style: OutlinedButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: constants.blueGeneral,
                    //onSurface: constants.grey,
                    side: const BorderSide(color: Colors.transparent, width: 0.5,),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],),
            ),

          /*
          if(!widget.actividad.isAutor)
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 32,),
                constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                child: OutlinedButton.icon(
                  onPressed: (){
                    ShareUtils.shareActivity(widget.actividad.titulo);

                    // Envia historial del usuario
                    _enviarHistorialUsuario(HistorialUsuario.getActividadInvitarAmigo(widget.actividad.id));
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text("Enviar a facuamigos",
                    style: TextStyle(fontSize: 14,),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),
              ),
            ),
         */

        ], crossAxisAlignment: CrossAxisAlignment.start),
      ),
      backgroundColor: Colors.white,
    );
  }

  void _compartirActividad(){
    Share.share("Unete a mi actividad en _url");
  }

  void _showDialogEliminarActividad(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Eliminar actividad?', style: TextStyle(fontSize: 16),),
          // TODO : cambiar texto (si es una actividad archivada, este texto no tiene sentido)
          content: const Text('Al eliminar esta actividad, perderás la capacidad de ver las nuevas actividades que '
              'otros usuarios creen en el día. ¿Estás seguro de que deseas continuar?',
            style: TextStyle(fontSize: 14,),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: _enviandoEliminarActividad ? null : () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Eliminar'),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
              onPressed: _enviandoEliminarActividad ? null : () => _eliminarActividad(setStateDialog),
            ),
          ],
        );
      });
    });
  }

  void _showDialogReportarActividad(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Quieres reportar esta actividad?'),
          content: const Text('Revisaremos esta actividad y tomaremos medidas si infringe nuestros términos y condiciones. Tus informes son confidenciales y solo serán compartidos con nuestro equipo de moderación.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: _enviandoReportarActividad ? null : () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Reportar'),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
              onPressed: _enviandoReportarActividad ? null : () => _reportarActividad(setStateDialog),
            ),
          ],
        );
      });
    });
  }

  void _showDialogAyudaTiposActividad(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            const Text("Hay 2 tipos de privacidad en las actividades:",
              style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24,),

            Row(children: const [
              SizedBox(
                width: 80,
                child: Text("Público:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 12,),
              Expanded(child: Text("Los usuarios que se unan a la actividad entraran automáticamente al chat grupal.",
                style: TextStyle(fontSize: 14, color: constants.grey),
              ),),
            ], crossAxisAlignment: CrossAxisAlignment.start,),
            const SizedBox(height: 24,),
            Row(children: const [
              SizedBox(
                width: 80,
                child: Text("Privado:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 8,),
              Expanded(child: Text("Los usuarios que se unan a la actividad enviarán una solicitud, y alguno de los cocreadores debe aceptar para que entren al chat grupal.",
                style: TextStyle(fontSize: 14, color: constants.grey),
              ),),
            ], crossAxisAlignment: CrossAxisAlignment.start,),
            /*const SizedBox(height: 24,),
            Row(children: const [
              SizedBox(
                width: 80,
                child: Text("Requisitos:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 8,),
              Expanded(child: Text("Al unirse, hay que contestar un cuestionario. Si las respuestas son correctas, entras automáticamente al chat grupal.",
                style: TextStyle(fontSize: 14, color: constants.grey),
              ),),
            ], crossAxisAlignment: CrossAxisAlignment.start,),*/

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

  Future<void> _cargarActividad(String? invitacionCreador, String? actividadId) async {
    setState(() {
      _loadingActividad = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    Map<String, String> queryParams = {};
    if(invitacionCreador != null){
      // Ingreso desde routeInvitacionCreador
      queryParams = {
        "invitacion_codigo": invitacionCreador
      };
    } else if(actividadId != null){
      // Ingreso desde routeActividadId
      queryParams = {
        "actividad_id": actividadId
      };
    } else {
      queryParams = {
        "actividad_id": widget.actividad!.id
      };
    }

    var response = await HttpService.httpGet(
      url: constants.urlVerActividad,
      queryParams: queryParams,
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){
        var datosActividad = datosJson['data']['actividad'];

        _noMostrarActividad = false;

        _creadoresPendientes = [];
        _creadoresPendientesExternosCodigo = [];

        List<Usuario> creadores = [];
        datosActividad['creadores'].forEach((usuario) {

          if(usuario['creador_estado'] != null && usuario['creador_estado'] == 'CREADOR_PENDIENTE'){
            _creadoresPendientes.add(Usuario(
              id: usuario['id'],
              nombre: usuario['nombre_completo'],
              username: usuario['username'],
              foto: constants.urlBase + usuario['foto_url'],
            ));
          } else {
            creadores.add(Usuario(
              id: usuario['id'],
              nombre: usuario['nombre_completo'],
              username: usuario['username'],
              foto: constants.urlBase + usuario['foto_url'],
            ));
          }

        });

        if(datosActividad['creadores_externos_codigo'] != null){
          datosActividad['creadores_externos_codigo'].forEach((codigo) {
            _creadoresPendientesExternosCodigo.add(codigo);
          });
        }

        Actividad actividad = Actividad(
          id: datosActividad['id'],
          titulo: datosActividad['titulo'],
          descripcion: datosActividad['descripcion'],
          fecha: datosActividad['fecha_texto'],
          privacidadTipo: Actividad.getActividadPrivacidadTipoFromString(datosActividad['privacidad_tipo']),
          interes: datosActividad['interes_id'].toString(),
          isLiked: datosActividad['like'] == "SI",
          likesCount: datosActividad['likes_count'],
          creadores: creadores,
          ingresoEstado: Actividad.getActividadIngresoEstadoFromString(datosActividad['ingreso_estado']),
          isAutor: datosActividad['autor_usuario_id'] == usuarioSesion.id,
        );

        if(datosActividad['chat'] != null){
          Chat chat = Chat(
            id: datosActividad['chat']['id'].toString(),
            tipo: ChatTipo.GRUPAL,
            numMensajesPendientes: null,
            actividadChat: actividad,
          );
          actividad.chat = chat;
        }

        widget.actividad = actividad;

        _isCreadorPendiente = datosJson['data']['is_creador_pendiente'];

        _invitacionCodigo = datosJson['data']['invitacion_codigo'];

        if(widget.onChangeIngreso != null) widget.onChangeIngreso!(widget.actividad!);

      } else {

        _noMostrarActividad = true;

        if(datosJson['error_tipo'] == 'eliminado'){
          _showSnackBar("La actividad fue eliminada.");
        } else if(datosJson['error_tipo'] == 'no_disponible'){
          _showSnackBar("Actividad no disponible.");
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _loadingActividad = false;
    });
  }

  Future<void> _eliminarActividad(setStateDialog) async {
    setStateDialog(() {
      _enviandoEliminarActividad = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlEliminarActividad,
      body: {
        "actividad_id": widget.actividad!.id
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
        Navigator.pop(context);

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoEliminarActividad = false;
    });
  }

  Future<void> _reportarActividad(setStateDialog) async {
    setStateDialog(() {
      _enviandoReportarActividad = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlReportarActividad,
      body: {
        "actividad_id": widget.actividad!.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pop(context);

        _showSnackBar("Tu reporte ha sido recibido y será revisado por nuestro equipo de moderación. Gracias por ayudarnos a mantener una comunidad segura y respetuosa para todos.");

      } else {
        Navigator.pop(context);

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoReportarActividad = false;
    });
  }

  Future<void> _confirmarCocreador() async {
    setState(() {
      _enviandoConfirmarCocreador = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadConfirmarCocreador,
      body: {
        "actividad_id": widget.actividad!.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _cargarActividad(null, null);

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoConfirmarCocreador = false;
    });
  }

  void _compartirInvitacionCreador(){
    /*if(_creadores.length >= 3){
      _showSnackBar("Solo se pueden añadir tres(3) cocreadores");
      return;
    }*/

    _enviandoGenerarInvitacionCreador = true;

    if(_invitacionCodigo != null){

      ShareUtils.shareActivityCocreator(_invitacionCodigo!);

      // Envia historial del usuario
      _enviarHistorialUsuario(HistorialUsuario.getActividadCocreadoresInvitarAmigo(widget.actividad!.id));

      _enviandoGenerarInvitacionCreador = false;
      setState(() {});

    } else {
      _generarInvitacionCreador();
    }
  }

  Future<void> _generarInvitacionCreador() async {
    setState(() {
      _enviandoGenerarInvitacionCreador = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadCrearInvitacionCreadorActividadCreada,
      body: {
        "actividad_id": widget.actividad!.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _invitacionCodigo = datosJson['data']['invitacion_codigo'];

        ShareUtils.shareActivityCocreator(_invitacionCodigo!);

        // Envia historial del usuario
        _enviarHistorialUsuario(HistorialUsuario.getActividadCocreadoresInvitarAmigo(widget.actividad!.id));

      } else {

        if(datosJson['error_tipo'] == 'limite_codigos'){
          _showSnackBar("Ya has generado el máximo de códigos permitidos para hoy.");
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoGenerarInvitacionCreador = false;
    });
  }

  Future<void> _confirmarCocreadorInvitacion() async {
    setState(() {
      _enviandoConfirmarCocreador = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadConfirmarCocreadorInvitacion,
      body: {
        "invitacion_codigo": widget.routeInvitacionCreador
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _cargarActividad(null, null);

      } else {

        if(datosJson['error_tipo'] == 'limite_creadores'){
          _showSnackBar("Esta actividad alcanzó el límite de cocreadores.");
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoConfirmarCocreador = false;
    });
  }

  Future<void> _showInvitarDisponibilidad(Disponibilidad disponibilidad) async {
    await Future.delayed(const Duration(seconds: 1)); // Espera un momento para que vea su actividad creada
    _showDialogInvitarDisponibilidad(disponibilidad);
  }

  void _showDialogInvitarDisponibilidad(Disponibilidad disponibilidad){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(children: [

              Text("¿Quieres invitar a ${disponibilidad.creador.nombre} a esta actividad?",
                style: const TextStyle(color: constants.blackGeneral, fontSize: 16, fontWeight: FontWeight.bold,),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24,),

              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: constants.greyBackgroundImage,
                    backgroundImage: CachedNetworkImageProvider(disponibilidad.creador.foto),
                    radius: 16,
                  ),
                  const SizedBox(width: 12,),
                  Text(disponibilidad.creador.nombre, style: const TextStyle(fontSize: 16),),
                ],
                mainAxisSize: MainAxisSize.min,
              ),

            ], mainAxisSize: MainAxisSize.min,),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: _enviandoInvitarDisponibilidad ? null : () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Invitar'),
              onPressed: _enviandoInvitarDisponibilidad ? null : () => _invitarDisponibilidad(disponibilidad, setStateDialog),
            ),
          ],
        );
      });
    });
  }

  Future<void> _invitarDisponibilidad(Disponibilidad disponibilidad, setStateDialog) async {
    setStateDialog(() {
      _enviandoInvitarDisponibilidad = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadInvitacionInvitar,
      body: {
        "actividad_id": widget.actividad!.id,
        "usuario_id": disponibilidad.creador.id,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pop(context);
        _showSnackBar("¡Invitación enviada!");

      } else {

        Navigator.pop(context);
        _showSnackBar("Se produjo un error inesperado");

      }
    }

    setStateDialog(() {
      _enviandoInvitarDisponibilidad = false;
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