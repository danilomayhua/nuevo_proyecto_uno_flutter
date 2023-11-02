import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/actividad_sugerencia_titulo.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class CrearDisponibilidadPage extends StatefulWidget {
  const CrearDisponibilidadPage({Key? key}) : super(key: key);

  @override
  State<CrearDisponibilidadPage> createState() => _CrearDisponibilidadPageState();
}

enum LocationPermissionStatus {
  loading,
  permitted,
  notPermitted,
  serviceDisabled,
}

class _CrearDisponibilidadPageState extends State<CrearDisponibilidadPage> {

  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  bool _loadingSugerenciasTitulo = false;
  List<ActividadSugerenciaTitulo> _actividadSugerenciasTitulo = [];

  bool _enviando = false;

  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.loading;
  Position? _position;

  @override
  void initState() {
    super.initState();

    _obtenerUbicacion();

    _cargarSugerenciasTitulo();
  }

  @override
  void dispose() {
    _titleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva visualización"),
        leading: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: (){
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          child: _contenido(),
        )),
        GestureDetector(
          child: const Text("¿Quién podrá ver esta visualización?",
            style: TextStyle(color: constants.grey, fontSize: 12, decoration: TextDecoration.underline,),
          ),
          onTap: (){
            _showDialogAyudaVisualizacion();
          },
        ),
        const SizedBox(height: 16,),
      ]),
    );
  }

  void _showDialogAyudaVisualizacion(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("La visualización estará durante 48 horas solamente.\n\n"
                "Solo las personas cercanas a tu ubicación que hayan creado en las últimas 48 horas, una actividad o una visualización, podrán verla.",
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

  Widget _contenido(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(children: [
        TextField(
          focusNode: _titleFocusNode,
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: "Escribe un estado...",
            hintStyle: TextStyle(fontWeight: FontWeight.normal,),
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

        Container(
          width: double.infinity,
          child: const Text("Opciones:", textAlign: TextAlign.left,
            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
          ),
        ),
        const SizedBox(height: 8,),
        Container(
          alignment: Alignment.centerLeft,
          height: 75,
          child: _loadingSugerenciasTitulo ? const CircularProgressIndicator() : ListView.builder(itemBuilder: (context, index){

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

        const SizedBox(height: 32,),

        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _enviando ? null : () => _validarContenido(),
            child: const Text("Acceder"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),

        const SizedBox(height: 32,),
      ],),
    );
  }

  Future<void> _cargarSugerenciasTitulo() async {
    setState(() {
      _loadingSugerenciasTitulo = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlDisponibilidadSugerencias,
      queryParams: {},
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _actividadSugerenciasTitulo.clear();

        List<dynamic> disponibilidadSugerencias = datosJson['data']['disponibilidad_sugerencias_texto'];
        for (var element in disponibilidadSugerencias) {
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
      _loadingSugerenciasTitulo = false;
    });
  }

  Future<void> _obtenerUbicacion() async {
    _position = null;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _permissionStatus = LocationPermissionStatus.serviceDisabled;
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _permissionStatus = LocationPermissionStatus.notPermitted;
      return;
    }

    try {

      _position = await Geolocator.getCurrentPosition();
      _permissionStatus = LocationPermissionStatus.permitted;

    } catch (e){
      _permissionStatus = LocationPermissionStatus.notPermitted;
      return;
    }

    return;
  }

  void _validarContenido(){
    if(_titleController.text.trim() == ''){
      _showSnackBar("El contenido está vacío");
      return;
    }

    if(_permissionStatus != LocationPermissionStatus.permitted){
      if(_permissionStatus == LocationPermissionStatus.loading){
        _showSnackBar("Obteniendo ubicación. Espere...");
      }

      if(_permissionStatus == LocationPermissionStatus.serviceDisabled){
        // TODO : Deberia volver a comprobar por si los activo después de recibir el aviso
        _showSnackBar("Tienes los servicios de ubicación deshabilitados. Actívalo desde Ajustes.");
      }

      if(_permissionStatus == LocationPermissionStatus.notPermitted){
        _showSnackBar("Debes habilitar la ubicación en Inicio para poder continuar.");
      }

      return;
    }

    _crearDisponibilidad();
  }

  Future<void> _crearDisponibilidad() async {
    setState(() {
      _enviando = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCrearDisponibilidad,
      body: {
        "disponibilidad_texto": _titleController.text.trim(),
        "ubicacion_latitud": _position?.latitude.toString() ?? "",
        "ubicacion_longitud": _position?.longitude.toString() ?? "",
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) => const PrincipalPage()
        ), (root) => false);

      } else {

        if(datosJson['error_tipo'] == 'ubicacion_no_disponible'){
          _showSnackBar("Lo sentimos, actualmente Tenfo no está disponible en tu ciudad.");
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviando = false;
    });
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}