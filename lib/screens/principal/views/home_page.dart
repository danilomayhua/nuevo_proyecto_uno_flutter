import 'dart:convert';
import 'dart:ui';

import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/previsualizacion_actividad.dart';
import 'package:tenfo/models/publicacion.dart';
import 'package:tenfo/models/sugerencia_usuario.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/screens/crear_disponibilidad/crear_disponibilidad_page.dart';
import 'package:tenfo/screens/notificaciones/notificaciones_page.dart';
import 'package:tenfo/screens/principal/views/mis_actividades_page.dart';
import 'package:tenfo/screens/seleccionar_crear_tipo/seleccionar_crear_tipo_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/services/location_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/intereses.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:tenfo/widgets/card_actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/widgets/card_disponibilidad.dart';
import 'package:tenfo/widgets/card_sugerencia_usuario.dart';
import 'package:tenfo/widgets/dialog_cambiar_intereses.dart';
import 'package:tenfo/widgets/scrollsnap_card_actividad.dart';
import 'package:tenfo/widgets/scrollsnap_card_disponibilidad.dart';
import 'package:tenfo/widgets/scrollsnap_card_sugerencia_usuario.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.showBadgeNotificaciones, required this.setShowBadge}) : super(key: key);

  final bool showBadgeNotificaciones;
  final void Function(bool) setShowBadge;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {

  String? _usuarioSesionFoto;

  bool _showBadgeNotificaciones = false;

  List<String> _intereses = [];
  String? _interesSeleccionado;

  List<Publicacion> _publicaciones = [];
  bool _isActividadesPermitido = true;
  bool _isCreadorActividadVisible = false;
  bool _isAutorActividadVisible = false;

  List<PrevisualizacionActividad> _previsualizacionActividades = [];

  ScrollController _scrollController = ScrollController();
  bool _loadingActividades = false;
  bool _verMasActividades = false;
  Map<String, dynamic> _ultimosId = {
    "actividades_ultimo_id": "false",
    "disponibilidades_ultimo_id": "false"
  };
  String _ultimoActividadIdMostrado = "";

  DateTime? _lastTimeCargarActividades;

  final LocationService _locationService = LocationService();
  LocationServicePermissionStatus _permissionStatus = LocationServicePermissionStatus.loading;
  LocationServicePosition? _locationServicePosition;
  bool _isCiudadDisponible = true;

  bool _isAvailableTooltipUnirse = false;

  bool _hasShownTooltipSuperlike = false;
  int? _indexDisponibilidadTooltip;
  final GlobalKey _keyDisponibilidadTooltip = GlobalKey();
  bool _isDisponibilidadTooltipVisible = false;

  @override
  void initState() {
    super.initState();

    _showBadgeNotificaciones = widget.showBadgeNotificaciones;

    _mostrarInteresesYTutorial();

    _recargarActividades();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingActividades && _verMasActividades){
          _cargarActividades(setState);
        }
      }


      // Saber si está visible en pantalla la disponibilidad del tooltip
      if(!_hasShownTooltipSuperlike && !_isDisponibilidadTooltipVisible){
        final RenderObject? renderObject = _keyDisponibilidadTooltip.currentContext?.findRenderObject();
        if (renderObject is RenderBox) {
          final offset = renderObject.localToGlobal(Offset.zero);

          bool isDisponibilidadVisible = offset.dy < MediaQuery.of(context).size.height && offset.dy + renderObject.size.height > 0;

          if(isDisponibilidadVisible){
            _isDisponibilidadTooltipVisible = true;
            setState(() {});
          }
        }
      }
    });

    WidgetsBinding.instance?.addObserver(this);

    _verificarNotificacionesPush();
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
        title: const Text("Tenfo"),
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: constants.blackGeneral, width: 1,),
              ),
              height: 28,
              width: 28,
              child: CircleAvatar(
                backgroundColor: constants.greyBackgroundImage,
                backgroundImage: _usuarioSesionFoto != null ? CachedNetworkImageProvider(_usuarioSesionFoto!) : null,
              ),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const MisActividadesPage(),
              ));
            },
          ),
          badges.Badge(
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificacionesPage()));
                setState(() {
                  _showBadgeNotificaciones = false;
                });
                widget.setShowBadge(false);
              },
            ),
            showBadge: _showBadgeNotificaciones,
            badgeColor: constants.blueGeneral,
            padding: const EdgeInsets.all(6),
            position: badges.BadgePosition.topEnd(top: 12, end: 12,),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if(_permissionStatus != LocationServicePermissionStatus.loading && _permissionStatus != LocationServicePermissionStatus.permitted)
            _buildSeccionSolicitarUbicacion(),

          if(_permissionStatus != LocationServicePermissionStatus.loading && _permissionStatus == LocationServicePermissionStatus.permitted)
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
                      //_buildSeccionIntereses(),
                      _buildSeccionInteresesTabs(),

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

                              return Column(children: [

                                if(index == 0 || _publicaciones[index-1].tipo != PublicacionTipo.ACTIVIDAD)
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 16, right: 8, bottom: 8,),
                                      child: Text("Actividades:",
                                        style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                                      ),
                                    ),
                                  ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: CardActividad(
                                    actividad: _publicaciones[index].actividad!,
                                    showTooltipUnirse: index == 0 && _isAvailableTooltipUnirse,
                                    onOpen: (){
                                      _showDialogPublicacionesJuego(index);
                                    },
                                    onChangeActividad: (Actividad actividad){
                                      setState(() {
                                        _publicaciones[index].actividad = actividad;
                                      });
                                    },
                                  ),
                                ),

                                if(_publicaciones[index].actividad!.id == _ultimoActividadIdMostrado && _ultimosId['actividades_ultimo_id'] == null)
                                  ...[
                                    const SizedBox(height: 40,),
                                    Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 16,),
                                      child: Text(_interesSeleccionado == null
                                          ? "No hay más actividades cerca disponibles actualmente."
                                          : "No hay más actividades cerca disponibles actualmente en ${Intereses.getNombre(_interesSeleccionado!)}.",
                                        style: const TextStyle(color: constants.blackGeneral, fontSize: 14,
                                          height: 1.3, fontWeight: FontWeight.bold,),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 24,),
                                  ],

                                if(index < (_publicaciones.length-1) && _publicaciones[index+1].tipo != PublicacionTipo.ACTIVIDAD)
                                  ...[
                                    const SizedBox(height: 16,),
                                  ],

                              ],);

                            } else if(_publicaciones[index].tipo == PublicacionTipo.DISPONIBILIDAD){

                              if(_indexDisponibilidadTooltip == null){
                                _indexDisponibilidadTooltip = index;
                              }

                              bool showTooltipSuperlike = !_hasShownTooltipSuperlike && _indexDisponibilidadTooltip == index && _isDisponibilidadTooltipVisible;
                              if (showTooltipSuperlike) {
                                _hasShownTooltipSuperlike = true;
                              }

                              return Column(children: [
                                if(index == 0 || _publicaciones[index-1].tipo != PublicacionTipo.DISPONIBILIDAD)
                                  ...[
                                    if(index == 0)
                                      ...[
                                        if(_ultimosId['actividades_ultimo_id'] == null && _ultimoActividadIdMostrado == "")
                                          ...[
                                            const SizedBox(height: 24,),
                                            Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(horizontal: 16,),
                                              child: Text(_interesSeleccionado == null
                                                  ? "No hay actividades cerca disponibles actualmente."
                                                  : "No hay actividades cerca disponibles actualmente en ${Intereses.getNombre(_interesSeleccionado!)}.",
                                                style: const TextStyle(color: constants.blackGeneral, fontSize: 14,
                                                  height: 1.3, fontWeight: FontWeight.bold,),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 48,),
                                            Container(
                                              decoration: const BoxDecoration(color: Colors.white),
                                              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                                Divider(color: constants.greyLight, height: 0.5,),
                                                SizedBox(height: 16,),
                                              ],),
                                            ),
                                          ],

                                        if(_ultimosId['actividades_ultimo_id'] != null || _ultimoActividadIdMostrado != "")
                                          ...[
                                            Container(
                                              decoration: const BoxDecoration(color: Colors.white),
                                              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                                Divider(color: constants.greyLight, height: 0.5,),
                                                SizedBox(height: 16,),
                                              ],),
                                            ),
                                          ],
                                      ],

                                    if(index != 0)
                                      ...[
                                        Container(
                                          decoration: const BoxDecoration(color: Colors.white),
                                          child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                            Divider(color: constants.grey, height: 0.5,),
                                            SizedBox(height: 28,),
                                          ],),
                                        ),
                                      ],

                                    Container(
                                      alignment: Alignment.centerLeft,
                                      decoration: const BoxDecoration(color: Colors.white),
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 16, right: 8,),
                                        child: Text("Personas buscando actividades:",
                                          style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                                        ),
                                      ),
                                    ),
                                  ],

                                Padding(
                                  padding: const EdgeInsets.all(0),
                                  child: CardDisponibilidad(
                                    key: _indexDisponibilidadTooltip == index ? _keyDisponibilidadTooltip : null,
                                    disponibilidad: _publicaciones[index].disponibilidad!,
                                    isCreadorActividadVisible: _isCreadorActividadVisible,
                                    isAutorActividadVisible: _isAutorActividadVisible,
                                    onOpen: (){
                                      _showDialogPublicacionesJuego(index);
                                    },
                                    onChangeDisponibilidad: (Disponibilidad disponibilidad){
                                      setState(() {
                                        _publicaciones[index].disponibilidad = disponibilidad;
                                      });
                                    },
                                    showTooltipSuperlike: showTooltipSuperlike,
                                  ),
                                ),

                                if(index < (_publicaciones.length-1) && _publicaciones[index+1].tipo == PublicacionTipo.DISPONIBILIDAD)
                                  const Divider(color: constants.greyLight, height: 1, indent: 56, endIndent: 16,),

                                if(index < (_publicaciones.length-1) && _publicaciones[index+1].tipo != PublicacionTipo.DISPONIBILIDAD && _publicaciones[index+1].tipo != PublicacionTipo.SUGERENCIA_USUARIO)
                                  ...[
                                    Container(
                                      decoration: const BoxDecoration(color: Colors.white),
                                      child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                        Divider(color: constants.grey, height: 0.5,),
                                      ],),
                                    ),
                                    const SizedBox(height: 24,),
                                  ],

                                if(index == (_publicaciones.length-1))
                                  Container(
                                    decoration: const BoxDecoration(color: Colors.white),
                                    child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                      Divider(color: constants.grey, height: 0.5,),
                                    ],),
                                  ),

                              ],);

                            } else if(_publicaciones[index].tipo == PublicacionTipo.SUGERENCIA_USUARIO){

                              return Column(children: [
                                if(index == 0 || _publicaciones[index-1].tipo != PublicacionTipo.SUGERENCIA_USUARIO)
                                  ...[
                                    if(index == 0)
                                      ...[
                                        if(_ultimosId['actividades_ultimo_id'] == null && _ultimoActividadIdMostrado == "")
                                          ...[
                                            const SizedBox(height: 24,),
                                            Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(horizontal: 16,),
                                              child: Text(_interesSeleccionado == null
                                                  ? "No hay actividades cerca disponibles actualmente."
                                                  : "No hay actividades cerca disponibles actualmente en ${Intereses.getNombre(_interesSeleccionado!)}.",
                                                style: const TextStyle(color: constants.blackGeneral, fontSize: 14,
                                                  height: 1.3, fontWeight: FontWeight.bold,),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 48,),
                                            Container(
                                              decoration: const BoxDecoration(color: Colors.white),
                                              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                                Divider(color: constants.greyLight, height: 0.5,),
                                                SizedBox(height: 16,),
                                              ],),
                                            ),
                                          ],

                                        if(_ultimosId['actividades_ultimo_id'] != null || _ultimoActividadIdMostrado != "")
                                          ...[
                                            Container(
                                              decoration: const BoxDecoration(color: Colors.white),
                                              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                                Divider(color: constants.greyLight, height: 0.5,),
                                                SizedBox(height: 16,),
                                              ],),
                                            ),
                                          ],
                                      ],

                                    if(index != 0)
                                      ...[
                                        Container(
                                          decoration: const BoxDecoration(color: Colors.white),
                                          child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                            Divider(color: constants.grey, height: 0.5,),
                                            SizedBox(height: 28,),
                                          ],),
                                        ),
                                      ],

                                    Container(
                                      alignment: Alignment.centerLeft,
                                      decoration: const BoxDecoration(color: Colors.white),
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 16, right: 8,),
                                        child: Text("Sugerencias de estudiantes:",
                                          style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                                        ),
                                      ),
                                    ),
                                  ],

                                Padding(
                                  padding: const EdgeInsets.all(0),
                                  child: CardSugerenciaUsuario(
                                    sugerenciaUsuario: _publicaciones[index].sugerenciaUsuario!,
                                    isAutorActividadVisible: _isAutorActividadVisible,
                                    onOpen: (){
                                      _showDialogPublicacionesJuego(index);
                                    },
                                    onChangeSugerenciaUsuario: (SugerenciaUsuario sugerenciaUsuario){
                                      setState(() {
                                        _publicaciones[index].sugerenciaUsuario = sugerenciaUsuario;
                                      });
                                    },
                                  ),
                                ),

                                if(index < (_publicaciones.length-1) && _publicaciones[index+1].tipo == PublicacionTipo.SUGERENCIA_USUARIO)
                                  const Divider(color: constants.greyLight, height: 1, indent: 24, endIndent: 16,),

                                if(index < (_publicaciones.length-1) && _publicaciones[index+1].tipo != PublicacionTipo.SUGERENCIA_USUARIO)
                                  ...[
                                    Container(
                                      decoration: const BoxDecoration(color: Colors.white),
                                      child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                        Divider(color: constants.grey, height: 0.5,),
                                      ],),
                                    ),
                                    const SizedBox(height: 32,),
                                  ],

                                if(index == (_publicaciones.length-1))
                                  Container(
                                    decoration: const BoxDecoration(color: Colors.white),
                                    child: Column(mainAxisSize: MainAxisSize.min, children: const [
                                      Divider(color: constants.grey, height: 0.5,),
                                    ],),
                                  ),

                              ],);

                            } else {

                              return Container();

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

  bool _hasShownTooltipMatchLike = false;
  int _currentPage = 0;

  void _showDialogPublicacionesJuego(int index){
    _currentPage = index;

    StateSetter? dialogSetState;

    PageController pageController = PageController(
      viewportFraction: 0.8,
      initialPage: index,
    );

    pageController.addListener(() {
      if (pageController.position.pixels >= pageController.position.maxScrollExtent - 50) {
        if(!_loadingActividades && _verMasActividades){
          if(dialogSetState != null) _cargarActividades(dialogSetState!);
        }
      }

      final int page = pageController.page?.round() ?? 0;
      if (page != _currentPage && pageController.position.haveDimensions) {
        setState(() {
          _currentPage = page;
        });
      }
    });

    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        dialogSetState = setStateDialog;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            //height: MediaQuery.of(context).size.height * 0.8,
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: pageController,
              itemCount: !_loadingActividades ? _publicaciones.length : _publicaciones.length + 1, // +1 mostrar cargando
              itemBuilder: (context, index) {

                if(_loadingActividades && index == _publicaciones.length){
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16,),
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _buildLoadingActividades(),
                  );
                }

                return AnimatedBuilder(
                  animation: pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (pageController.position.haveDimensions) {
                      value = pageController.page! - index;
                      value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                    }

                    if(_publicaciones[index].tipo == PublicacionTipo.DISPONIBILIDAD){
                      return Opacity(
                        opacity: value,
                        child: ScrollsnapCardDisponibilidad(
                          disponibilidad: _publicaciones[index].disponibilidad!,
                          isAutorActividadVisible: _isAutorActividadVisible,
                          onNextItem: (){
                            pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,);
                          },
                          onChangeDisponibilidad: (Disponibilidad disponibilidad){
                            setState(() {
                              _publicaciones[index].disponibilidad = disponibilidad;
                            });
                          },
                        ),
                      );
                    }

                    if(_publicaciones[index].tipo == PublicacionTipo.SUGERENCIA_USUARIO){
                      return Opacity(
                        opacity: value,
                        child: ScrollsnapCardSugerenciaUsuario(
                          sugerenciaUsuario: _publicaciones[index].sugerenciaUsuario!,
                          isAutorActividadVisible: _isAutorActividadVisible,
                          onNextItem: (){
                            pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,);
                          },
                          onChangeSugerenciaUsuario: (SugerenciaUsuario sugerenciaUsuario){
                            setState(() {
                              _publicaciones[index].sugerenciaUsuario = sugerenciaUsuario;
                            });
                          },
                        ),
                      );
                    }

                    if(_publicaciones[index].tipo == PublicacionTipo.ACTIVIDAD){
                      bool showTooltipMatchLike = !_hasShownTooltipMatchLike && _currentPage == index;
                      if (showTooltipMatchLike) {
                        _hasShownTooltipMatchLike = true;
                      }

                      return Opacity(
                        opacity: value,
                        child: ScrollsnapCardActividad(
                          actividad: _publicaciones[index].actividad!,
                          onNextItem: (){
                            pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,);
                          },
                          onChangeActividad: (Actividad actividad){
                            setState(() {
                              _publicaciones[index].actividad = actividad;
                            });
                          },
                          showTooltipMatchLike: showTooltipMatchLike,
                        ),
                      );
                    }

                    return Container();
                  },
                );
              },
            ),
          ),
        );
      });
    }).then((value) {
      //pageController.dispose();
      dialogSetState = null;
      setState(() {});
    });
  }

  Future<void> _verificarNotificacionesPush() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
      if(settings.authorizationStatus != AuthorizationStatus.authorized){

        // Permisos para iOS y para Android 13+
        NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
        if(settings.authorizationStatus != AuthorizationStatus.authorized){
          // Si los permisos están denegados, siempre va enviar historial

          // Envia historial del usuario
          _enviarHistorialUsuario(HistorialUsuario.getHomeNotificaciones(false));

        } else {
          // Envia historial del usuario
          _enviarHistorialUsuario(HistorialUsuario.getHomeNotificaciones(true));
        }
      }
    } catch(e){
      // Captura error, por si surge algun posible error con FirebaseMessaging
    }
  }

  Future<void> _mostrarInteresesYTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    _usuarioSesionFoto = usuarioSesion.foto;

    // Muestra los intereses en orden
    List<String> listIntereses = Intereses.getListaIntereses();
    listIntereses.forEach((element) {
      if(usuarioSesion.interesesId.contains(element)){
        _intereses.add(element);
      }
    });

    setState(() {});


    // Muestra pantalla Tutorial a los usuarios nuevos que no lo vieron (se muestra hasta que presione "Comenzar")
    bool isShowed = prefs.getBool(SharedPreferencesKeys.isShowedScreenSignupTutorial) ?? true; // Por defecto si lo vieron, para versiones anteriores de la app
    if(!isShowed){
      _showDialogComoFunciona(isFromTutorial: true,);
    }
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

    _previsualizacionActividades = [];

    setState(() {});

    _permissionStatus = await _locationService.verificarUbicacion();
    if(_permissionStatus == LocationServicePermissionStatus.permitted){

      _locationServicePosition = await _locationService.obtenerUbicacion();
      _cargarActividades(setState);

    } else {
      _loadingActividades = false;
      setState(() {});
    }
  }

  Future<void> _cargarActividades(StateSetter setStateActual) async {
    setStateActual(() {
      _loadingActividades = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    if(usuarioSesion.interesesId.isEmpty){
      _showDialogCambiarIntereses();
      _isActividadesPermitido = false; // Puede que si tenga permitido, si acepto ser cocreador y nunca eligió sus intereses
      setStateActual(() {_loadingActividades = false;});
      return;
    }
    //String interesesIdString = usuarioSesion.interesesId.join(",");

    // Si no tiene un interes seleccionado, muestra todos los intereses
    String interesesIdString = _interesSeleccionado ?? Intereses.getListaIntereses().join(",");

    // Se usa POST porque envia datos privados (ubicacion)
    var response = await HttpService.httpPost(
      url: constants.urlHomeVerActividades,
      body: {
        "ultimos_id": _ultimosId,
        "intereses": interesesIdString,
        "ubicacion_latitud": _locationServicePosition?.latitude.toString() ?? "",
        "ubicacion_longitud": _locationServicePosition?.longitude.toString() ?? ""
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

            List<ActividadCreador> creadores = [];
            actividadDatos['creadores'].forEach((usuario) {
              creadores.add(ActividadCreador(
                id: usuario['id'],
                nombre: usuario['nombre'],
                nombreCompleto: usuario['nombre_completo'],
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
              isLiked: actividadDatos['like'] == "SI",
              likesCount: actividadDatos['likes_count'],
              creadores: creadores,
              ingresoEstado: Actividad.getActividadIngresoEstadoFromString(actividadDatos['ingreso_estado']),
              isAutor: actividadDatos['autor_usuario_id'] == usuarioSesion.id,
              isMatchLiked: actividadDatos['is_match_liked'],
              isMatch: actividadDatos['is_match'],
              distanciaTexto: actividadDatos['distancia_texto'],
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
                descripcion: disponibilidadDatos['creador']['descripcion'],
                universidadNombre: disponibilidadDatos['creador']['universidad_nombre'],
                isVerificadoUniversidad: disponibilidadDatos['creador']['is_verificado_universidad'],
                verificadoUniversidadNombre: disponibilidadDatos['creador']['verificado_universidad_nombre'],
                isMatchLiked: disponibilidadDatos['creador']['is_match_liked'],
                isMatch: disponibilidadDatos['creador']['is_match'],
                isSuperliked: disponibilidadDatos['creador']['is_superliked'],
              ),
              texto: disponibilidadDatos['texto'],
              fecha: disponibilidadDatos['fecha_texto'],
              isAutor: disponibilidadDatos['creador']['id'] == usuarioSesion.id,
              distanciaTexto: disponibilidadDatos['distancia_texto'],
            );
          }

          SugerenciaUsuario? sugerenciaUsuario;
          if(element['sugerencia_usuario'] != null){
            var sugerenciaUsuarioDatos = element['sugerencia_usuario'];

            sugerenciaUsuario = SugerenciaUsuario(
              id: sugerenciaUsuarioDatos['id'],
              nombre: sugerenciaUsuarioDatos['nombre'],
              nombreCompleto: sugerenciaUsuarioDatos['nombre_completo'],
              username: sugerenciaUsuarioDatos['username'],
              foto: constants.urlBase + sugerenciaUsuarioDatos['foto_url'],
              universidadNombre: sugerenciaUsuarioDatos['universidad_nombre'],
              isVerificadoUniversidad: sugerenciaUsuarioDatos['is_verificado_universidad'],
              verificadoUniversidadNombre: sugerenciaUsuarioDatos['verificado_universidad_nombre'],
              isMatchLiked: sugerenciaUsuarioDatos['is_match_liked'],
              isMatch: sugerenciaUsuarioDatos['is_match'],
              isSuperliked: sugerenciaUsuarioDatos['is_superliked'],
            );
          }

          _publicaciones.add(Publicacion(
            tipo: Publicacion.getPublicacionTipoFromString(element['tipo']),
            actividad: actividad,
            disponibilidad: disponibilidad,
            sugerenciaUsuario: sugerenciaUsuario,
          ));
        }

        _isActividadesPermitido = datosJson['is_permitido_ver_actividades'];
        _isCreadorActividadVisible = datosJson['is_creador_actividad_visible'];
        _isAutorActividadVisible = datosJson['is_autor_actividad_visible'];

        if(!_isActividadesPermitido && datosJson['previsualizacion_actividades'] != null){
          List<dynamic> previsualizacionActividades = datosJson['previsualizacion_actividades'];
          for (var element in previsualizacionActividades) {

            List<PrevisualizacionActividadCreador> creadores = [];
            element['creadores'].forEach((creador) {
              creadores.add(PrevisualizacionActividadCreador(
                nombre: creador['nombre'],
                foto: constants.urlBase + creador['foto_url'],
              ));
            });

            PrevisualizacionActividad previsualizacionActividad = PrevisualizacionActividad(
              titulo: element['titulo'],
              fecha: element['fecha_texto'],
              fechaCompleto: element['fecha'].toString(),
              creadores: creadores,
            );

            _previsualizacionActividades.add(previsualizacionActividad);

          }
        }

        _lastTimeCargarActividades = DateTime.now();


        // Tooltip de ayuda a los usuarios nuevos para enviar match like a actividad.
        _hasShownTooltipMatchLike = prefs.getBool(SharedPreferencesKeys.isShowedAyudaActividadMatchLike) ?? false;

        // Tooltip de ayuda a los usuarios nuevos para enviar superlike desde disponibilidad.
        _hasShownTooltipSuperlike = prefs.getBool(SharedPreferencesKeys.isShowedAyudaDisponibilidadSuperlike) ?? false;

      } else {

        if(datosJson['error_tipo'] == 'ubicacion_no_disponible'){
          _isActividadesPermitido = true;
          _isCiudadDisponible = false;
          //_showDialogCiudadNoDisponible();
        } else if(datosJson['error_tipo'] == 'intereses_vacio'){
          _showDialogCambiarIntereses();
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    } else {
      // Se produjo en el error en el servidor (por ej. Error 500). No quitar "cargando" o mostrar un mensaje en toda la pantalla.
      _showSnackBar("Se produjo un error");
      return;
    }

    setStateActual(() {
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
              Text("Lo sentimos, actualmente Tenfo no está disponible en tu ciudad.",
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

            // Se muestran tarjetas vacias si no existe _previsualizacionActividades[i]
            for (int i=0; i<5; i++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                height: i < _previsualizacionActividades.length ? null : 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: constants.grey),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 24,),
                child: Column(children: [
                  Row(
                    children: [
                      Text(i < _previsualizacionActividades.length ? _previsualizacionActividades[i].fecha : "",
                        style: const TextStyle(color: constants.greyLight, fontSize: 12,),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.end,
                  ),
                  const SizedBox(height: 24,),
                  Align(
                    alignment: Alignment.center,
                    child: Text(i < _previsualizacionActividades.length ? _previsualizacionActividades[i].titulo : "",
                      style: const TextStyle(color: constants.blackGeneral, fontSize: 18, height: 1.3,),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40,),
                  if(i < _previsualizacionActividades.length)
                    Row(children: [
                      SizedBox(
                        width: (15 * _previsualizacionActividades[i].creadores.length) + 10,
                        height: 20,
                        child: Stack(
                          children: [
                            Container(),
                            for (int j=(_previsualizacionActividades[i].creadores.length-1); j>=0; j--)
                              Positioned(
                                left: (15 * j).toDouble(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: constants.greyLight, width: 0.5,),
                                  ),
                                  height: 20,
                                  width: 20,
                                  child: CircleAvatar(
                                    backgroundColor: const Color(0xFFFAFAFA),
                                    backgroundImage: CachedNetworkImageProvider(_previsualizacionActividades[i].creadores[j].foto),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(_previsualizacionCocreadoresTexto(_previsualizacionActividades[i]),
                          style: const TextStyle(color: constants.grey, fontSize: 12,),
                          maxLines: 1,
                        ),
                      ),
                    ],),
                ], crossAxisAlignment: CrossAxisAlignment.start,),
              ),

          ], crossAxisAlignment: CrossAxisAlignment.stretch,),)
        ),
      ),

      Positioned.fill(child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.6),
            ],
            stops: const [0.1, 0.8],
          ),
        ),
        child: BackdropFilter(
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
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12,),
              child: Column(children: [

                const Text("Accede con tu estado o actividad para desbloquear lo que otros están compartiendo.",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24,),

                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  child: ElevatedButton.icon(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const CrearDisponibilidadPage(isFromHome: true,),
                      ));
                    },
                    icon: const Icon(Icons.add_rounded, size: 18,),
                    label: const Text("Acceder", style: TextStyle(fontSize: 16,),),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                  ),
                ),

                const SizedBox(height: 16,),

                TextButton(
                  onPressed: (){
                    _showDialogComoFunciona();
                  },
                  child: const Text("Cómo funciona", style: TextStyle(fontSize: 14,),),
                  style: TextButton.styleFrom(
                    primary: constants.blackGeneral,
                  ),
                ),

              ], mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,),
            ),
          )),
        ),
      )),

    ]);
  }

  String _previsualizacionCocreadoresTexto(PrevisualizacionActividad previsualizacionActividad){
    String creadoresNombre = "";

    if(previsualizacionActividad.creadores.length == 1){

      creadoresNombre = previsualizacionActividad.creadores[0].nombre;

    } else if(previsualizacionActividad.creadores.length >= 1){

      creadoresNombre = previsualizacionActividad.creadores[0].nombre;
      for(int i = 1; i < (previsualizacionActividad.creadores.length-1); i++){
        creadoresNombre += ", "+previsualizacionActividad.creadores[i].nombre;
      }
      creadoresNombre += " y "+previsualizacionActividad.creadores[previsualizacionActividad.creadores.length-1].nombre;

    }

    return creadoresNombre;
  }

  void _showDialogComoFunciona({bool isFromTutorial = false}){
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context){
        return SingleChildScrollView(child: Container(
          height: !isFromTutorial
              ? null
              : MediaQuery.of(context).size.height
                - MediaQuery.of(context).padding.top
                - MediaQuery.of(context).padding.bottom
                - kToolbarHeight,
          padding: const EdgeInsets.only(left: 16, top: 32, right: 16, bottom: 32,),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              const Text("¿Cómo funciona Tenfo? 👋",
                style: TextStyle(color: constants.blackGeneral, fontSize: 20,),
              ),

              const SizedBox(height: 32,),

              const Align(
                alignment: Alignment.center,
                child: Text("Publica una actividad o estado para desbloquear lo que otros están compartiendo.",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                  textAlign: TextAlign.left,
                ),
              ),

              const SizedBox(height: 56,),

              Row(children: [
                Container(
                  width: 50,
                  child: const Icon(Icons.groups),
                ),
                Expanded(child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: constants.blackGeneral, fontSize: 15, height: 1.3,),
                    children: [
                      TextSpan(
                        text: "Actividad:",
                        style: TextStyle(color: constants.blackGeneral, fontWeight: FontWeight.bold, fontSize: 16,),
                      ),
                      TextSpan(
                        text: " Sugiere o invita a realizar una actividad y otros usuarios pueden unirse en un chat grupal.",
                      )
                    ],
                  ),
                ),),
              ], crossAxisAlignment: CrossAxisAlignment.start,),

              const SizedBox(height: 48,),

              Row(children: [
                Container(
                  width: 50,
                  child: const Icon(Icons.person),
                ),
                Expanded(child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: constants.blackGeneral, fontSize: 15, height: 1.3,),
                    children: [
                      TextSpan(
                        text: "Estado:",
                        style: TextStyle(color: constants.blackGeneral, fontWeight: FontWeight.bold, fontSize: 16,),
                      ),
                      TextSpan(
                        text: " Indica que solo estás viendo actividades para unirte.",
                      )
                    ],
                  ),
                ),),
              ], crossAxisAlignment: CrossAxisAlignment.start,),

              const SizedBox(height: 56,),

              const Align(
                alignment: Alignment.center,
                child: Text("Todas las publicaciones desaparecen después de 48 horas, obteniendo más espontaneidad y privacidad 😊.",
                  style: TextStyle(color: constants.blackGeneral,),
                  textAlign: TextAlign.left,
                ),
              ),

              if(!isFromTutorial)
                ...[
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Entendido"),
                  ),
                ],

              if(isFromTutorial)
                ...[
                  const SizedBox(height: 32,),
                  Container(
                    constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (){
                        // No muestra el tutorial cuando vuelva a abrir la app
                        SharedPreferences.getInstance().then((prefs){
                          prefs.setBool(SharedPreferencesKeys.isShowedScreenSignupTutorial, true);
                        });

                        Navigator.pop(context);
                      },
                      child: const Text("Comenzar"),
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                    ),
                  ),
                ],
            ],
          ),
        ));
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0),),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildActividadesVacio(){

    if(!_isCiudadDisponible){
      return Container(
        alignment: Alignment.center,
        // Lo hace ver más centrado (bottom es una altura aproximada de la seccion "Intereses")
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 64,),
        margin: const EdgeInsets.symmetric(vertical: 24,),
        child: const Text("Lo sentimos, Tenfo no está disponible en tu ciudad o zona. 🙁\n\n"
            "Actualmente, estamos en CABA (Buenos Aires) y alrededores. Pronto estaremos en más lugares.\n\n"
            "¡Síguenos en redes para las novedades!",
          style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      // Lo hace ver más centrado (bottom es una altura aproximada de la seccion "Intereses")
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 64,),
      child: Text(_interesSeleccionado == null
          ? "No hay actividades cerca disponibles actualmente."
          : "No hay actividades cerca disponibles actualmente en ${Intereses.getNombre(_interesSeleccionado!)}.",
        style: const TextStyle(color: constants.blackGeneral, fontSize: 16,),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSeccionInteresesTabs(){
    List<String> intereses = Intereses.getListaIntereses();

    return SliverPadding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8,),
      sliver: SliverToBoxAdapter(
        child: Container(
          alignment: Alignment.centerLeft,
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: intereses.length + 1,
            shrinkWrap: true,
            itemBuilder: (context, index){
              if(index == 0){
                return _buildTabInteres(null);
              }

              index = index - 1;

              return _buildTabInteres(intereses[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabInteres(String? interesId){
    // Si interesId es null, es "Para ti" (todos los intereses)

    return Column(children: [
      InkWell(
        onTap: (){
          String? actualInteresId = _interesSeleccionado;

          setState(() {
            _interesSeleccionado = interesId;
          });

          if(interesId != actualInteresId){
            _recargarActividades();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          margin: const EdgeInsets.only(right: 8,),
          height: 28,
          decoration: BoxDecoration(
            color: interesId == _interesSeleccionado ? Colors.grey : Colors.transparent,
            border: Border.all(color: constants.grey, width: 0.5,),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            if(interesId != null)
              ...[
                Intereses.getIcon(interesId, size: 14, color: interesId == _interesSeleccionado ? Colors.white : null,),
                const SizedBox(width: 4,),
              ],
            Text(interesId == null ? "Para ti" : Intereses.getNombre(interesId),
              style: TextStyle(color: interesId == _interesSeleccionado ? Colors.white : constants.blackGeneral, fontSize: 12,),
            ),
          ], mainAxisSize: MainAxisSize.min,),
        ),
      ),
    ], mainAxisAlignment: MainAxisAlignment.center,);
  }

  Widget _buildSeccionIntereses(){
    return SliverPadding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 16,),
      sliver: SliverToBoxAdapter(
        child: Container(
          alignment: Alignment.centerLeft,
          height: 75,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _intereses.length + 1,
            shrinkWrap: true,
            itemBuilder: (context, index){
              if(index == _intereses.length){
                return _buildInteresCambiar();
              }

              return _buildInteres(Intereses.getNombre(_intereses[index]), Intereses.getIcon(_intereses[index], size: 18,));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInteres(String texto, Icon icon){
    return Container(
      width: 56,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: constants.grey),
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          const SizedBox(height: 4,),
          Text(texto, style: const TextStyle(fontSize: 10),)
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
  }

  Widget _buildInteresCambiar(){
    return Container(
      padding: const EdgeInsets.only(bottom: 14,),
      child: IconButton(
        onPressed: (){
          _showDialogCambiarIntereses();
        },
        icon: const Icon(Icons.settings_suggest_rounded, color: constants.blackGeneral, size: 28,),
        padding: const EdgeInsets.all(0),
      ),
    );
  }

  void _showDialogCambiarIntereses(){
    showDialog(context: context, builder: (context) {
      return DialogCambiarIntereses(intereses: _intereses, onChanged: (nuevosIntereses){
        _intereses = nuevosIntereses;
        setState(() {});

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

    _permissionStatus = LocationServicePermissionStatus.permitted;
    setState(() {});

    _recargarActividades();
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
    if(mounted){
      setState(() {});
    }
    await Future.delayed(const Duration(seconds: 5,));
    _isAvailableTooltipUnirse = false;
    if(mounted){
      setState(() {});
    }
  }

  void setShowBadgeNotificaciones(bool value){
    setState(() {
      _showBadgeNotificaciones = value;
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