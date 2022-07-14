import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/models/actividad.dart';
import 'package:nuevoproyectouno/models/actividad_requisito.dart';
import 'package:nuevoproyectouno/models/usuario.dart';
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/screens/actividad/actividad_page.dart';
import 'package:nuevoproyectouno/screens/principal/principal_page.dart';
import 'package:nuevoproyectouno/services/http_service.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:nuevoproyectouno/utilities/intereses.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrearActividadPage extends StatefulWidget {
  const CrearActividadPage({Key? key}) : super(key: key);

  @override
  State<CrearActividadPage> createState() => _CrearActividadPageState();
}

enum ActividadTipo { publico, privado, requisitos }

class _CrearActividadPageState extends State<CrearActividadPage> {
  final PageController _pageController = PageController();
  int _pageCurrent = 0;

  List<String> _intereses = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedInteresId;

  List<Usuario> _creadores = [];
  List<Usuario> _creadoresBusqueda = [];
  bool _loadingCreadoresBusqueda = false;
  Timer? _timer;
  final List<String> _stringActividadTipo = ["Público","Privado","Requisitos"];
  ActividadTipo? _actividadTipo = ActividadTipo.publico;
  String _actividadTipoSelected = "Público";
  List<ActividadRequisito> _requisitoPreguntas = [];
  bool _preguntaNueva = false;
  final TextEditingController _preguntaNuevaController = TextEditingController();
  String _errorTextPreguntas = '';

