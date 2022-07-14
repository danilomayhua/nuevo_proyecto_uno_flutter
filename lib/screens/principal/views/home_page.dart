import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/models/actividad.dart';
import 'package:nuevoproyectouno/models/actividad_requisito.dart';
import 'package:nuevoproyectouno/models/chat.dart';
import 'package:nuevoproyectouno/models/checkbox_item_intereses.dart';
import 'package:nuevoproyectouno/models/usuario.dart';
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/screens/buscador/buscador_page.dart';
import 'package:nuevoproyectouno/services/http_service.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:nuevoproyectouno/utilities/intereses.dart';
import 'package:nuevoproyectouno/utilities/shared_preferences_keys.dart';
import 'package:nuevoproyectouno/widgets/card_actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _intereses = [];
  List<Widget> _interesesIcons = [];
  List<CheckboxItemIntereses> _listInteresesCheckbox = [];
  bool _enviandoIntereses = false;

  List<Actividad> _actividades = [];

  ScrollController _scrollController = ScrollController();
  bool _loadingActividades = false;
  bool _verMasActividades = false;
  String _ultimoActividades = "false";

  @override
  void initState() {
    super.initState();

    _mostrarIntereses();

    _loadingActividades = false;
    _verMasActividades = false;
    _ultimoActividades = "false";

    _cargarActividades();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingActividades && _verMasActividades){
          _cargarActividades();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Actividades"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => BuscadorPage()));
            },
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.only(left: 8, top: 24, right: 8, bottom: 8),
            sliver: SliverToBoxAdapter(
              child: Text("Mis intereses: ",
                style: TextStyle(color: constants.blackGeneral,),
              ),
            ),
          ),
          _buildSeccionIntereses(),
          (!_loadingActividades && _actividades.length == 0)
              ? SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text("No hay actividades relacionadas con tus intereses disponibles.",
                    style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index){

                  if(index == _actividades.length){
                    return _buildLoadingActividades();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    child: CardActividad(actividad: _actividades[index]),
                  );
                }, childCount: _actividades.length + 1)),
              ),
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

  void _recargarActividades(){
    _loadingActividades = false;
    _verMasActividades = false;
    _ultimoActividades = "false";

    _actividades = [];
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    setState(() {
      _loadingActividades = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    String interesesIdString = usuarioSesion.interesesId.join(",");

    var response = await HttpService.httpGet(
      url: constants.urlHomeActividades,
      queryParams: {
        "ultimo_id": _ultimoActividades,
        "intereses": interesesIdString
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

        /*for(var i = 0; i < 15; i++){
          String titulo = "Practiquemos ingles $i";
          String interes = "2";
          String fecha = "hace 3 min";

          String descripcion = "";

          ActividadPrivacidadTipo privacidadTipo = ActividadPrivacidadTipo.PUBLICO;
          ActividadIngresoEstado ingresoEstado = ActividadIngresoEstado.NO_INTEGRANTE;

          List<Usuario> creadores = [
            Usuario(id: "23", nombre: "Armando Casas", username: "armandocasas", foto: "https://cdn.pixabay.com/photo/2018/07/12/12/28/dog-3533300_960_720.jpg")
          ];
          bool isAutor = false;

          List<ActividadRequisito> requisitosPreguntas = [];
          bool requisitosEnviado = false;

          if(i == 1){

            privacidadTipo = ActividadPrivacidadTipo.REQUISITOS;
            ingresoEstado = ActividadIngresoEstado.INTEGRANTE;
            isAutor = true;

            requisitosPreguntas = [
              ActividadRequisito(pregunta: "¿Cursas en UADE?"),
              ActividadRequisito(pregunta: "¿Podrias juntarte zona norte?"),
              ActividadRequisito(pregunta: "¿Sos programador avanzado?"),
            ];

          } else if(i == 4){
            privacidadTipo = ActividadPrivacidadTipo.REQUISITOS;

            requisitosPreguntas = [
              ActividadRequisito(pregunta: "¿Cursas en UADE?"),
              ActividadRequisito(pregunta: "¿Podrias juntarte zona norte?"),
              ActividadRequisito(pregunta: "¿Sos programador avanzado?"),
            ];

          } else if(i == 8){

            privacidadTipo = ActividadPrivacidadTipo.REQUISITOS;

            requisitosPreguntas = [
              ActividadRequisito(pregunta: "¿Cursas en UADE?"),
              ActividadRequisito(pregunta: "¿Podrias juntarte zona norte?"),
              ActividadRequisito(pregunta: "¿Sos programador avanzado?"),
            ];
            requisitosEnviado = true;

          }

          _actividades.add(Actividad(
            id: (i + 1).toString(),
            titulo: titulo,
            descripcion: descripcion,
            fecha: fecha,
            privacidadTipo: privacidadTipo,
            interes: interes,
            creadores: creadores,
            ingresoEstado: ingresoEstado,
            isAutor: isAutor,
            requisitosPreguntas: requisitosPreguntas,
            requisitosEnviado: requisitosEnviado,
          ));
        }*/

      } else {

        if(datosJson['error_tipo'] == 'intereses_vacio'){
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

  Widget _buildSeccionIntereses(){
    return SliverPadding(
      padding: EdgeInsets.only(left: 8, /*top: 24,*/ right: 8, bottom: 16),
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
    _intereses.forEach((String element) {
      _interesesIcons.add(_buildInteres(Intereses.getNombre(element), Intereses.getIcon(element)));
    });
    _interesesIcons.add(_buildInteresCambiar());

    setState(() {});
  }

  Widget _buildInteres(String texto, Icon icon){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: constants.blackGeneral),
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
    List<String> listIntereses = Intereses.getListaIntereses();

    _listInteresesCheckbox = [];
    listIntereses.forEach((String element) {
      _listInteresesCheckbox.add(CheckboxItemIntereses(interesId: element, seleccionado: _intereses.contains(element)));
    });

    showDialog(context: context, builder: (context){
      return StatefulBuilder(builder: (context, setState){
        return AlertDialog(
          content: Container(
              width: double.maxFinite,
              child: ListView.builder(itemBuilder: (context, index){
                if(index == 0){
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16,),
                    child: Text("Selecciona tus intereses para ver actividades relacionados con estos. Elige mínimo uno (1):",
                      style: TextStyle(color: constants.grey, fontSize: 12), textAlign: TextAlign.center,),
                  );
                }

                index = index - 1;

                return CheckboxListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  value: _listInteresesCheckbox[index].seleccionado,
                  onChanged: (newValue){
                    setState(() {
                      _listInteresesCheckbox[index].seleccionado = newValue;
                    });
                  },
                  title: Text(Intereses.getNombre(_listInteresesCheckbox[index].interesId)),
                  subtitle: Text(Intereses.getDescripcion(_listInteresesCheckbox[index].interesId), style: TextStyle(fontSize: 12),),
                  secondary: Intereses.getIcon(_listInteresesCheckbox[index].interesId),
                );

              }, itemCount: _listInteresesCheckbox.length + 1, shrinkWrap: true,)
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _enviandoIntereses ? null : () => _validarInteresesNuevos(setState),
              child: const Text("Enviar"),
            ),
          ],
        );
      });
    });
  }

  _validarInteresesNuevos(setStateDialog){
    setStateDialog(() {
      _enviandoIntereses = true;
    });

    List<String> nuevosIntereses = [];

    _listInteresesCheckbox.forEach((CheckboxItemIntereses element) {
      if(element.seleccionado == true){
        nuevosIntereses.add(element.interesId);
      }
    });

    if(nuevosIntereses.length < 1){

      setStateDialog(() {
        _enviandoIntereses = false;
      });

    } else {
      _enviarInteresesNuevos(setStateDialog, nuevosIntereses);
    }
  }

  _enviarInteresesNuevos(setStateDialog, List<String> nuevosIntereses) async {
    setStateDialog(() {
      _enviandoIntereses = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlHomeCambiarIntereses,
      body: {
        "intereses": nuevosIntereses
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _intereses = nuevosIntereses;
        _buildInteresesIcons();


        usuarioSesion.interesesId = nuevosIntereses;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));


        Navigator.of(context).pop();

        _recargarActividades();

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoIntereses = false;
    });
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