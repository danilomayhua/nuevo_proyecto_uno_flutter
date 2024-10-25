import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/actividad_requisito.dart';
import 'package:tenfo/models/actividad_sugerencia_titulo.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/sugerencia_usuario.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_cocreador_pendiente.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/actividad/actividad_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/services/location_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/intereses.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/utilities/share_utils.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:tenfo/widgets/dialog_cambiar_intereses.dart';

class CrearActividadPage extends StatefulWidget {
  const CrearActividadPage({Key? key, this.cocreadorUsuario,
    this.fromDisponibilidad, this.fromSugerenciaUsuario, this.fromPantalla}) : super(key: key);

  final Usuario? cocreadorUsuario;
  final Disponibilidad? fromDisponibilidad;
  final SugerenciaUsuario? fromSugerenciaUsuario;
  final CrearActividadFromPantalla? fromPantalla;

  @override
  State<CrearActividadPage> createState() => _CrearActividadPageState();
}

enum ActividadTipo { publico, privado, requisitos }

// Es importante no cambiar los nombres de este enum (se envian al backend)
enum CrearActividadFromPantalla { card_disponibilidad, scrollsnap_disponibilidad, card_sugerencia_usuario, scrollsnap_sugerencia_usuario }

class _CrearActividadPageState extends State<CrearActividadPage> {
  final PageController _pageController = PageController();
  int _pageCurrent = 0;

  final GlobalKey<State<Tooltip>> _keyTooltipSugerencias = GlobalKey();
  bool _enabledTooltipSugerencias = false;

  List<String> _intereses = [];
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  bool _loadingActividadSugerenciasTitulo = false;
  List<ActividadSugerenciaTitulo> _actividadSugerenciasTitulo = [];
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedInteresId;

  List<UsuarioCocreadorPendiente> _creadores = [];
  List<Usuario> _creadoresBusqueda = [];
  String _textoBusqueda = "";
  bool _loadingCreadoresBusqueda = false;
  bool _dialogCreadoresIsOpen = false;
  Timer? _timer;
  bool _enviandoCrearInvitacion = false;

  List<Contact> _telefonoContactos = [];
  List<Contact> _filteredTelefonoContactos = [];

  String? _invitacionCodigo;
  bool _enviandoGenerarInvitacionCodigo = false;
  String _numeroGenerarInvitacionCodigo = "";

  final List<String> _stringActividadTipo = ["Público","Privado","Requisitos"];
  ActividadTipo? _actividadTipo = ActividadTipo.publico;
  String _actividadTipoSelected = "Público";
  List<ActividadRequisito> _requisitoPreguntas = [];
  bool _preguntaNueva = false;
  final TextEditingController _preguntaNuevaController = TextEditingController();
  String _errorTextPreguntas = '';

  bool _enviando = false;

  final LocationService _locationService = LocationService();
  LocationServicePermissionStatus _permissionStatus = LocationServicePermissionStatus.loading;
  LocationServicePosition? _locationServicePosition;

  List<Map<String, dynamic>> _historialesUsuario = [];
  bool _isEnviadoHistorialesUsuario = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      // Muestra los intereses en orden
      List<String> listIntereses = Intereses.getListaIntereses();
      listIntereses.forEach((element) {
        /*if(usuarioSesion.interesesId.contains(element)){
          _intereses.add(element);
        }*/

        // Muestra todos los intereses
        _intereses.add(element);
      });

      setState(() {});

      if(_intereses.isEmpty) _showDialogCambiarIntereses();
      if(_intereses.isNotEmpty){
        setState(() {
          _selectedInteresId = _intereses[0]; // Selecciona el primer interes por defecto
        });
        _cargarActividadSugerenciasTitulo(_intereses[0]); // Muestra opciones con el primer interes por defecto
      }