  bool _enviando = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);
      _intereses = usuarioSesion.interesesId;
      setState(() {});
    });
    _titleController.text = '';
    _descriptionController.text = '';

    _pageController.addListener(() {
      if(_pageController.page != null && _pageCurrent != _pageController.page!.toInt()){
        _pageCurrent = _pageController.page!.toInt();
        setState(() {});
      }
    });
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
        title: const Text("Crear actividad"),
        leading: IconButton(
          icon: _pageCurrent == 0 ? Icon(Icons.clear) : Icon(Icons.arrow_back),
          onPressed: (){
            if(_pageCurrent == 0){
              Navigator.of(context).pop();
            } else {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index){
          WidgetsBinding.instance?.focusManager.primaryFocus?.unfocus();
        },
        children: [
          SingleChildScrollView(
            child: contenidoUno(),
          ),
          SingleChildScrollView(
            child: contenidoDos(),
          ),
        ],
      ),
    );

    return WillPopScope(
      child: child,
      onWillPop: _pageCurrent != 0 ? (){

        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return Future.value(false);

      } : null, // Tiene que ser null para que funcione en iOS
    );
  }

  Widget contenidoUno(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: "¿Qué actividad vas a realizar?",
            labelText: "Título",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(),
          ),
          maxLength: 200,
          minLines: 1,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: 24,),

        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            isDense: true,
            //contentPadding: EdgeInsets.only(top: 4, bottom: 8),
            //hintText: "Descripción detallada...",
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

        const SizedBox(height: 24,),

        Container(
          width: double.infinity,
          child: const Text("¿A qué interés pertenece?", textAlign: TextAlign.center,
            style: TextStyle(color: constants.blackGeneral,),
          ),
        ),
        const SizedBox(height: 8,),
        Container(
          alignment: Alignment.center,
          height: 75,
          child: ListView.builder(itemBuilder: (context, index){

            return GestureDetector(
              onTap: (){
                setState(() {
                  _selectedInteresId = _intereses[index];
                });
              },
              child: Container(
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 8),
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
                        child: Intereses.getIcon(_intereses[index])
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

        const SizedBox(height: 16,),

        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (){
              _validarContenidoUno();
            },
            child: const Text("Siguiente"),
            style: ElevatedButton.styleFrom(
              //primary: ,
            ),
          ),
        ),
        const SizedBox(height: 8,),
        const Text("Paso 1 de 2",
          style: TextStyle(color: constants.grey, fontSize: 12,),
        ),

        const SizedBox(height: 32,),
      ],),
    );
  }

  Widget contenidoDos(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(children: [
        Container(
          width: double.infinity,
          child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              style: TextStyle(color: constants.blackGeneral),
              text: "¿Quién más crea la actividad? (opcional)",
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    width: 32,
                    height: 32,
                    //margin: EdgeInsets.only(left: 4),
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
            ListTile(
              dense: true,
              title: Text(_creadores[i].nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_creadores[i].username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: CircleAvatar(
                backgroundColor: constants.greyBackgroundImage,
                backgroundImage: NetworkImage(_creadores[i].foto),
              ),
              trailing: IconButton(
                onPressed: (){
                  setState(() {
                    _creadores.removeAt(i);
                  });
                },
                icon: const Icon(Icons.cancel_outlined, color: constants.blackGeneral,),
              ),
            ),
        const SizedBox(height: 8,),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: (){
              if(_creadores.length >= 3){
                _showSnackBar("Solo se pueden añadir tres(3) co-creadores");
              } else {
                _showDialogCreadores();
              }
            },
            icon: const Icon(Icons.add, size: 18,),
            label: const Text("Añadir co-creadores", style: TextStyle(fontSize: 12,)),
            style: OutlinedButton.styleFrom(
              primary: constants.blackGeneral,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),

        const SizedBox(height: 24,),

        Row(
          children: [
            const Text("Tipo:", style: TextStyle(color: constants.blackGeneral),),
            const SizedBox(width: 8,),
            OutlinedButton(
              onPressed: () => _mostrarDialogTipos(),
              child: Text(_actividadTipoSelected, style: TextStyle(fontSize: 12,)),
              style: OutlinedButton.styleFrom(
                primary: constants.blackGeneral,
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            IconButton(
              onPressed: (){
                _showDialogAyudaTiposActividad();
              },
              icon: Icon(Icons.help_outline, color: constants.grey,),
              padding: EdgeInsets.all(0),
            ),
          ],
        ),
        if(_actividadTipo == ActividadTipo.requisitos)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: (){
                _showDialogPreguntas();
              },
              icon: Icon(Icons.edit, size: 18,),
              label: Text("Editar preguntas", style: TextStyle(fontSize: 12,)),
              style: OutlinedButton.styleFrom(
                primary: constants.blackGeneral,
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),

        const SizedBox(height: 32,),

        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _enviando ? null : () => _validarContenidoDos(),
            child: const Text("Crear actividad"),
            style: ElevatedButton.styleFrom(
              //primary: ,
            ),
          ),
        ),
        const SizedBox(height: 8,),
        const Text("Paso 2 de 2",
          style: TextStyle(color: constants.grey, fontSize: 12,),
        ),

        const SizedBox(height: 32,),
      ],),
    );
  }

  void _validarContenidoUno(){
    if(_titleController.text.trim() == ''){
      _showSnackBar("El título está vacío");
      return;
    }

    if(_selectedInteresId == null){
      _showSnackBar("Selecciona a qué interés pertenece");
      return;
    }

    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }

  void _showDialogAyudaCreadores(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("Puedes añadir a tus amigos cercanos con los cuales vas a organizar la actividad.\n\n"
                "Todos aparecerán enlistados como co-creadores de la actividad y podrán eliminar o aceptar integrantes nuevos en el chat grupal.\n\n"
                "Los usuarios primero tendrán que confirmar ser co-creadores. Puedes añadir hasta tres(3) en total.",
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

  void _showDialogCreadores(){
    showDialog(context: context, builder: (context){
      return StatefulBuilder(builder: (context, setStateDialog){
        return AlertDialog(
          content: Container(
            width: MediaQuery.of(context).size.width - 80,
            child: Column(children: [
              TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: "Buscar...",
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
              const Text("Presiona sobre un usuario para añadirlo",
                style: TextStyle(color: constants.grey, fontSize: 12,),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8,),

              Expanded(
                child: !_loadingCreadoresBusqueda ? ListView.builder(
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
                      backgroundImage: NetworkImage(_creadoresBusqueda[index].foto),
                    ),
                    onTap: (){
                      for(var creador in _creadores){
                        if(creador.id == _creadoresBusqueda[index].id){
                          _creadoresBusqueda.clear();
                          Navigator.of(context).pop();
                          return;
                        }
                      }
                      setState(() {
                        _creadores.add(_creadoresBusqueda[index]);
                        _creadoresBusqueda.clear();
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ) : const Center(child: CircularProgressIndicator()),
              ),

            ], /*mainAxisSize: MainAxisSize.min,*/),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
          ],
        );
      });
    });
  }

  Future<void> _buscarUsuario(String texto, setStateDialog) async {
    setStateDialog(() {
      _loadingCreadoresBusqueda = true;
    });

    if(texto.trim() == ''){
      _creadoresBusqueda.clear();
      setStateDialog(() {_loadingCreadoresBusqueda = false;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlActividadBuscadorCocreador,
      queryParams: {
        "texto": texto
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _creadoresBusqueda.clear();

        List<dynamic> usuarios = datosJson['data']['usuarios'];
        for (var element in usuarios) {
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
  }

  void _showDialogAyudaTiposActividad(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            const Text("Existen 2 tipos de privacidad en las actividades:",
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
              Expanded(child: Text("El usuario que quiera unirse, envía una solicitud y alguno de los co-creadores tiene que aceptar para que entre al chat grupal.",
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

    List<String> creadoresId = [];
    for(Usuario usuario in _creadores){
      creadoresId.add(usuario.id);
    }

    var response = await HttpService.httpPost(
      url: constants.urlCrearActividad,
      body: {
        "titulo": _titleController.text.trim(),
        "descripcion": _descriptionController.text.trim(),
        "interes_id": _selectedInteresId,
        "privacidad_tipo": Actividad.getActividadPrivacidadTipoToString(actividadPrivacidadTipo),
        "creadores": creadoresId,
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
                creadores: [Usuario(
                  id: usuarioSesion.id,
                  nombre: usuarioSesion.nombre_completo,
                  username: usuarioSesion.username,
                  foto: usuarioSesion.foto,
                )],
                ingresoEstado: Actividad.getActividadIngresoEstadoFromString(datosActividad['ingreso_estado']),
                isAutor: true,
              ),
              reload: false,
              creadoresPendientes: _creadores,
            )
        )).then((value) => {

          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (context) => const PrincipalPage()
          ), (root) => false)

        });

      } else {
        _showSnackBar("Se produjo un error inesperado");
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