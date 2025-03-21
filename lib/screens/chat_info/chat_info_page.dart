import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_chat_integrante.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/actividad/actividad_page.dart';
import 'package:tenfo/screens/chat_solicitudes/chat_solicitudes_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/share_utils.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:tenfo/widgets/dialog_enviar_sticker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatInfoPage extends StatefulWidget {
  const ChatInfoPage({Key? key, required this.chat}) : super(key: key);

  final Chat chat;

  @override
  State<ChatInfoPage> createState() => _ChatInfoPageState();
}

enum _PopupMenuOption { salirGrupo }

class _ChatInfoPageState extends State<ChatInfoPage> {

  bool _loadingChatInfo = false;

  bool _isIntegrante = true;

  Actividad? _actividad;
  List<UsuarioChatIntegrante> _integrantes = [];
  bool _isGrupoLleno = false;
  bool _isCreador = false;

  String _encuentroFechaString = "";
  DateTime _dateSelected = DateTime.now();
  TimeOfDay _timeSelected = TimeOfDay.now();
  bool _enviandoEncuentroFecha = false;

  String? _encuentroLink;
  final TextEditingController _encuentroLinkController = TextEditingController();
  String? _encuentroLinkErrorText;
  final RegExp _regExUrl = RegExp(r'(?:https?://)?(?:www\.)?[a-zA-Z0-9@:%._+~#=]+\.[a-z]{2,6}\b(?:\.?[-a-zA-Z0-9@:%_+~#=?&/])*');
  bool _enviandoEncuentroLink = false;

  bool _enviandoSalirGrupo = false;

  bool _enviandoEliminarIntegrante = false;

  bool _isAvailableTooltipGrupoFecha = false;

  UsuarioSesion? _usuarioSesion;