      // Muestra tooltip de sugerencias a los usuarios nuevos (se muestra hasta que presione en un interes y cargue nuevas sugerencias)
      bool isShowed = prefs.getBool(SharedPreferencesKeys.isShowedAyudaCrearActividadSugerencias) ?? false;
      if(!isShowed){
        setState(() {
          _enabledTooltipSugerencias = true;
        });
        _showAndCloseTooltipSugerencias();
      }

    });
    _titleController.text = '';
    _descriptionController.text = '';

    _pageController.addListener(() {
      if(_pageController.page != null && _pageCurrent != _pageController.page!.toInt()){
        _pageCurrent = _pageController.page!.toInt();
        setState(() {});
      }
    });

    _obtenerUbicacion();

    if(widget.cocreadorUsuario != null){
      _creadores.add(UsuarioCocreadorPendiente(
        tipo: UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE,
        usuario: widget.cocreadorUsuario,
      ));
    }

    //_cargarTelefonoContactos();
    _buscarUsuario("", setState);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Scaffold(
      appBar: AppBar(
        title: Text(widget.cocreadorUsuario != null ? "Cocrear actividad" : "Crear actividad"),
        leading: IconButton(
          icon: _pageCurrent == 0 ? const Icon(Icons.clear) : const BackButtonIcon(),
          onPressed: (){
            _handleBack();

            if(_pageCurrent == 0){
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(children: [
        Expanded(child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index){
            WidgetsBinding.instance?.focusManager.primaryFocus?.unfocus();
          },
          children: [
            SingleChildScrollView(
              child: contenidoUno(),
            ),
            contenidoDos(),
          ],
        )),
        /*
        if(_pageCurrent == 0)
          ...[
            GestureDetector(
              child: const Text("¿Quién podrá ver esta actividad?",
                style: TextStyle(color: constants.grey, fontSize: 12, decoration: TextDecoration.underline,),
              ),
              onTap: (){
                _showDialogAyudaActividadVisible();
              },
            ),
            const SizedBox(height: 8,),
          ],
         */
      ]),),
    );

    return WillPopScope(
      child: child,
      onWillPop: (){
        _handleBack();

        if(_pageCurrent == 0){
          // Posiblemente esto no funcione en iOS y no cierre CrearActividad (onWillPop tiene que ser null para que funcione)
          // En ese caso _handleBack() se podria llamar repetidamente con _pageCurrent en 0
          return Future.value(true);
        } else {
          return Future.value(false);
        }
      },
    );
  }

  void _handleBack(){
    if(_pageCurrent == 0){
      // Envia historial del usuario cuando cancela CrearActividad
      _enviarHistorialesUsuario();
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showDialogAyudaActividadVisible(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("La actividad estará visible durante 48 horas solamente.\n\n"
                "Solo las personas cercanas a tu ubicación que hayan creado una actividad en las últimas 48 horas podrán verla.",
              style: TextStyle(color: constants.blackGeneral,),
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

  Widget contenidoUno(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(children: [
        TextField(
          focusNode: _titleFocusNode,
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: "¿Qué actividad tienes en mente?",
            hintStyle: TextStyle(fontWeight: FontWeight.normal,),
            //labelText: "Título",
            //floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(),
            counterText: "",
          ),
          maxLength: 200,
          minLines: 1,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontWeight: FontWeight.bold,),
        ),

        const SizedBox(height: 16,),

        Row(children: [
          InkWell(
            child: const Icon(Icons.cached),
            onTap: (){
              if(_selectedInteresId != null && !_loadingActividadSugerenciasTitulo){
                _cargarActividadSugerenciasTitulo(_selectedInteresId!, isFromReload : true,);
              }
            },
          ),
          const SizedBox(width: 4,),
          const Text("Sugerencias:", textAlign: TextAlign.left,
            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
          ),
        ],),
        const SizedBox(height: 8,),
        Container(
          alignment: Alignment.centerLeft,
          height: 75,
          child: _loadingActividadSugerenciasTitulo ? const CircularProgressIndicator() : ListView.builder(itemBuilder: (context, index){

            return InkWell(
              onTap: (){
                if(_actividadSugerenciasTitulo[index].requiereCompletar){
                  _titleController.text = _actividadSugerenciasTitulo[index].texto + ' ';

                  _titleFocusNode.requestFocus();
                  _titleController.selection = TextSelection.collapsed(offset: _titleController.text.length);
                } else {
                  _titleController.text = _actividadSugerenciasTitulo[index].texto;

                  _titleFocusNode.unfocus();
                }
                setState(() {});
              },
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8,),
                decoration: BoxDecoration(
                  border: Border.all(color: constants.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(_actividadSugerenciasTitulo[index].requiereCompletar
                    ? (_actividadSugerenciasTitulo[index].texto + '...') : _actividadSugerenciasTitulo[index].texto,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 4,
                ),
              ),
            );

          }, scrollDirection: Axis.horizontal, itemCount: _actividadSugerenciasTitulo.length, shrinkWrap: true,),
        ),
        const SizedBox(height: 8,),

        /*
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            isDense: true,
            labelText: "Descripción detallada (opcional)",
            counterText: '',
            border: OutlineInputBorder(),
          ),
          maxLength: 1300,
          minLines: 1,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 12,),
        ),
        */

        const SizedBox(height: 24,),

        Row(children: [
          const Text("Categoría:", textAlign: TextAlign.left,
            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
          ),
          const SizedBox(width: 4,),
          if(_enabledTooltipSugerencias && _intereses.isNotEmpty)
            Tooltip(
              key: _keyTooltipSugerencias,
              triggerMode: TooltipTriggerMode.manual,
              message: "Presiona en una categoría para\ncambiar las sugerencias\nmostradas", // Tiene saltos de linea para modificar el ancho
              preferBelow: false,
              verticalOffset: 18,
              padding: const EdgeInsets.all(8),
              decoration: ShapeDecoration(
                shape: _CustomShapeBorder(), // Forma personalizada
                color: Colors.grey[700]?.withOpacity(0.9),
              ),
              child: Container(
                width: 32,
                height: 32,
                /*child: IconButton(
                  onPressed: (){
                    _showTooltipSugerencias();
                  },
                  icon: const Icon(Icons.help_outline, color: constants.grey,),
                  padding: const EdgeInsets.all(0),
                ),*/
              ),
            ),
        ],),
        const SizedBox(height: 8,),
        Container(
          alignment: Alignment.centerLeft,
          height: 70,
          child: ListView.builder(itemBuilder: (context, index){

            /*if(index == _intereses.length){
              return InkWell(
                onTap: (){
                  _showDialogCambiarIntereses();
                },
                child: Container(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 14,),
                    child: const Icon(Icons.settings_suggest_rounded, color: constants.blackGeneral, size: 28,),
                ),
              );
            }*/

            return GestureDetector(
              onTap: (){
                String? actualInteresId = _selectedInteresId;

                setState(() {
                  _selectedInteresId = _intereses[index];
                });

                if(_intereses[index] != actualInteresId){
                  _cargarActividadSugerenciasTitulo(_intereses[index]);

                  // Si estaba mostrando el tooltip, ya no lo muestra las siguientes veces
                  if(_enabledTooltipSugerencias){
                    SharedPreferences.getInstance().then((prefs){
                      prefs.setBool(SharedPreferencesKeys.isShowedAyudaCrearActividadSugerencias, true);
                    });
                  }
                }
              },
              child: Container(
                width: 56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _selectedInteresId == _intereses[index] ? Colors.black12 : Colors.transparent,
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
                        child: Intereses.getIcon(_intereses[index], size: 16,)
                    ),
                    const SizedBox(height: 4,),
                    Text(Intereses.getNombre(_intereses[index]), style: TextStyle(fontSize: 10),)
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
              ),
            );

          }, scrollDirection: Axis.horizontal, itemCount: _intereses.length, shrinkWrap: true,),
        ),

        const SizedBox(height: 24,),

        Row(
          children: [
            const Text("Tipo:", style: TextStyle(color: constants.blackGeneral, fontSize: 12,),),
            const SizedBox(width: 8,),
            OutlinedButton(
              onPressed: () => _mostrarDialogTipos(),
              child: Text(_actividadTipoSelected, style: const TextStyle(fontSize: 12,)),
              style: OutlinedButton.styleFrom(
                primary: constants.blackGeneral,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24,),

        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (){
              _validarContenidoUno();
            },
            child: const Text("Siguiente"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),
        /*const SizedBox(height: 8,),
        const Text("Paso 1 de 2",
          style: TextStyle(color: constants.grey, fontSize: 12,),
        ),*/

        const SizedBox(height: 32,),
      ],),
    );
  }

  Widget contenidoDos(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(children: [
        /*
        Container(
          width: double.infinity,
          child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              style: TextStyle(color: constants.blackGeneral),
              text: "¿Quién más crea la actividad?",
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: (){
                        _showDialogAyudaCreadores();
                      },
                      icon: Icon(Icons.help_outline, color: constants.grey,),
                      padding: EdgeInsets.all(0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if(_creadores.isNotEmpty)
          for(int i = 0; i<_creadores.length; i++)
            _buildCocredor(i, _creadores[i]),

        const SizedBox(height: 8,),

        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: (){
              if(_creadores.length >= 3){
                _showSnackBar("Solo se pueden añadir tres(3) cocreadores");
              } else {
                _showDialogCreadores();
              }
            },
            icon: const Icon(Icons.add, size: 18,),
            label: const Text("Añadir cocreadores", style: TextStyle(fontSize: 12,)),
            style: OutlinedButton.styleFrom(
              primary: constants.blackGeneral,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),

        const SizedBox(height: 24,),
        */

        Container(
          alignment: Alignment.centerLeft,
          child: const Text("Selecciona amigos para crear la actividad en grupo",
            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
            textAlign: TextAlign.left,
          ),
        ),

        const SizedBox(height: 16,),

        TextField(
          decoration: const InputDecoration(
            isDense: true,
            hintText: "Buscar...",
            counterText: '',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8,),
          ),
          maxLength: 200,
          minLines: 1,
          maxLines: 1,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14,),
          onChanged: (text){
            if(text == _textoBusqueda){
              return;
            }
            _textoBusqueda = text;


            setState(() {
              _filteredTelefonoContactos = _telefonoContactos
                  .where((contact) => contact.displayName.toLowerCase().contains(text.toLowerCase()))
                  .toList();
            });


            _timer?.cancel();

            setState(() {
              _loadingCreadoresBusqueda = true;
            });

            _timer = Timer(const Duration(milliseconds: 500), (){
              _buscarUsuario(text, setState);
            });
          },
        ),

        Flexible(child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320,),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _creadoresBusqueda.length + 1, // 1 listas y 1 texto cabecera
            //itemCount: _creadoresBusqueda.length + 1 + _filteredTelefonoContactos.length + 1, // 2 listas y 2 texto cabecera
            itemBuilder: (context, index){
              if(index == 0){
                return _buildCabeceraAmigos();
              }

              // Al buscar un contacto, quita los resultados anteriores
              if(_loadingCreadoresBusqueda) return Container();

              return _buildUsuarioBusqueda(_creadoresBusqueda[index - 1]);

              /*
              if (index < _creadoresBusqueda.length + 1) {
                // Al buscar un contacto, quita los resultados anteriores
                if(_loadingCreadoresBusqueda) return Container();

                return _buildUsuarioBusqueda(_creadoresBusqueda[index - 1]);
              }

              if (index == _creadoresBusqueda.length + 1) {
                return _buildCabeceraTelefonoContactos();
              }

              return _buildTelefonoContacto(_filteredTelefonoContactos[index - _creadoresBusqueda.length - 2]);
              */
            },
            padding: const EdgeInsets.only(bottom: 24,),
          ),
        )),

        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _enviando ? null : () => _validarContenidoDos(),
            child: const Text("Crear actividad"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),
        /*const SizedBox(height: 8,),
        const Text("Paso 2 de 2",
          style: TextStyle(color: constants.grey, fontSize: 12,),
        ),*/

        const SizedBox(height: 16,),

        Container(
          alignment: Alignment.centerLeft,
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _creadores.length + 1,
            shrinkWrap: true,
            itemBuilder: (context, index){
              if(index == 0){
                // Si no tiene creadores agregados, no muestra el texto
                if(_creadores.isEmpty) return Container();

                return Container(
                  alignment: Alignment.center,
                  child: const Text("Cocreadores:",
                    style: TextStyle(color: constants.grey, fontSize: 12,),
                    textAlign: TextAlign.left,
                  ),
                );
              }

              index = index - 1;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4,),
                padding: const EdgeInsets.symmetric(horizontal: 4,),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: constants.grey, width: 0.5,),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: constants.greyBackgroundImage,
                      backgroundImage: CachedNetworkImageProvider(_creadores[index].usuario!.foto),
                      radius: 12,
                    ),
                    const SizedBox(width: 4,),
                    Text(_creadores[index].usuario!.username, style: const TextStyle(fontSize: 10),),
                    const SizedBox(width: 4,),
                    GestureDetector(
                      onTap: (){
                        setState(() {
                          _creadores.removeAt(index);
                        });
                      },
                      child: const Icon(Icons.close, color: constants.blackGeneral, size: 18,),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],),
    );
  }

  Widget _buildCabeceraAmigos(){
    return Column(children: [
      Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(top: 16, bottom: 12,),
        child: const Text("Amigos",
          style: TextStyle(color: constants.grey, fontSize: 12,),
        ),
      ),

      if(_loadingCreadoresBusqueda)
        ...[
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: const CircularProgressIndicator(),
          ),
        ],

      if(!_loadingCreadoresBusqueda && _creadoresBusqueda.isEmpty)
        ...[
          const SizedBox(height: 24,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16,),
            child: const Text("No hay resultados",
              style: TextStyle(color: constants.blackGeneral, fontSize: 12,
                height: 1.3, fontWeight: FontWeight.bold,),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24,),
        ],
    ],);
  }

  Widget _buildCabeceraTelefonoContactos(){
    return Column(children: [
      /*Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
        child: Row(children: [
          const Text("Contactos",
            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
          ),
          const Spacer(),
          Text("Invitaciones ${(_totalInvitaciones <= 5) ? _totalInvitaciones : 5}/5",
            style: const TextStyle(color: constants.blueGeneral, fontSize: 12, fontWeight: FontWeight.bold,),
          ),
        ],),
      ),*/
      Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(top: 16, bottom: 12,),
        child: const Text("Contactos",
          style: TextStyle(color: constants.grey, fontSize: 12,),
        ),
      ),

      //if(_telefonoContactos.isNotEmpty && _filteredTelefonoContactos.isEmpty)
      if(_filteredTelefonoContactos.isEmpty)
        ...[
          const SizedBox(height: 24,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16,),
            child: const Text("No hay resultados encontrados",
              style: TextStyle(color: constants.blackGeneral, fontSize: 12,
                height: 1.3, fontWeight: FontWeight.bold,),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24,),
        ],
    ],);
  }

  Widget _buildUsuarioBusqueda(Usuario usuario){
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12,),
      title: Text(usuario.nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(usuario.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: CachedNetworkImageProvider(usuario.foto),
      ),
      onTap: (){
        for(int i = 0; i < _creadores.length; i++){
          if(_creadores[i].usuario?.id == usuario.id){
            setState(() {
              _creadores.removeAt(i);
            });
            return;
          }
        }

        if(_creadores.length >= 3){
          _showSnackBar("Solo se pueden añadir tres(3) cocreadores");
          return;
        }

        setState(() {
          _creadores.add(UsuarioCocreadorPendiente(
            tipo: UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE,
            usuario: usuario,
          ));
        });
      },
      trailing: _creadores.any((creador) => creador.usuario?.id == usuario.id)
          ? const Icon(Icons.check_box_outlined, color: constants.blackGeneral,)
          : const Icon(Icons.check_box_outline_blank, color: constants.blackGeneral,),
    );
  }

  Widget _buildTelefonoContacto(Contact contact){
    Phone? phone = contact.phones.isNotEmpty ? contact.phones.first : null;
    String primeraLetra = contact.displayName.substring(0, 1).toUpperCase();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12,),
      title: Text(contact.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        child: Text(primeraLetra,
          style: const TextStyle(color: constants.blackGeneral, fontSize: 18, fontWeight: FontWeight.bold,),
        ),
      ),
      trailing: OutlinedButton(
        onPressed: !_enviandoGenerarInvitacionCodigo
            ? () => _enviarInvitacionCodigo(phone?.number ?? "")
            : (_numeroGenerarInvitacionCodigo == (phone?.number ?? ""))
              ? null
              : (){},
        child: const Text("Invitar", style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          primary: constants.blackGeneral,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8,),
        ),
      ),
    );
  }

  Widget _buildCocredor(index, UsuarioCocreadorPendiente cocreador){

    String titulo = "";
    String subtitulo = "";

    if(cocreador.tipo == UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE){
      titulo = cocreador.usuario!.nombre;
      subtitulo = cocreador.usuario!.username;
    } else {
      titulo = "Invitado externo";
      subtitulo = "Código: " + (cocreador.invitacionCodigo?.split('').join(' ') ?? "");
    }

    return ListTile(
      dense: true,
      title: Text(titulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: cocreador.tipo == UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE
            ? null : const TextStyle(fontStyle: FontStyle.italic),
      ),
      subtitle: Text(subtitulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: cocreador.tipo == UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE
            ? CachedNetworkImageProvider(cocreador.usuario!.foto) : null,
        child: cocreador.tipo == UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE
            ? null : const Icon(Icons.group, color: constants.blackGeneral,),
      ),
      onTap: cocreador.tipo == UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE ? null : (){
        ShareUtils.shareActivityCocreatorCode(
          cocreador.invitacionCodigo!,
          _titleController.text.trim(),
        );
      },
      trailing: IconButton(
        onPressed: (){
          if(cocreador.tipo == UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE){
            setState(() {
              _creadores.removeAt(index);
            });
          } else {
            _showDialogEliminarCocreador((){
              setState(() {
                _creadores.removeAt(index);
              });
            });
          }
        },
        icon: const Icon(Icons.cancel_outlined, color: constants.blackGeneral,),
      ),
    );
  }

  void _showDialogCambiarIntereses(){
    showDialog(context: context, builder: (context) {
      return DialogCambiarIntereses(intereses: _intereses, onChanged: (nuevosIntereses){
        _intereses = nuevosIntereses;

        Navigator.of(context).pop();

        setState(() {
          _selectedInteresId = _intereses[0]; // Selecciona el primer interes por defecto
        });
        _cargarActividadSugerenciasTitulo(_intereses[0]); // Muestra opciones con el primer interes por defecto
      },);
    });
  }

  Future<void> _cargarActividadSugerenciasTitulo(String interesId, { bool isFromReload = false }) async {
    setState(() {
      _loadingActividadSugerenciasTitulo = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    String enviadoDesde = "seleccionar_interes";
    if(isFromReload) enviadoDesde = "recargar";

    var response = await HttpService.httpGet(
      url: constants.urlActividadSugerenciasTitulo,
      queryParams: {
        "interes_id": interesId,
        "enviado_desde": enviadoDesde
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        if(interesId != _selectedInteresId){
          // Cambio de interes mientras cargaba sugerencias (se mostraran las sugerencias del nuevo interes)
          return;
        }

        _actividadSugerenciasTitulo.clear();

        List<dynamic> actividadSugerenciasTitulo = datosJson['data']['actividad_sugerencias_titulo'];
        for (var element in actividadSugerenciasTitulo) {
          _actividadSugerenciasTitulo.add(ActividadSugerenciaTitulo(
            texto: element['texto'],
            requiereCompletar: element['requiere_completar'],
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingActividadSugerenciasTitulo = false;
    });
  }

  Future<void> _obtenerUbicacion() async {
    LocationServicePermissionStatus status = await _locationService.verificarUbicacion();

    if(status == LocationServicePermissionStatus.permitted){
      // Actualiza el valor a "permitted" cuando obtiene la ubicacion
      try {

        _locationServicePosition = await _locationService.obtenerUbicacion();
        _permissionStatus = LocationServicePermissionStatus.permitted;

      } catch (e){
        _permissionStatus = LocationServicePermissionStatus.notPermitted;
      }
    } else {
      _permissionStatus = status;
    }
  }

  Future _showAndCloseTooltipSugerencias() async {
    await Future.delayed(const Duration(milliseconds: 500,));
    dynamic tooltip = _keyTooltipSugerencias.currentState; // Es dynamic para que tome la funcion ensureTooltipVisible
    tooltip?.ensureTooltipVisible();
    await Future.delayed(const Duration(seconds: 4));
    tooltip?.deactivate();
  }

  Future _showTooltipSugerencias() async {
    await Future.delayed(const Duration(milliseconds: 10)); // Necesario para que no se cierre al momento de mostrar
    dynamic tooltip = _keyTooltipSugerencias.currentState; // Es dynamic para que tome la funcion ensureTooltipVisible
    tooltip?.ensureTooltipVisible();
  }

  Future<void> _cargarTelefonoContactos() async {
    //_loadingContactosSugerencias = true;
    //setState(() {});


    //_isPermisoTelefonoContactos = true;

    final PermissionStatus permissionStatus = await Permission.contacts.status;
    if(!permissionStatus.isGranted){
      //_isPermisoTelefonoContactos = false;

      //_loadingContactosSugerencias = false;
      //setState(() {});
      return;
    }


    _telefonoContactos = await FlutterContacts.getContacts(withProperties: true,);
    _filteredTelefonoContactos = _telefonoContactos;


    //_loadingContactosSugerencias = false;
    setState(() {});
  }

  void _validarContenidoUno(){
    if(_intereses.isEmpty){
      _showSnackBar("Primero debes seleccionar tus intereses");
      return;
    }

    if(_titleController.text.trim() == ''){
      _showSnackBar("El contenido está vacío");
      return;
    }

    if(_selectedInteresId == null){
      _showSnackBar("Selecciona a qué categoría pertenece");
      return;
    }

    if(_permissionStatus != LocationServicePermissionStatus.permitted){
      if(_permissionStatus == LocationServicePermissionStatus.loading){
        _showSnackBar("Obteniendo ubicación. Espere...");
      }

      if(_permissionStatus == LocationServicePermissionStatus.serviceDisabled){
        // TODO : Deberia volver a comprobar por si los activo después de recibir el aviso
        _showSnackBar("Tienes los servicios de ubicación deshabilitados. Actívalo desde Ajustes.");
      }

      if(_permissionStatus == LocationServicePermissionStatus.notPermitted){
        _showSnackBar("Debes habilitar la ubicación en Inicio para poder crear actividades.");
      }

      return;
    }

    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // Agrega historial del usuario
    _agregarHistorialUsuario(HistorialUsuario.getCrearActividadPasoDos());
  }

  void _showDialogAyudaCreadores(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("¿Qué son los cocreadores?",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 16,),
            Text("Los cocreadores son tus amigos cercanos con quienes puedes organizar y crear actividades en conjunto.\n"
                "Todos se mostrarán enlistados como cocreadores de la actividad y tendrán permisos de administrador en el chat grupal.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
              textAlign: TextAlign.left,
            ),

            SizedBox(height: 24,),

            Text("¿Por qué agregar cocreadores?",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 16,),
            Text("Agregar cocreadores a tus actividades puede hacerlas más atractivas y amigables.\n"
                "Cuando una actividad cuenta con varios cocreadores, fomenta a más personas a unirse y participar.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 24,),

            Text("¿Cómo funciona?",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 16,),
            Text("Cuando añades a alguien como cocreador, esta persona será notificada y deberá confirmar ser cocreador de la actividad.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
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

    // Agrega historial del usuario
    _agregarHistorialUsuario(HistorialUsuario.getCrearActividadCocreadoresInformacion());
  }

  void _showDialogCreadores(){
    _creadoresBusqueda = [];
    _loadingCreadoresBusqueda = false;
    String textoBusqueda = "";

    showDialog(context: context, builder: (context){

      _dialogCreadoresIsOpen = true;

      return StatefulBuilder(builder: (context, setStateDialog){
        return AlertDialog(
          content: Container(
            width: MediaQuery.of(context).size.width - 80,
            child: Column(children: [
              TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: "Buscar usuario...",
                  counterText: '',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8,),
                ),
                maxLength: 200,
                minLines: 1,
                maxLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 14,),
                onChanged: (text){

                  if(text == textoBusqueda){
                    return;
                  }
                  textoBusqueda = text;


                  _timer?.cancel();

                  setStateDialog(() {
                    _loadingCreadoresBusqueda = true;
                  });

                  _timer = Timer(const Duration(milliseconds: 500), (){
                    _buscarUsuario(text, setStateDialog);
                  });
                },
              ),
              const SizedBox(height: 8,),

              if(_creadoresBusqueda.isNotEmpty)
                ...[
                  const Text("Presiona sobre un usuario para añadirlo",
                    style: TextStyle(color: constants.grey, fontSize: 12,),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8,),
                ],

              Expanded(
                child: _loadingCreadoresBusqueda
                    ? const Center(child: CircularProgressIndicator())
                    : _creadoresBusqueda.isEmpty
                      ? Center(child: Column(children: [

                        const Spacer(),
                        if(textoBusqueda.isNotEmpty)
                          const Text("No hay resultados",
                            style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                          ),
                        const Spacer(),

                        /*
                        ElevatedButton.icon(
                          onPressed: _enviandoCrearInvitacion ? null : () {

                            _crearInvitacionCocreadorExterno(setStateDialog);

                            // Podria lanzar urls directas
                            // Uri url = Uri.parse("whatsapp://send?text=Probando un mensaje");
                            // Uri url = Uri.parse("instagram://sharesheet?text=Probandounmensaje"); // No funciona, capaz ya lo sacaron
                          },
                          icon: const Icon(Icons.share, size: 18,),
                          label: const Text("Invitar amigo",
                            style: TextStyle(fontSize: 12,),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                        ),
                        const SizedBox(height: 8,),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: constants.grey, fontSize: 12,),
                            text: "Comparte un código con tus amigos fuera de la app y se agregarán como cocreador. ",
                            children: [
                              TextSpan(
                                text: "Más información.",
                                style: const TextStyle(decoration: TextDecoration.underline,),
                                recognizer: TapGestureRecognizer()..onTap = (){
                                  _showDialogAyudaCreadorExterno();
                                },
                              ),
                            ],
                          ),
                        ),
                        */
                      ], mainAxisSize: MainAxisSize.min,),)

                      : ListView.builder(
                        itemCount: _creadoresBusqueda.length,
                        itemBuilder: (context, index) => ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(left: 0.0, right: 0.0),
                          title: Text(_creadoresBusqueda[index].nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(_creadoresBusqueda[index].username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: constants.greyBackgroundImage,
                            backgroundImage: CachedNetworkImageProvider(_creadoresBusqueda[index].foto),
                          ),
                          onTap: (){
                            for(var creador in _creadores){
                              if(creador.usuario?.id == _creadoresBusqueda[index].id){
                                _creadoresBusqueda.clear();
                                Navigator.of(context).pop();
                                return;
                              }
                            }
                            setState(() {
                              _creadores.add(UsuarioCocreadorPendiente(
                                tipo: UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE,
                                usuario: _creadoresBusqueda[index],
                              ));
                              _creadoresBusqueda.clear();
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
              ),

            ],),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
          ],
        );
      });
    }).then((value) => _dialogCreadoresIsOpen = false);

    // Agrega historial del usuario
    _agregarHistorialUsuario(HistorialUsuario.getCrearActividadBuscador());
  }

  Future<void> _buscarUsuario(String texto, setStateDialog) async {
    setStateDialog(() {
      _loadingCreadoresBusqueda = true;
    });

    // Permite enviar texto vacio
    /*
    if(texto.trim() == ''){
      _creadoresBusqueda.clear();
      setStateDialog(() {_loadingCreadoresBusqueda = false;});
      return;
    }
    */

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlActividadBuscadorCocreador,
      queryParams: {
        "texto": texto
      },
      usuarioSesion: usuarioSesion,
    );

    List<dynamic>? usuarios;
    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _creadoresBusqueda.clear();

        usuarios = datosJson['data']['usuarios'];
        for (var element in usuarios!) {
          _creadoresBusqueda.add(Usuario(
            id: element['id'],
            nombre: element['nombre_completo'],
            username: element['username'],
            foto: constants.urlBase + element['foto_url'],
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _loadingCreadoresBusqueda = false;
    });


    if(texto.trim() != ''){
      // Agrega historial del usuario
      List<String>? usuariosId = usuarios?.map<String>((element) => element['id']).toList();
      _agregarHistorialUsuario(HistorialUsuario.getCrearActividadBuscadorResultado(texto, usuariosId));
    }
  }

  void _enviarInvitacionCodigo(String phoneNumber){
    if(_creadores.length >= 3){
      _showSnackBar("Solo se pueden añadir tres(3) cocreadores");
      return;
    }

    _enviandoGenerarInvitacionCodigo = true;
    _numeroGenerarInvitacionCodigo = phoneNumber;

    if(_invitacionCodigo != null){

      String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), ''); // Elimina cualquier caracter que no sea un digito del numero
      ShareUtils.shareActivityCocreatorWhatsappNumber(cleanedPhoneNumber, _invitacionCodigo!);

      // Agrega historial del usuario
      _agregarHistorialUsuario(HistorialUsuario.getCrearActividadCocreadoresInvitarAmigo(phoneNumber));

      _enviandoGenerarInvitacionCodigo = false;
      _numeroGenerarInvitacionCodigo = "";
      setState(() {});

    } else {
      _generarInvitacionCodigo(phoneNumber);
    }
  }

  Future<void> _generarInvitacionCodigo(String phoneNumber) async {
    setState(() {
      _enviandoGenerarInvitacionCodigo = true;
      _numeroGenerarInvitacionCodigo = phoneNumber;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadCrearInvitacionCreador,
      body: {},
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _invitacionCodigo = datosJson['data']['invitacion_codigo'];

        String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), ''); // Elimina cualquier caracter que no sea un digito del numero
        ShareUtils.shareActivityCocreatorWhatsappNumber(cleanedPhoneNumber, _invitacionCodigo!);

        // Agrega historial del usuario
        _agregarHistorialUsuario(HistorialUsuario.getCrearActividadCocreadoresInvitarAmigo(phoneNumber));

      } else {

        if(datosJson['error_tipo'] == 'limite_codigos'){
          _showSnackBar("Ya has generado el máximo de códigos permitidos para hoy.");
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoGenerarInvitacionCodigo = false;
      _numeroGenerarInvitacionCodigo = "";
    });
  }

  void _showDialogAyudaCreadorExterno(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("Invita a tus amigos que aún no tienen la app para colaborar contigo en una actividad.\n\n"
                "Esto creará un código para tu invitado, donde al ingresarlo, será agregado automáticamente como cocreador de esta actividad.\n\n"
                "Si tu amigo no tiene un correo de los permitidos para registrarse, podrá registrarse igualmente y se restará de tus invitaciones directas que tienes disponibles.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
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

    // Agrega historial del usuario
    _agregarHistorialUsuario(HistorialUsuario.getCrearActividadBuscadorCodigoInformacion());
  }

  Future<void> _crearInvitacionCocreadorExterno(setStateDialog) async {
    setStateDialog(() {
      _enviandoCrearInvitacion = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlActividadCodigoCocreadorExterno,
      queryParams: {},
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        String codigoInvitacion = datosJson['data']['codigo'];

        if(_dialogCreadoresIsOpen) {
          Navigator.of(context).pop();
        }

        ShareUtils.shareActivityCocreatorCode(codigoInvitacion, _titleController.text.trim());

        _creadores.add(UsuarioCocreadorPendiente(
          tipo: UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE_EXTERNO,
          invitacionCodigo: codigoInvitacion,
        ));

      } else {
        if(_dialogCreadoresIsOpen) {
          Navigator.of(context).pop();
        }

        if(datosJson['error_tipo'] == 'limite_codigos'){
          _showSnackBar("Ya has generado el máximo de códigos permitidos para hoy.");
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    _enviandoCrearInvitacion = false; // Actualizar afuera, por si ya no existe setStateDialog
    setState(() {});
    setStateDialog(() {});
  }

  void _showDialogEliminarCocreador(void Function() onAccept){
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text('¿Seguro que quieres eliminar al invitado externo?'),
        content: const Text('Si compartiste el código, ya no podrá ser usado.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Eliminar'),
            style: TextButton.styleFrom(
              primary: constants.redAviso,
            ),
            onPressed: (){
              onAccept();
              Navigator.pop(context);
            },
          ),
        ],
      );
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
              Expanded(child: Text("Los usuarios que se unan a la actividad enviarán una solicitud, y alguno de los cocreadores (tú) debe aceptar para que entren al chat grupal.",
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
              Expanded(child: Text("Se crea un cuestionario con las respuestas requeridas. El usuario que se una tiene que contestar un cuestionario. "
                  "Si lo que responda coincide con las respuestas requeridas, el usuario entra automáticamente al chat grupal.",
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

  void _mostrarDialogTipos(){
    if(_actividadTipoSelected == _stringActividadTipo[0]){
      _actividadTipo = ActividadTipo.publico;
    } else if(_actividadTipoSelected == _stringActividadTipo[1]){
      _actividadTipo = ActividadTipo.privado;
    } else if(_actividadTipoSelected == _stringActividadTipo[2]) {
      _actividadTipo = ActividadTipo.requisitos;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context){
        return StatefulBuilder(
          builder: (context, setStateDialog){
            return Container(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[

                  const SizedBox(height: 24,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16,),
                    child: Row(children: [
                      SizedBox(
                        width: 56,
                        child: Text("Privado:",
                          style: TextStyle(fontSize: 12, color: constants.blackGeneral,
                            fontWeight: _actividadTipo == ActividadTipo.privado ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      const Expanded(child: Text("Para unirse a la actividad, los usuarios deben enviar una solicitud y ser aprobados por ti o por alguno de los cocreadores.",
                        style: TextStyle(fontSize: 12, color: constants.grey),
                      ),),
                    ], crossAxisAlignment: CrossAxisAlignment.start,),
                  ),
                  const SizedBox(height: 8,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16,),
                    child: Row(children: [
                      SizedBox(
                        width: 56,
                        child: Text("Público:",
                          style: TextStyle(fontSize: 12, color: constants.blackGeneral,
                            fontWeight: _actividadTipo == ActividadTipo.publico ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      const Expanded(child: Text("Cualquier usuario puede unirse a la actividad y entrar automáticamente al chat grupal.",
                        style: TextStyle(fontSize: 12, color: constants.grey),
                      ),),
                    ], crossAxisAlignment: CrossAxisAlignment.start,),
                  ),
                  const SizedBox(height: 24,),

                  RadioListTile<ActividadTipo>(
                    title: Text(_stringActividadTipo[1]),
                    value: ActividadTipo.privado,
                    groupValue: _actividadTipo,
                    onChanged: (ActividadTipo? value) {
                      _actividadTipo = value;
                      _actividadTipoSelected = _stringActividadTipo[1];
                      setStateDialog(() {});
                      setState(() {});
                    },
                  ),
                  RadioListTile<ActividadTipo>(
                    title: Text(_stringActividadTipo[0]),
                    value: ActividadTipo.publico,
                    groupValue: _actividadTipo,
                    onChanged: (ActividadTipo? value) {
                      _actividadTipo = value;
                      _actividadTipoSelected = _stringActividadTipo[0];
                      setStateDialog(() {});
                      setState(() {});
                    },
                  ),
                  /*RadioListTile<ActividadTipo>(
                    title: Text(_stringActividadTipo[2]),
                    value: ActividadTipo.requisitos,
                    groupValue: _actividadTipo,
                    onChanged: (ActividadTipo? value) {
                      _actividadTipo = value;
                      _actividadTipoSelected = _stringActividadTipo[2];
                      setStateDialog(() {});
                      setState(() {});
                    },
                  ),*/
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Continuar"),
                  ),
                ],
              ),
            );
          },
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0),),
      ),
    );
  }

  void _showDialogPreguntas(){
    showDialog(context: context, builder: (context){
      return StatefulBuilder(builder: (context, setStateDialog){
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text("Debes añadir minino una(1) pregunta. Las preguntas deben ser con respuestas SI/NO.",
                  style: TextStyle(color: constants.grey, fontSize: 12,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16,),

                for(int i = 0; i < _requisitoPreguntas.length; i++)
                  Column(children: [
                    Row(children: [
                      Expanded(child: Text(_requisitoPreguntas[i].pregunta,
                        style: TextStyle(color: constants.blackGeneral,),
                      ),),
                      IconButton(
                        onPressed: (){
                          _requisitoPreguntas.removeAt(i);
                          _limpiarErrorTextPreguntas(setStateDialog);
                        },
                        icon: const Icon(Icons.cancel),
                      ),
                    ],),
                    Row(children: [
                      const Text("Respuesta correcta:",
                        style: TextStyle(fontSize: 12, color: constants.blackGeneral,),
                      ),
                      Row(children: [
                        Radio<ActividadRequisitoRepuesta>(
                          value: ActividadRequisitoRepuesta.SI,
                          groupValue: _requisitoPreguntas[i].respuesta,
                          onChanged: (ActividadRequisitoRepuesta? value) {
                            setStateDialog(() {
                              _requisitoPreguntas[i].respuesta = value;
                              _limpiarErrorTextPreguntas(setStateDialog);
                            });
                          },
                        ),
                        Text("Si", style: TextStyle(fontSize: 12, color: constants.blackGeneral,),),
                      ],),
                      Row(children: [
                        Radio<ActividadRequisitoRepuesta>(
                          value: ActividadRequisitoRepuesta.NO,
                          groupValue: _requisitoPreguntas[i].respuesta,
                          onChanged: (ActividadRequisitoRepuesta? value) {
                            setStateDialog(() {
                              _requisitoPreguntas[i].respuesta = value;
                              _limpiarErrorTextPreguntas(setStateDialog);
                            });
                          },
                        ),
                        Text("No", style: TextStyle(fontSize: 12, color: constants.blackGeneral,),),
                      ],),
                    ],),
                    const SizedBox(height: 16,),
                  ],),

                if(_preguntaNueva)
                  Row(children: [
                    Expanded(child: TextField(
                      autofocus: true,
                      controller: _preguntaNuevaController,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: "Escribe una pregunta...",
                        counterText: '',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8,),
                      ),
                      maxLength: 80,
                      minLines: 1,
                      maxLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(fontSize: 12,),
                    ),),
                    TextButton(
                      onPressed: (){
                        _agregarPreguntaNueva(setStateDialog);
                      },
                      child: Text("Añadir"),
                    ),
                  ],),
                if(_preguntaNueva)
                  const SizedBox(height: 16,),

                if(_errorTextPreguntas != '')
                  Text(_errorTextPreguntas,
                    style: const TextStyle(color: constants.redAviso, fontSize: 12,),
                    textAlign: TextAlign.center,
                  ),
                if(_errorTextPreguntas != '')
                  const SizedBox(height: 16,),

                OutlinedButton.icon(
                  onPressed: (){
                    if(_requisitoPreguntas.length >= 5){
                      _errorTextPreguntas = "No puedes agregar más de 5 preguntas";
                    } else {
                      _preguntaNueva = true;
                    }
                    setStateDialog(() {});
                  },
                  icon: Icon(Icons.add, size: 18,),
                  label: Text("Añadir pregunta nueva", style: TextStyle(fontSize: 12,)),
                  style: OutlinedButton.styleFrom(
                    primary: constants.blackGeneral,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: (){
                _agregarPreguntaNueva(setStateDialog);
                _verificarPreguntas(setStateDialog);
              },
              child: const Text("Listo"),
            ),
          ],
        );
      });
    });
  }

  void _agregarPreguntaNueva(setStateDialog){
    if(_preguntaNuevaController.text.trim() != ''){
      _requisitoPreguntas.add(ActividadRequisito(pregunta: _preguntaNuevaController.text));
    }
    _preguntaNuevaController.text = '';
    _preguntaNueva = false;
    setStateDialog(() {});
  }

  void _limpiarErrorTextPreguntas(setStateDialog){
    _errorTextPreguntas = '';
    setStateDialog(() {});
  }

  void _verificarPreguntas(setStateDialog){
    bool error = false;

    for(var requisitoPregunta in _requisitoPreguntas){
      if(requisitoPregunta.respuesta == ActividadRequisitoRepuesta.SIN_RESPONDER){
        error = true;
        _errorTextPreguntas = "Por favor agrega una respuesta a todas las preguntas";
        break;
      }
    }

    if(error){
      setStateDialog(() {});
    } else {
      _limpiarErrorTextPreguntas(setStateDialog);
      Navigator.of(context).pop();
    }
  }

  void _validarContenidoDos(){
    if(_actividadTipo == ActividadTipo.requisitos){

      if(_requisitoPreguntas.isEmpty){
        _showSnackBar("La actividad es de tipo Requisitos, debes agregar mínimo una(1) pregunta.");
        return;
      }

      for(var requisitoPregunta in _requisitoPreguntas){
        if(requisitoPregunta.respuesta == ActividadRequisitoRepuesta.SIN_RESPONDER){
          _showSnackBar("Debes agregar una respuesta a cada pregunta");
          return;
        }
      }
    }

    _enviarActividad();
  }

  Future<void> _showDialogConfirmarCrearActividad() async {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text('¿Estás seguro de que deseas crear la actividad sin añadir cocreadores?',
          style: TextStyle(fontSize: 16,),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Crear actividad'),
            onPressed: (){
              _enviarActividad();
              Navigator.pop(context);
            },
          ),
        ],
      );
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(SharedPreferencesKeys.isShowedAyudaCrearActividadCocreadores, true);
  }

  Future<void> _enviarActividad() async {
    setState(() {
      _enviando = true;
    });


    ActividadPrivacidadTipo actividadPrivacidadTipo;
    if(_actividadTipo == ActividadTipo.privado){
      actividadPrivacidadTipo = ActividadPrivacidadTipo.PRIVADO;
    } else if(_actividadTipo == ActividadTipo.requisitos){
      actividadPrivacidadTipo = ActividadPrivacidadTipo.REQUISITOS;
    } else {
      actividadPrivacidadTipo = ActividadPrivacidadTipo.PUBLICO;
    }


    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    /*
    // Muestra el dialog a los usuarios nuevos (se muestra solo una vez)
    bool isShowed = prefs.getBool(SharedPreferencesKeys.isShowedAyudaCrearActividadCocreadores) ?? false;
    if(!isShowed && _creadores.isEmpty){
      _showDialogConfirmarCrearActividad();
      setState(() {_enviando = false;});
      return;
    }
    */

    List<Usuario> creadoresUsuario = [];
    List<String> creadoresId = [];
    List<String> creadoresExternoCodigo = [];
    for(UsuarioCocreadorPendiente usuarioCocreadorPendiente in _creadores){
      if(usuarioCocreadorPendiente.tipo == UsuarioCocreadorPendienteTipo.CREADOR_PENDIENTE){
        creadoresUsuario.add(usuarioCocreadorPendiente.usuario!);
        creadoresId.add(usuarioCocreadorPendiente.usuario!.id);
      } else {
        creadoresExternoCodigo.add(usuarioCocreadorPendiente.invitacionCodigo!);
      }
    }

    var response = await HttpService.httpPost(
      url: constants.urlCrearActividad,
      body: {
        "titulo": _titleController.text.trim(),
        "descripcion": _descriptionController.text.trim(),
        "interes_id": _selectedInteresId,
        "privacidad_tipo": Actividad.getActividadPrivacidadTipoToString(actividadPrivacidadTipo),
        "creadores": creadoresId,
        "creadores_externos_codigo": creadoresExternoCodigo,
        "ubicacion_latitud": _locationServicePosition?.latitude.toString() ?? "",
        "ubicacion_longitud": _locationServicePosition?.longitude.toString() ?? "",
        "invitacion_codigo": _invitacionCodigo,

        // Envia historial del usuario para analizar comportamiento
        "historiales_usuario_activo": _historialesUsuario,
        "datos_enviado_desde": (widget.fromDisponibilidad == null && widget.fromSugerenciaUsuario == null)
            ? null
            : {
              "disponibilidad_id" : widget.fromDisponibilidad?.id,
              "sugerencia_usuario_id" : widget.fromSugerenciaUsuario?.id,
              "pantalla" : widget.fromPantalla?.name,
            },
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        var datosActividad = datosJson['data']['actividad'];

        Navigator.push(context, MaterialPageRoute(
            builder: (context) => ActividadPage(
              actividad: Actividad(
                id: datosActividad['id'],
                titulo: datosActividad['titulo'],
                descripcion: datosActividad['descripcion'],
                fecha: datosActividad['fecha_texto'],
                privacidadTipo: Actividad.getActividadPrivacidadTipoFromString(datosActividad['privacidad_tipo']),
                interes: datosActividad['interes_id'].toString(),
                isLiked: datosActividad['like'] == "SI",
                likesCount: datosActividad['likes_count'],
                creadores: [ActividadCreador(
                  id: usuarioSesion.id,
                  nombre: usuarioSesion.nombre,
                  nombreCompleto: usuarioSesion.nombre_completo,
                  username: usuarioSesion.username,
                  foto: usuarioSesion.foto,
                )],
                ingresoEstado: Actividad.getActividadIngresoEstadoFromString(datosActividad['ingreso_estado']),
                isAutor: true,
              ),
              reload: false,
              creadoresPendientes: creadoresUsuario,
              creadoresPendientesExternosCodigo: creadoresExternoCodigo,
              invitacionCodigo: _invitacionCodigo,
              fromDisponibilidad: widget.fromDisponibilidad,
            )
        )).then((value) => {

          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (context) => const PrincipalPage()
          ), (root) => false)

        });

      } else {

        if(datosJson['error_tipo'] == 'ubicacion_no_disponible'){
          _showSnackBar("Lo sentimos, actualmente Tenfo no está disponible en tu ciudad.");
        } else if(datosJson['error_tipo'] == 'titulo'){
          _showSnackBar("El contenido de la actividad no es válido.");
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviando = false;
    });
  }

  void _agregarHistorialUsuario(Map<String, dynamic> nuevoHistorial){
    // Agrega historial si tiene menos de 20 items.
    // Si tiene 20 items o más, solo lo agrega si no existe el evento.

    if(_historialesUsuario.length < 20){
      _historialesUsuario.add(nuevoHistorial);
    } else {
      if(!HistorialUsuario.containsEvento(_historialesUsuario, nuevoHistorial)){
        _historialesUsuario.add(nuevoHistorial);
      }
    }
  }

  Future<void> _enviarHistorialesUsuario() async {
    //setState(() {});

    if(_historialesUsuario.isEmpty || _isEnviadoHistorialesUsuario) return;

    // Evita que se envie más de una vez (puede generarse por posible error con WillPopScope en iOS)
    _isEnviadoHistorialesUsuario = true;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCrearHistorialUsuarioActivo,
      body: {
        "historiales_usuario_activo": _historialesUsuario,
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
      ..moveTo(rect.left + rect.width / 2 - 10, rect.bottom)
      ..lineTo(rect.left + rect.width / 2, rect.bottom + 10)
      ..lineTo(rect.left + rect.width / 2 + 10, rect.bottom);

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return _CustomShapeBorder();
  }
}