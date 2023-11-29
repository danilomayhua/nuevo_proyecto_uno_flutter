import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/publicacion.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/screens/buscador/buscador_page.dart';
import 'package:tenfo/screens/seleccionar_crear_tipo/seleccionar_crear_tipo_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/intereses.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:tenfo/widgets/card_actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/widgets/card_disponibilidad.dart';
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

  List<Publicacion> _publicaciones = [];
  bool _isActividadesPermitido = true;
  bool _isCreadorActividadVisible = false;

  ScrollController _scrollController = ScrollController();
  bool _loadingActividades = false;
  bool _verMasActividades = false;
  Map<String, dynamic> _ultimosId = {
    "actividades_ultimo_id": "false",
    "disponibilidades_ultimo_id": "false"
  };
  String _ultimoActividadIdMostrado = "";

  DateTime? _lastTimeCargarActividades;

  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.loading;
  Position? _position;
  bool _isCiudadDisponible = true;

  bool _isAvailableTooltipUnirse = false;

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
              if(_publicaciones.isEmpty && _loadingActividades)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),

              if(_publicaciones.isNotEmpty || !_loadingActividades)
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
                          child: Text("Intereses:",
                            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                          ),
                        ),
                      ),
                      _buildSeccionIntereses(),

                      (_publicaciones.isEmpty)
                        ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildActividadesVacio(),
                        )
                        : SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                          sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index){
                            if(index == _publicaciones.length){
                              return _buildLoadingActividades();
                            }

                            if(_publicaciones[index].tipo == PublicacionTipo.ACTIVIDAD){

                              if(_publicaciones[index].actividad!.id == _ultimoActividadIdMostrado
                                  && _ultimosId['actividades_ultimo_id'] == null){
                                return Column(children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    child: CardActividad(actividad: _publicaciones[index].actividad!, showTooltipUnirse: index == 0 && _isAvailableTooltipUnirse,),
                                  ),
                                  const SizedBox(height: 40,),
                                  Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 16,),
                                    child: const Text("No hay más actividades cerca disponibles según tus intereses.",
                                      style: TextStyle(color: constants.blackGeneral, fontSize: 14,
                                        height: 1.3, fontWeight: FontWeight.bold,),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 40,),
                                  const Divider(color: constants.greyLight, height: 0.5,),
                                  const SizedBox(height: 24,),
                                ],);
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: CardActividad(actividad: _publicaciones[index].actividad!, showTooltipUnirse: index == 0 && _isAvailableTooltipUnirse,),
                              );

                            } else {

                              if(_ultimosId['actividades_ultimo_id'] == null){
                                if((index == 0 && _ultimoActividadIdMostrado == "") ||
                                    (index != 0 && _ultimoActividadIdMostrado != "" && (_publicaciones[index-1].actividad?.id ?? "") == _ultimoActividadIdMostrado)){
                                  return Column(children: [
                                    if(index == 0)
                                      ...[
                                        const SizedBox(height: 40,),
                                        Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(horizontal: 16,),
                                          child: const Text("No hay actividades cerca disponibles según tus intereses.",
                                            style: TextStyle(color: constants.blackGeneral, fontSize: 14,
                                              height: 1.3, fontWeight: FontWeight.bold,),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 48,),
                                        const Divider(color: constants.greyLight, height: 0.5,),
                                        const SizedBox(height: 24,),
                                      ],

                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 8, right: 8, bottom: 16,),
                                        child: Text("Buscando actividades:",
                                          style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                      child: CardDisponibilidad(
                                        disponibilidad: _publicaciones[index].disponibilidad!,
                                        isCreadorActividadVisible: _isCreadorActividadVisible,
                                      ),
                                    ),
                                  ],);
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                child: CardDisponibilidad(
                                  disponibilidad: _publicaciones[index].disponibilidad!,
                                  isCreadorActividadVisible: _isCreadorActividadVisible,
                                ),
                              );

                            }

                          }, childCount: _publicaciones.length + 1)),
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
    _ultimosId = {
      "actividades_ultimo_id": "false",
      "disponibilidades_ultimo_id": "false"
    };
    _ultimoActividadIdMostrado = "";

    _publicaciones = [];

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
        "ultimos_id": _ultimosId,
        "intereses": interesesIdString,
        "ubicacion_latitud": _position?.latitude.toString() ?? "",
        "ubicacion_longitud": _position?.longitude.toString() ?? ""
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        // Tooltip de ayuda a los usuarios nuevos para unirse a una actividad. Se muestra en la primera carga.
        bool isShowedUnirse = prefs.getBool(SharedPreferencesKeys.isShowedAyudaActividadUnirse) ?? false;
        if(!isShowedUnirse && _publicaciones.isEmpty){
          _showTooltipUnirse();
        }


        datosJson = datosJson['data'];

        _ultimosId = datosJson['ultimos_id'];
        _verMasActividades = datosJson['ver_mas'];

        List<dynamic> publicaciones = datosJson['publicaciones'];
        for (var element in publicaciones) {

          Actividad? actividad;
          if(element['actividad'] != null){
            var actividadDatos = element['actividad'];

            List<Usuario> creadores = [];
            actividadDatos['creadores'].forEach((usuario) {
              creadores.add(Usuario(
                id: usuario['id'],
                nombre: usuario['nombre_completo'],
                username: usuario['username'],
                foto: constants.urlBase + usuario['foto_url'],
              ));
            });

            actividad = Actividad(
              id: actividadDatos['id'],
              titulo: actividadDatos['titulo'],
              descripcion: actividadDatos['descripcion'],
              fecha: actividadDatos['fecha_texto'],
              privacidadTipo: Actividad.getActividadPrivacidadTipoFromString(actividadDatos['privacidad_tipo']),
              interes: actividadDatos['interes_id'].toString(),
              creadores: creadores,
              ingresoEstado: Actividad.getActividadIngresoEstadoFromString(actividadDatos['ingreso_estado']),
              isAutor: actividadDatos['autor_usuario_id'] == usuarioSesion.id,
            );

            if(actividadDatos['chat'] != null){
              Chat chat = Chat(
                id: actividadDatos['chat']['id'].toString(),
                tipo: ChatTipo.GRUPAL,
                numMensajesPendientes: null,
                actividadChat: actividad,
              );
              actividad.chat = chat;
            }

            _ultimoActividadIdMostrado = actividad.id;
          }

          Disponibilidad? disponibilidad;
          if(element['disponibilidad'] != null){
            var disponibilidadDatos = element['disponibilidad'];

            disponibilidad = Disponibilidad(
              id: disponibilidadDatos['id'],
              creador: DisponibilidadCreador(
                id: disponibilidadDatos['creador']['id'],
                foto: constants.urlBase + disponibilidadDatos['creador']['foto_url'],
                nombre: disponibilidadDatos['creador']['nombre'],
                isVerificadoUniversidad: disponibilidadDatos['creador']['is_verificado_universidad'],
                verificadoUniversidadNombre: disponibilidadDatos['creador']['verificado_universidad_nombre'],
              ),
              texto: disponibilidadDatos['texto'],
              fecha: disponibilidadDatos['fecha_texto'],
              isAutor: disponibilidadDatos['creador']['id'] == usuarioSesion.id,
            );
          }

          _publicaciones.add(Publicacion(
            tipo: Publicacion.getPublicacionTipoFromString(element['tipo']),
            actividad: actividad,
            disponibilidad: disponibilidad,
          ));
        }

        _isActividadesPermitido = datosJson['is_permitido_ver_actividades'];
        _isCreadorActividadVisible = datosJson['is_creador_actividad_visible'];

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
          elevation: 10,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.grey, width: 0.5,),
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16,),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(children: [

              Text("Crea tu actividad o visualización para acceder a las actividades disponibles.",
                style: TextStyle(color: Colors.grey[800], fontSize: 14,),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8,),
              Text("Esto solo lo podrán ver personas que también crearon en este momento.",
                style: TextStyle(color: Colors.grey[800], fontSize: 14,),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32,),

              Container(
                constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                child: ElevatedButton.icon(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const SeleccionarCrearTipoPage(),
                    ));
                  },
                  icon: const Icon(Icons.add_rounded, size: 24,),
                  label: const Text("Comenzar", style: TextStyle(fontSize: 18,),),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),
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
          spacing: 6,
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
        _interesesIcons.add(_buildInteres(Intereses.getNombre(element), Intereses.getIcon(element, size: 18,)));
      }
    });
    _interesesIcons.add(_buildInteresCambiar());

    setState(() {});
  }

  Widget _buildInteres(String texto, Icon icon){
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: constants.grey, width: 0.5,),
        shape: BoxShape.circle,
      ),
      child: icon,
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

  Future<void> _showTooltipUnirse() async {
    await Future.delayed(const Duration(milliseconds: 500,));
    _isAvailableTooltipUnirse = true;
    setState(() {});
    await Future.delayed(const Duration(seconds: 5,));
    _isAvailableTooltipUnirse = false;
    setState(() {});
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}