import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/buscador/buscador_page.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/intereses.dart';
import 'package:tenfo/widgets/card_actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/widgets/dialog_cambiar_intereses.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

enum LocationPermissionStatus {
  loading,
  permitted,
  notPermitted,
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<String> _intereses = [];
  List<Widget> _interesesIcons = [];

  List<Actividad> _actividades = [];
  bool _isActividadesPermitido = true;

  ScrollController _scrollController = ScrollController();
  bool _loadingActividades = false;
  bool _verMasActividades = false;
  String _ultimoActividades = "false";

  DateTime? _lastTimeCargarActividades;

  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.loading;
  Position? _position;
  bool _isCiudadDisponible = true;

  @override
  void initState() {
    super.initState();

    _mostrarIntereses();

    _recargarActividades();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingActividades && _verMasActividades){
          _cargarActividades();
        }
      }
    });

    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Se abrió la app desde segundo plano (o cuando vuelve de exterior, por ej. al aceptar ubicacion)

      DateTime timeNow = DateTime.now();

      if(!_loadingActividades && _lastTimeCargarActividades != null && timeNow.difference(_lastTimeCargarActividades!).inMinutes >= 15){
        // Vuelve a cargar actividades, si al volver de segundo plano, pasaron más de 15 minutos de las ultimas actividades cargadas
        _recargarActividades();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Actividades"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => BuscadorPage()));
            },
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if(_permissionStatus != LocationPermissionStatus.loading && _permissionStatus == LocationPermissionStatus.notPermitted)
            _buildSeccionSolicitarUbicacion(),

          if (_permissionStatus != LocationPermissionStatus.loading && _permissionStatus == LocationPermissionStatus.permitted)
            ...[
              if(_actividades.isEmpty && _loadingActividades)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),

              if(_actividades.isNotEmpty || !_loadingActividades)
                ...[
                  if(!_isActividadesPermitido)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildActividadesNoPermitido(),
                    ),

                  if(_isActividadesPermitido)
                    ...[
                      const SliverPadding(
                        padding: EdgeInsets.only(left: 8, top: 16, right: 8, bottom: 8),
                        sliver: SliverToBoxAdapter(
                          child: Text("Mis intereses: ",
                            style: TextStyle(color: constants.blackGeneral,),
                          ),
                        ),
                      ),
                      _buildSeccionIntereses(),

                      (_actividades.isEmpty)
                        ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildActividadesVacio(),
                        )
                        : SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index){

                            if(index == _actividades.length){
                              return _buildLoadingActividades();
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                              child: CardActividad(actividad: _actividades[index]),
                            );
                          }, childCount: _actividades.length + 1)),
                        ),
                    ],
                ],
            ],
        ],
      ),
      backgroundColor: constants.greyBackgroundScreen,
    );
  }

  Future<void> _mostrarIntereses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    _intereses = usuarioSesion.interesesId;
    _buildInteresesIcons();
  }

  Future<void> _recargarActividades() async {
    _loadingActividades = true;
    _verMasActividades = false;
    _ultimoActividades = "false";

    _actividades = [];

    setState(() {});

    bool ubicacionPermitida = await _verificarUbicacion();
    if(ubicacionPermitida){

      _position = await Geolocator.getCurrentPosition();
      _cargarActividades();

    } else {
      _loadingActividades = false;
      setState(() {});
    }
  }

  Future<bool> _verificarUbicacion() async {
    _position = null;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _permissionStatus = LocationPermissionStatus.notPermitted;
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _permissionStatus = LocationPermissionStatus.notPermitted;
      return false;
    }

    try {

      _permissionStatus = LocationPermissionStatus.permitted;

    } catch (e){
      _permissionStatus = LocationPermissionStatus.notPermitted;
      return false;
    }

    return true;
  }

  Future<void> _cargarActividades() async {
    setState(() {
      _loadingActividades = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    if(usuarioSesion.interesesId.isEmpty){
      _showDialogCambiarIntereses();
      _isActividadesPermitido = false; // Puede que si tenga permitido, si acepto ser cocreador y nunca eligió sus intereses
      setState(() {_loadingActividades = false;});
      return;
    }
    String interesesIdString = usuarioSesion.interesesId.join(",");

    // Se usa POST porque envia datos privados (ubicacion)
    var response = await HttpService.httpPost(
      url: constants.urlHomeVerActividades,
      body: {
        "ultimo_id": _ultimoActividades,
        "intereses": interesesIdString,
        "ubicacion_latitud": _position?.latitude.toString() ?? "",
        "ubicacion_longitud": _position?.longitude.toString() ?? ""
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        datosJson = datosJson['data'];

        _ultimoActividades = datosJson['ultimo_id'];
        _verMasActividades = datosJson['ver_mas'];

        List<dynamic> actividades = datosJson['actividades'];
        for (var element in actividades) {

          List<Usuario> creadores = [];
          element['creadores'].forEach((usuario) {
            creadores.add(Usuario(
              id: usuario['id'],
              nombre: usuario['nombre_completo'],
              username: usuario['username'],
              foto: constants.urlBase + usuario['foto_url'],
            ));
          });

          Actividad actividad = Actividad(
            id: element['id'],
            titulo: element['titulo'],
            descripcion: element['descripcion'],
            fecha: element['fecha_texto'],
            privacidadTipo: Actividad.getActividadPrivacidadTipoFromString(element['privacidad_tipo']),
            interes: element['interes_id'].toString(),
            creadores: creadores,
            ingresoEstado: Actividad.getActividadIngresoEstadoFromString(element['ingreso_estado']),
            isAutor: element['autor_usuario_id'] == usuarioSesion.id,
          );

          if(element['chat'] != null){
            Chat chat = Chat(
              id: element['chat']['id'].toString(),
              tipo: ChatTipo.GRUPAL,
              numMensajesPendientes: null,
              actividadChat: actividad,
            );
            actividad.chat = chat;
          }

          _actividades.add(actividad);
        }

        _isActividadesPermitido = datosJson['is_permitido_ver_actividades'];

        _lastTimeCargarActividades = DateTime.now();

      } else {

        if(datosJson['error_tipo'] == 'ubicacion_no_disponible'){
          _isActividadesPermitido = true;
          _isCiudadDisponible = false;
          _showDialogCiudadNoDisponible();
        } else if(datosJson['error_tipo'] == 'intereses_vacio'){
          _showDialogCambiarIntereses();
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _loadingActividades = false;
    });
  }

  void _showDialogCiudadNoDisponible(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text("Lo sentimos, actualmente Tenfo no está disponible en tu ciudad. Puedes revisar nuestro instagram @tenfo.app para "
                  "ver las ciudades disponibles actualmente.",
                style: TextStyle(color: constants.blackGeneral),),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            child: const Text("Entendido"),
          ),
        ],
      );
    });
  }

  Widget _buildActividadesNoPermitido(){
    return Stack(children: [

      Positioned.fill(
        child: IgnorePointer(
          child: SingleChildScrollView(child: Column(children: [
            const SizedBox(height: 12,),
            for (int i=0; i<5; i++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: constants.grey),
                  color: Colors.white,
                ),
              ),
          ], crossAxisAlignment: CrossAxisAlignment.stretch,),)
        ),
      ),

      BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 3.0,
          sigmaY: 3.0,
        ),
        child: Center(child: Card(
          elevation: 20,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.grey, width: 0.5,),
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16,),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(children: [

              Text("Crea tu actividad para acceder a las actividades disponibles.",
                style: TextStyle(color: Colors.grey[800], fontSize: 14,),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8,),
              Text("Tu actividad solo lo podrán ver personas que también crearon en este momento.",
                style: TextStyle(color: Colors.grey[800], fontSize: 14,),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32,),

              Container(
                constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                child: ElevatedButton.icon(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const CrearActividadPage(),
                    ));
                  },
                  icon: const Icon(Icons.add_rounded, size: 24,),
                  label: const Text("Comenzar", style: TextStyle(fontSize: 16,),),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),
              ),

              const SizedBox(height: 32,),
              const Text('Podés crear algo simple como "¿Qué sale hoy?"',
                style: TextStyle(color: constants.grey, fontSize: 12,),
                textAlign: TextAlign.center,
              ),

            ], mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,),
          ),
        )),
      ),
    ]);

    /*
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 16,),
      child: Column(children: [
        Container(
          //constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: (){
              _showDialogCambiarIntereses();
            },
            icon: const Icon(Icons.edit_outlined, size: 16,),
            label: const Text("Editar intereses",
                style: TextStyle(fontSize: 12,)
            ),
            style: TextButton.styleFrom(
              primary: constants.blackGeneral,
              padding: const EdgeInsets.all(0),
            ),
          ),
        ),

        Expanded(child: Column(children: [
          Text("Para ver las actividades, debes tener una tuya creada en las últimas 48 horas.",
            style: TextStyle(color: Colors.grey[800], fontSize: 16,),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24,),
          Container(
            constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
            child: ElevatedButton.icon(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const CrearActividadPage(),
                ));
              },
              icon: const Icon(Icons.add_rounded, size: 24,),
              label: const Text("Crear actividad", style: TextStyle(fontSize: 16,),),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(
                  side: BorderSide(color: constants.grey, width: 0.5,),
                ),
                primary: Colors.white,
                onPrimary: constants.blueGeneral,
              ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
            ),
          ),
        ], mainAxisAlignment: MainAxisAlignment.center,)),

        // Lo hace ver más centrado al Expanded (es una altura aproximada del TextButton "Editar intereses")
        const SizedBox(height: 40,),
      ],),
    );
    */
  }

  Widget _buildActividadesVacio(){

    if(!_isCiudadDisponible){
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text("Lo sentimos, actualmente Tenfo no está disponible en tu ciudad.",
          style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Text("No hay actividades cerca disponibles según tus intereses.",
        style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSeccionIntereses(){
    return SliverPadding(
      padding: const EdgeInsets.only(left: 8, right: 8,),
      sliver: SliverToBoxAdapter(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _interesesIcons,
        ),
      ),
    );
  }

  void _buildInteresesIcons(){
    _interesesIcons = [];

    List<String> listIntereses = Intereses.getListaIntereses();
    listIntereses.forEach((element) {
      if(_intereses.contains(element)){
        _interesesIcons.add(_buildInteres(Intereses.getNombre(element), Intereses.getIcon(element)));
      }
    });
    _interesesIcons.add(_buildInteresCambiar());

    setState(() {});
  }

  Widget _buildInteres(String texto, Icon icon){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: constants.blackGeneral, width: 0.5,),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Text(texto, style: TextStyle(color: constants.blackGeneral, fontSize: 12,),),
        icon,
      ], mainAxisSize: MainAxisSize.min,),
    );
  }

  Widget _buildInteresCambiar(){
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: constants.blueGeneral),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: (){
          _showDialogCambiarIntereses();
        },
        icon: const Icon(Icons.edit, color: constants.blueGeneral,),
        padding: const EdgeInsets.all(0),
      ),
    );
  }

  void _showDialogCambiarIntereses(){
    showDialog(context: context, builder: (context) {
      return DialogCambiarIntereses(intereses: _intereses, onChanged: (nuevosIntereses){
        _intereses = nuevosIntereses;
        _buildInteresesIcons();

        Navigator.of(context).pop();

        _recargarActividades();
      },);
    });
  }


  Widget _buildSeccionSolicitarUbicacion(){
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.location_on, size: 50.0, color: constants.grey,),
            const SizedBox(height: 15.0,),
            Text(
              'Es necesario permitir ubicación para ver actividades de tu ciudad y al crear tus actividades. '
                  'Tu ubicación siempre será privada y nunca será compartida con otros usuarios.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 15.0,),
            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              child: ElevatedButton(
                onPressed: () {
                  _habilitarUbicacion();
                },
                child: const Text('Permitir ubicación'),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _habilitarUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Tienes los servicios de ubicación deshabilitados. Actívalo desde Ajustes.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Los permisos están denegados. Permite la ubicación desde Ajustes en la app.");
      return;
    }

    try {

      _permissionStatus = LocationPermissionStatus.permitted;
      setState(() {});

      _recargarActividades();

    } catch (e){
      //
    }
  }

  Widget _buildLoadingActividades(){
    if(_loadingActividades){
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Opacity(
            opacity: _loadingActividades ? 1.0 : 00,
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}