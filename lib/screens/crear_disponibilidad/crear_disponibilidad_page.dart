import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/actividad_sugerencia_titulo.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/services/location_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class CrearDisponibilidadPage extends StatefulWidget {
  const CrearDisponibilidadPage({Key? key, this.isFromSignup = false}) : super(key: key);

  final bool isFromSignup;

  @override
  State<CrearDisponibilidadPage> createState() => _CrearDisponibilidadPageState();
}

class _CrearDisponibilidadPageState extends State<CrearDisponibilidadPage> {

  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  bool _loadingSugerenciasTitulo = false;
  List<ActividadSugerenciaTitulo> _actividadSugerenciasTitulo = [];

  bool _enviando = false;
  bool _isValorPredeterminadoUsado = false;

  final LocationService _locationService = LocationService();
  LocationServicePermissionStatus _permissionStatus = LocationServicePermissionStatus.loading;
  LocationServicePosition? _locationServicePosition;

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
        title: widget.isFromSignup ? const Text("Nuevo") : const Text("Nuevo"),
        leading: widget.isFromSignup ? null : IconButton(
          icon: const Icon(Icons.clear),
          onPressed: (){
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(children: [
        Expanded(child: SingleChildScrollView(
          child: _contenido(),
        )),

        if(!widget.isFromSignup)
          ...[
            GestureDetector(
              child: const Text("¿Quién podrá ver este estado?",
                style: TextStyle(color: constants.grey, fontSize: 12, decoration: TextDecoration.underline,),
              ),
              onTap: (){
                _showDialogAyudaVisualizacion();
              },
            ),
            const SizedBox(height: 16,),
          ],

        if(widget.isFromSignup)
          ...[
            TextButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const CrearActividadPage(),
                ));
              },
              child: const Text("Ir a Crear Actividad"),
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12,),
                shape: const StadiumBorder(),
              ),
            ),
            const SizedBox(height: 16,),
          ],
      ]),),
    );
  }

  void _showDialogAyudaVisualizacion(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("El estado estará durante 48 horas solamente.\n\n"
                "Solo las personas cercanas a tu ubicación que hayan creado en las últimas 48 horas, una actividad o un estado, podrán verlo.\n\n"
                "Si ya tienes un estado visible, el nuevo estado lo reemplazará.",
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
  }

  Widget _contenido(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(children: [
        TextField(
          focusNode: _titleFocusNode,
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: "Escribe un estado... (opcional)",
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
          child: const Text("Sugerencias:", textAlign: TextAlign.left,
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

  void _validarContenido(){
    bool isValorPredeterminado = false;

    if(_titleController.text.trim() == '' || (_titleController.text.trim() == "👋" && _isValorPredeterminadoUsado)){
      // Si el contenido esta vacio, crea esto por defecto
      _titleController.text = "👋";
      isValorPredeterminado = true;
    }

    if(_permissionStatus != LocationServicePermissionStatus.permitted){
      if(_permissionStatus == LocationServicePermissionStatus.loading){
        _showSnackBar("Obteniendo ubicación. Espere...");

        if(isValorPredeterminado){
          // Debe volver a presionar cuando ya se cargó la ubicación. Con esto saber que el contenido ya era un valorPredeterminado.
          _isValorPredeterminadoUsado = true;
        }
      }

      if(_permissionStatus == LocationServicePermissionStatus.serviceDisabled){
        // TODO : Deberia volver a comprobar por si los activo después de recibir el aviso
        _showSnackBar("Tienes los servicios de ubicación deshabilitados. Actívalo desde Ajustes.");
      }

      if(_permissionStatus == LocationServicePermissionStatus.notPermitted){
        _showSnackBar("Debes habilitar la ubicación en Inicio para poder continuar.");
      }

      return;
    }

    _crearDisponibilidad(isValorPredeterminado);
  }

  Future<void> _crearDisponibilidad(bool isValorPredeterminado) async {
    setState(() {
      _enviando = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    String textoPredeterminadoEnviado = "NO";
    if(isValorPredeterminado){
      textoPredeterminadoEnviado = "SI";
    }

    var response = await HttpService.httpPost(
      url: constants.urlCrearDisponibilidad,
      body: {
        "disponibilidad_texto": _titleController.text.trim(),
        "ubicacion_latitud": _locationServicePosition?.latitude.toString() ?? "",
        "ubicacion_longitud": _locationServicePosition?.longitude.toString() ?? "",
        "texto_predeterminado_enviado": textoPredeterminadoEnviado,
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