  @override
  void initState() {
    super.initState();

    _cargarIntegrantes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Info. del grupo"),
        actions: [
          if(_isCreador && _actividad != null && _actividad!.privacidadTipo == ActividadPrivacidadTipo.PRIVADO)
            IconButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ChatSolicitudesPage(actividad: _actividad!),
                ));
              },
              icon: const Icon(Icons.group_add_outlined),
            ),

          if(_actividad != null)
            PopupMenuButton<_PopupMenuOption>(
              onSelected: (_PopupMenuOption result) {
                if(result == _PopupMenuOption.salirGrupo){
                  _showDialogSalirGrupo();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<_PopupMenuOption>>[
                PopupMenuItem<_PopupMenuOption>(
                  value: _PopupMenuOption.salirGrupo,
                  child: Text(_actividad!.isAutor
                      ? 'Salir y eliminar actividad'
                      : 'Salir del grupo'
                  ),
                ),
              ],
            ),
        ],
      ),
      body:  _loadingChatInfo ? const Center(

        child: CircularProgressIndicator(),

      ) : !_isIntegrante ? Container() : SingleChildScrollView(
        child: Column(children: [
          if(_actividad != null)
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ActividadPage(actividad: _actividad!)
                ));
              },
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 96),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: constants.grey),
                  color: Colors.white,
                ),
                margin: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 24,),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16,),
                child: Column(children: [
                  Text(_actividad!.titulo,
                    style: const TextStyle(color: constants.blackGeneral, fontSize: 18, height: 1.3,),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  /*
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(_actividad!.descripcion ?? "",
                      style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.4,),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  */
                ], crossAxisAlignment: CrossAxisAlignment.start),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Hora de encuentro:", style: TextStyle(color: constants.blackGeneral),),
          ),
          const SizedBox(height: 8,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: InputDecorator(
                isEmpty: _encuentroFechaString == "" ? true : false,
                decoration: InputDecoration(
                  enabled: false,
                  isDense: true,
                  hintText: _isCreador
                      ? "Ingresa una hora"
                      : "Indefinido", //"DD/MM/AAAA hh:mm",
                  hintStyle: TextStyle(fontSize: 12,),
                  //counterText: '',
                  border: OutlineInputBorder(),
                ),
                child: Text(_encuentroFechaString,
                  style: const TextStyle(fontSize: 12,),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),),

              if(_isCreador)
                Stack(children: [
                  IconButton(
                    onPressed: _enviandoEncuentroFecha ? null : () => _showDialogEditarFecha(),
                    icon: _enviandoEncuentroFecha ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ) : const Icon(Icons.edit_outlined,
                      size: 24,
                      color: constants.blackGeneral,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(maxWidth: 40,),
                  ),
                  if(_encuentroFechaString == "" && _isAvailableTooltipGrupoFecha)
                    Positioned(
                      child: Container(
                        decoration: ShapeDecoration(
                          shape: _CustomShapeBorder(),
                          color: Colors.grey[700]?.withOpacity(0.9),
                        ),
                        constraints: const BoxConstraints(maxWidth: 200,),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8,),
                        child: const Text("¡Elige una hora para hacer que el encuentro sea más fácil!",
                          style: TextStyle(color: Colors.white,),
                        ),
                      ),
                      bottom: 56,
                      right: 0,
                    ),
                ], clipBehavior: Clip.none,),
            ],),
          ),

          const SizedBox(height: 16,),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Link de ubicación:", style: TextStyle(color: constants.blackGeneral),),
          ),
          const SizedBox(height: 8,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: InputDecorator(
                isEmpty: (_encuentroLink ?? "") == "" ? true : false,
                decoration: InputDecoration(
                  enabled: false,
                  isDense: true,
                  hintText: _isCreador
                      ? "Ingresa un link de Maps..."
                      : "Indefinido",
                  hintStyle: TextStyle(fontSize: 12,),
                  //counterText: '',
                  border: OutlineInputBorder(),
                ),
                child: Text.rich(
                  TextSpan(children: _linkify(_encuentroLink ?? "")),
                  style: const TextStyle(fontSize: 12,),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),),

              if(_isCreador || (_encuentroLink ?? "") != "")
                IconButton(
                  onPressed: (){
                    if(_isCreador){
                      _showDialogEditarLink();
                    } else {
                      Clipboard.setData(ClipboardData(text: _encuentroLink ?? ""))
                          .then((value) => _showSnackBar("Enlace copiado"));
                    }
                  },
                  icon: Icon(_isCreador ? Icons.edit_outlined : Icons.content_copy_outlined,
                    size: 24,
                    color: constants.blackGeneral,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(maxWidth: 40,),
                ),
            ],),
          ),

          /*const SizedBox(height: 24,),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton.icon(
              onPressed: (){
                _showDialogEnviarSticker();
              },
              icon: const Icon(CupertinoIcons.bitcoin),
              //label: Text('Enviar propina', style: TextStyle(fontSize: 16)),
              label: Text(Platform.isIOS ? 'Enviar propina' : 'Enviar sticker', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                primary: Colors.white,
                backgroundColor: constants.blueGeneral,
                side: const BorderSide(color: Colors.transparent, width: 0.5,),
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16,),
              ),
            ),
          ),
          if(!Platform.isIOS)
            ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: InkWell(
                  child: const Text("¿Cómo funciona?",
                    style: TextStyle(color: constants.grey, fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: (){
                    _showDialogAyudaSticker();
                  },
                ),
              ),
            ],*/

          const SizedBox(height: 24,),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Integrantes:", style: TextStyle(color: constants.blackGeneral),),
          ),
          if(_isGrupoLleno)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 0),
              child: Text("El chat grupal alcanzó el límite de ${_integrantes.length} integrantes",
                style: const TextStyle(color: constants.grey, fontSize: 12,),
              ),
            ),
          const SizedBox(height: 8,),
          ListView.builder(
            itemCount: _integrantes.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => _buildIntegrante(_integrantes[index]),
          ),

          if(_actividad != null)
            ...[
              const SizedBox(height: 32,),

              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16,),
                child: Text(_actividad!.isAutor
                    ? 'Puedes invitar a personas que no están en Tenfo:'
                    : 'Invita amigos para que participen en la actividad contigo:',
                  style: const TextStyle(color: constants.grey, fontSize: 12,),
                ),
              ),

              const SizedBox(height: 16,),

              Container(
                alignment: Alignment.center,
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  children: [

                    Column(children: [
                      InkWell(
                        onTap: () => _compartirWhatsapp(),
                        child: Container(
                          //width: 56,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25d366),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 24,
                                width: 24,
                                child: Image.asset("assets/whatsapp_icon_circulo.png"),
                              ),
                              const SizedBox(width: 4,),
                              const Text("Enviar a WhatsApp", style: TextStyle(fontSize: 12, color: Colors.white,),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            //mainAxisAlignment: MainAxisAlignment.center,
                          ),
                        ),
                      ),
                    ], mainAxisAlignment: MainAxisAlignment.start,),

                    InkWell(
                      onTap: () => _copiarLink(),
                      child: Container(
                        width: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyan,
                              ),
                              child: const Icon(CupertinoIcons.link, size: 18, color: Colors.white,),
                            ),
                            const SizedBox(height: 10,),
                            const Text("Copiar enlace", style: TextStyle(fontSize: 10), textAlign: TextAlign.center,)
                          ],
                          //mainAxisAlignment: MainAxisAlignment.center,
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: () => _compartirGeneral(),
                      child: Container(
                        width: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: constants.grey),
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(CupertinoIcons.share, size: 18,),
                            ),
                            const SizedBox(height: 10,),
                            const Text("Compartir", style: TextStyle(fontSize: 10), textAlign: TextAlign.center,)
                          ],
                          //mainAxisAlignment: MainAxisAlignment.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

          const SizedBox(height: 16,),
        ], crossAxisAlignment: CrossAxisAlignment.start),
      ),
    );
  }

  void _compartirWhatsapp(){
    ShareUtils.shareActivityWhatsapp(_actividad!.id);

    // Envia historial del usuario
    _enviarHistorialUsuario(HistorialUsuario.getChatActividadEnviarWhatsapp(_actividad!.id, isAutor: _actividad!.isAutor,));
  }

  void _copiarLink(){
    ShareUtils.copyLinkActivity(_actividad!.id)
        .then((value) => _showSnackBar("Enlace copiado"));

    // Envia historial del usuario
    _enviarHistorialUsuario(HistorialUsuario.getChatActividadEnviarCopiar(_actividad!.id, isAutor: _actividad!.isAutor,));
  }

  void _compartirGeneral(){
    ShareUtils.shareActivity(_actividad!.id);

    // Envia historial del usuario
    _enviarHistorialUsuario(HistorialUsuario.getChatActividadEnviarCompartir(_actividad!.id, isAutor: _actividad!.isAutor,));
  }


  Widget _buildIntegrante(UsuarioChatIntegrante integrante){
    return ListTile(
      title: Text(integrante.usuario.nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(integrante.usuario.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: CachedNetworkImageProvider(integrante.usuario.foto),
      ),
      trailing: (integrante.rol == UsuarioChatIntegranteRol.ADMINISTRADOR) ? Container(
        child: const Text("Creador",
          style: TextStyle(color: constants.grey, fontSize: 12,),
        ),
        decoration: const ShapeDecoration(
          shape: StadiumBorder(
            side: BorderSide(color: constants.grey),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4,),
      ) : null,
      onTap: (){
        if(_isCreador){
          _showDialogOpcionesIntegrante(integrante);
        } else {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => UserPage(usuario: integrante.usuario, compartenGrupoChatId: widget.chat.id,),
          ));
        }
      },
    );
  }

  String _encuentroFechaToString(DateTime dateTime, TimeOfDay timeOfDay){
    String mes = dateTime.month < 10 ? '0${dateTime.month}' : '${dateTime.month}';
    String dia = dateTime.day < 10 ? '0${dateTime.day}' : '${dateTime.day}';
    String hora = timeOfDay.hour < 10 ? '0${timeOfDay.hour}' : '${timeOfDay.hour}';
    String minutos = timeOfDay.minute < 10 ? '0${timeOfDay.minute}' : '${timeOfDay.minute}';

    String fecha = "El $dia/$mes a las $hora:$minutos hs";
    return fecha;
  }

  Future<void> _cargarIntegrantes() async {
    setState(() {
      _loadingChatInfo = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlChatGrupalInformacion,
      queryParams: {
        "chat_id": widget.chat.id
      },
      usuarioSesion: _usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){
        var datosActividad = datosJson['data']['actividad'];

        _actividad = Actividad(
          id: datosActividad['id'],
          titulo: datosActividad['titulo'],
          descripcion: datosActividad['descripcion'],
          fecha: datosActividad['fecha_texto'],
          privacidadTipo: Actividad.getActividadPrivacidadTipoFromString(datosActividad['privacidad_tipo']),
          ingresoEstado: ActividadIngresoEstado.INTEGRANTE,
          isAutor: datosActividad['autor_usuario_id'] == _usuarioSesion!.id,

          // Los siguientes datos de Actividad no son usados (no son los datos reales)
          interes: "",
          isLiked: false,
          likesCount: 0,
          creadores: [],
        );

        List<dynamic> integrantes = datosJson['data']['integrantes'];
        for (var element in integrantes) {
          if(UsuarioChatIntegrante.getUsuarioChatIntegranteRolFromString(element['chat_rol']) == UsuarioChatIntegranteRol.ADMINISTRADOR){
            // Es co-creador
            if(element['id'] == _usuarioSesion!.id){
              _isCreador = true;
            }
          }

          UsuarioChatIntegrante usuarioChatIntegrante = UsuarioChatIntegrante(
            usuario: Usuario(
              id: element['id'],
              nombre: element['nombre_completo'],
              username: element['username'],
              foto: constants.urlBase + element['foto_url'],
            ),
            rol: UsuarioChatIntegrante.getUsuarioChatIntegranteRolFromString(element['chat_rol']),
            isAutor: datosActividad['autor_usuario_id'] == element['id'],
          );

          _integrantes.add(usuarioChatIntegrante);
        }

        _isGrupoLleno = datosJson['data']['is_grupo_lleno'];

        if(datosJson['data']['encuentro_fecha'] != null){
          _dateSelected = DateTime.fromMillisecondsSinceEpoch(datosJson['data']['encuentro_fecha']);
          _timeSelected = TimeOfDay.fromDateTime(_dateSelected);

          _encuentroFechaString = _encuentroFechaToString(_dateSelected, _timeSelected);
        }

        if(datosJson['data']['encuentro_link'] != null){
          _encuentroLink = datosJson['data']['encuentro_link'];
        }


        // Tooltip de ayuda a los usuarios nuevos para editar una fecha de encuentro
        bool isShowedGrupoFecha = prefs.getBool(SharedPreferencesKeys.isShowedAyudaGrupoEditarFecha) ?? false;
        if(!isShowedGrupoFecha){
          _showTooltipGrupoFecha();
        }

      } else {

        if(datosJson['error_tipo'] == 'no_integrante'){
          _isIntegrante = false;
          _showSnackBar("Solo los integrantes pueden ver Info. del grupo.");
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _loadingChatInfo = false;
    });
  }

  void _showDialogSalirGrupo(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Salir del grupo?'),
          content: Text(_actividad!.isAutor
              ? 'Ya no podrás volver acceder al chat grupal. Como eres el autor de la actividad vinculada, la actividad será eliminada automáticamente.'
              : 'Al salir del grupo, te perderás los nuevos mensajes y los nuevos integrantes que se unan.'
                + (_integrantes.length <= 2 ? ' También podés esperar un poco más, ¡podrían unirse más personas pronto!' : '')
              // TODO : el mensaje no tiene sentido si la actividad ya no está visible
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: _enviandoSalirGrupo ? null : () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Salir'),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
              onPressed: _enviandoSalirGrupo ? null : () => _salirGrupo(setStateDialog),
            ),
          ],
        );
      });
    });
  }

  Future<void> _salirGrupo(setStateDialog) async {
    setStateDialog(() {
      _enviandoSalirGrupo = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlChatGrupalSalir,
      body: {
        "chat_id": widget.chat.id
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
      _enviandoSalirGrupo = false;
    });
  }

  List<TextSpan> _linkify(String text) {
    var list = <TextSpan>[];
    var match = _regExUrl.firstMatch(text);

    // If there are no matches, return all the text
    if (match == null) {
      list.add(TextSpan(text: text));
      return list;
    }

    // If there is some text before the match, add it to the list
    if (match.start > 0) list.add(TextSpan(text: text.substring(0, match.start)));

    list.add(_buildLinkComponent(match.group(0)!));

    // Call this function again and concatenate its list to ours
    list.addAll(_linkify(text.substring(match.start + match.group(0)!.length)));

    return list;
  }
  TextSpan _buildLinkComponent(String link) => TextSpan(
    text: link,
    style: const TextStyle(
      color: constants.blueGeneral,
      decoration: TextDecoration.underline,
      fontSize: 12,
    ),
    recognizer: TapGestureRecognizer()..onTap = () async {
      var realLink = link.startsWith('http') ? link : 'https://$link';

      Uri url = Uri.parse(realLink);

      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch(e){
        throw 'Could not launch $realLink';
      }
    },
  );

  void _showDialogEditarLink(){
    _encuentroLinkController.text = _encuentroLink ?? "";
    _encuentroLinkErrorText = null;

    showDialog(context: context, builder: (context){
      return StatefulBuilder(builder: (context, setStateDialog){
        return AlertDialog(
          content: TextField(
            autofocus: true,
            controller: _encuentroLinkController,
            decoration: InputDecoration(
              isDense: true,
              hintText: "Ingresa un link de Maps...",
              counterText: '',
              border: OutlineInputBorder(),
              errorText: _encuentroLinkErrorText,
            ),
            maxLength: 200,
            style: const TextStyle(fontSize: 12,),
            keyboardType: TextInputType.url,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _enviandoEncuentroLink ? null : () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: _enviandoEncuentroLink ? null : () => _guardarLinkNuevo(setStateDialog),
              child: const Text("Guardar"),
            ),
          ],
        );
      });
    }, barrierDismissible: false,);
  }

  Future<void> _guardarLinkNuevo(setStateDialog) async {
    _encuentroLinkErrorText = null;

    setStateDialog(() {
      _enviandoEncuentroLink = true;
    });


    String link = _encuentroLinkController.text;
    if(!_regExUrl.hasMatch(link)){
      _encuentroLinkErrorText = 'Link no válido';
      setStateDialog(() {_enviandoEncuentroLink = false;});
      return;
    }
    // Solo acepta url con https
    if(link.startsWith('http://')) {
      link = 'https' + link.substring(4);
    }
    link = link.startsWith('https') ? link : 'https://$link';


    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlChatGrupalCambiarLink,
      body: {
        "chat_id": widget.chat.id,
        "encuentro_link": link
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){
        _encuentroLink = link;
        setState(() {});
      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoEncuentroLink = false;
    });

    Navigator.of(context).pop();
  }

  void _showDialogEditarFecha() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateSelected,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if(picked != null){
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _timeSelected,
      );

      if(pickedTime != null){
        _guardarFechaNuevo(picked, pickedTime);
      }
    }
  }

  Future<void> _guardarFechaNuevo(DateTime dateTimePicked, TimeOfDay timeOfDayPicked) async {
    setState(() {
      _enviandoEncuentroFecha = true;
    });

    DateTime dateEncuentroFecha = DateTime(dateTimePicked.year, dateTimePicked.month, dateTimePicked.day, timeOfDayPicked.hour, timeOfDayPicked.minute);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);


    // Tooltip de ayuda a los usuarios nuevos para editar una fecha de encuentro. Actualiza valor para no volver a mostrar.
    bool isShowedGrupoFecha = prefs.getBool(SharedPreferencesKeys.isShowedAyudaGrupoEditarFecha) ?? false;
    if(!isShowedGrupoFecha){
      prefs.setBool(SharedPreferencesKeys.isShowedAyudaGrupoEditarFecha, true);
    }


    var response = await HttpService.httpPost(
      url: constants.urlChatGrupalCambiarFecha,
      body: {
        "chat_id": widget.chat.id,
        "encuentro_fecha": dateEncuentroFecha.millisecondsSinceEpoch.toString()
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _dateSelected = dateTimePicked;
        _timeSelected = timeOfDayPicked;
        _encuentroFechaString = _encuentroFechaToString(_dateSelected, _timeSelected);

      } else {
        if(datosJson['error_tipo'] == 'encuentro_fecha_limite'){
          _showSnackBar("No se puede agregar una actividad mayor a 30 días. Elija una fecha más cercana.");
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }
      }
    }

    setState(() {
      _enviandoEncuentroFecha = false;
    });
  }

  void _showDialogEnviarSticker(){
    showDialog(context: context, builder: (context) {
      return DialogEnviarSticker(isGroup: true, chat: widget.chat);
    });
  }

  void _showDialogAyudaSticker(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            Text(Platform.isIOS
              ? "Envía una propina/regalo como un buen gesto a los cocreadores.\n\n"
                "El cocreador que lo reciba, tendrá el mismo valor en bitcoin.\n\n"
                "Cuando se envía una propina, este será enviado aleatoriamente hacia alguno de los cocreadores."
              : "Envía un sticker como un buen gesto a los cocreadores.\n\n"
                "Los stickers son micro-regalos que el cocreador que lo reciba podrá canjear por el mismo valor del sticker en bitcoin.\n\n"
                "Cuando se envía un sticker, este será enviado aleatoriamente hacia alguno de los cocreadores.",
              style: TextStyle(color: constants.grey, fontSize: 12,),
              textAlign: TextAlign.center,
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

  void _showDialogOpcionesIntegrante(UsuarioChatIntegrante integrante){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        content: Column(children: [
          ListTile(
            title: const Text("Ver perfil"),
            onTap: (){
              Navigator.of(context).pop();
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => UserPage(usuario: integrante.usuario, compartenGrupoChatId: widget.chat.id,),
              ));
            },
          ),
          if(!integrante.isAutor && integrante.usuario.id != _usuarioSesion!.id)
            ListTile(
              title: const Text("Eliminar integrante"),
              onTap: (){
                Navigator.of(context).pop();
                _showDialogEliminarIntegrante(integrante);
              },
            ),
        ], mainAxisSize: MainAxisSize.min,),
      );
    });
  }

  void _showDialogEliminarIntegrante(UsuarioChatIntegrante integrante){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text('¿Eliminar a ${integrante.usuario.username}?'),
          content: const Text('Esta persona no podrá volver a entrar al chat grupal.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: _enviandoEliminarIntegrante ? null : () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar'),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
              onPressed: _enviandoEliminarIntegrante ? null : () => _eliminarIntegrante(setStateDialog, integrante),
            ),
          ],
        );
      });
    });
  }

  Future<void> _eliminarIntegrante(setStateDialog, UsuarioChatIntegrante integrante) async {
    setStateDialog(() {
      _enviandoEliminarIntegrante = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlChatEliminarIntegrante,
      body: {
        "chat_id": widget.chat.id,
        "usuario_id": integrante.usuario.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        for(int i = 0; i < _integrantes.length; i++){
          if(_integrantes[i].usuario.id == integrante.usuario.id){
            _integrantes.removeAt(i);
            break;
          }
        }

        _isGrupoLleno = false;

        Navigator.of(context).pop();
        setState(() {});

      } else {
        Navigator.of(context).pop();

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoEliminarIntegrante = false;
    });
  }

  Future<void> _showTooltipGrupoFecha() async {
    await Future.delayed(const Duration(milliseconds: 500,));
    _isAvailableTooltipGrupoFecha = true;
    setState(() {});
    await Future.delayed(const Duration(seconds: 5,));
    _isAvailableTooltipGrupoFecha = false;
    setState(() {});
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

class _CustomShapeBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(10)))
      ..moveTo(rect.left + rect.width - 25 - 10, rect.bottom)
      ..lineTo(rect.left + rect.width - 25, rect.bottom + 10)
      ..lineTo(rect.left + rect.width - 25 + 10, rect.bottom);

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return _CustomShapeBorder();
  }
}