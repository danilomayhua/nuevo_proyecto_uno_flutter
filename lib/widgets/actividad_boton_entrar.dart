import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/actividad_requisito.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/chat/chat_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class ActividadBotonEntrar extends StatefulWidget {
  const ActividadBotonEntrar({Key? key, required this.actividad, this.onChangeIngreso}) : super(key: key);

  final Actividad actividad;
  final void Function()? onChangeIngreso;

  @override
  _ActividadBotonEntrarState createState() => _ActividadBotonEntrarState();
}

class _ActividadBotonEntrarState extends State<ActividadBotonEntrar> {

  bool _errorRequisitos = false;

  bool _enviando = false;

  @override
  Widget build(BuildContext context) {
    return _botonEntrar();
  }

  Widget _botonEntrar(){
    if(widget.actividad.ingresoEstado == ActividadIngresoEstado.PENDIENTE){
      return OutlinedButton.icon(
        onPressed: (){
          _showDialogPendiente();
        },
        //onPressed: null,
        icon: const Icon(Icons.north_east, size: 16,),
        label: const Text("En espera", style: TextStyle(fontSize: 12),),
        style: OutlinedButton.styleFrom(
          primary: Colors.white,
          backgroundColor: constants.blueGeneral,
          //onSurface: constants.grey,
          side: const BorderSide(color: Colors.transparent, width: 0.5,),
          shape: const StadiumBorder(),
        ),
      );
    } else if(widget.actividad.ingresoEstado == ActividadIngresoEstado.INTEGRANTE || widget.actividad.isAutor){
      return OutlinedButton.icon(
        onPressed: (){
          if(widget.actividad.isAutor && widget.actividad.ingresoEstado == ActividadIngresoEstado.NO_INTEGRANTE){
            _showDialogSinIntegrantes();
          } else {
            Navigator.push(context,
              MaterialPageRoute(
                builder: (context) => ChatPage(chat: widget.actividad.chat!),
              ),
            );
          }
        },
        //onPressed: null,
        icon: const Icon(Icons.near_me, size: 16,),
        label: const Text("Ir al chat grupal", style: TextStyle(fontSize: 12),),
        style: OutlinedButton.styleFrom(
          primary: Colors.white,
          backgroundColor: constants.blueGeneral,
          //onSurface: constants.grey,
          side: const BorderSide(color: Colors.transparent, width: 0.5,),
          shape: const StadiumBorder(),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: _enviando ? null : (){
          if(widget.actividad.ingresoEstado == ActividadIngresoEstado.EXPULSADO){
            _showDialogExpulsado();
          } else {
            _unirseActividad();
          }
        },
        icon: const Icon(Icons.north_east, size: 16,),
        label: const Text("Unirse", style: TextStyle(fontSize: 12),),
        style: OutlinedButton.styleFrom(
          primary: constants.blueGeneral,
          backgroundColor: Colors.white,
          //onSurface: constants.grey,
          side: const BorderSide(color: constants.blueGeneral, width: 0.5,),
          shape: const StadiumBorder(),
        ),
      );
    }
  }

  void _showDialogSinIntegrantes(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text("El chat grupal se creará cuando al menos una persona se una a la actividad.",
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

  void _showDialogExpulsado(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text("No puedes unirte a este chat grupal porque un usuario te eliminó.",
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

  Future<void> _showDialogAvisoLimite() async {
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView( // Es necesario SingleChildScrollView si content es Column
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text("Únete a la actividad y sé parte del chat grupal.\n\n"
                  "Recuerda que solo puedes unirte a una cantidad limitada de actividades por día.",
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

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(SharedPreferencesKeys.isShowedAyudaActividadIngreso, true);
  }

  void _showDialogLimiteAlcanzado(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Text("Alcanzaste la cantidad máxima de actividades por día.\n\n"
                  "Debes esperar unas horas para entrar a más actividades.",
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

  void _showDialogPendiente(){
    showDialog(context: context, builder: (context){
      return StatefulBuilder(builder: (context, setStateDialog){
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                Text("Esta es una actividad de tipo Privado.\n\n"
                    "Tienes que esperar que te acepte alguno de los co-creadores para ser parte del chat grupal.",
                  style: TextStyle(color: constants.blackGeneral),),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _enviando ? null : () => _cancelarPeticionUnirse(setStateDialog),
              child: const Text("Cancelar petición"),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
            ),
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              child: const Text("Entendido"),
            ),
          ],
        );
      });
    });
  }

  void _showDialogRequisitos(){
    showDialog(context: context, builder: (context){
      return StatefulBuilder(builder: (context, setStateDialog){
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text("Esta es una actividad de tipo Requisitos. Requiere contestar un cuestionario para unirte.\n"
                    "Solo puedes llenarlo una vez.",
                  style: TextStyle(color: constants.grey, fontSize: 12,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18,),
                for (int i=0; i<widget.actividad.requisitosPreguntas.length; i++)
                  Column(children: [
                    Text(widget.actividad.requisitosPreguntas[i].pregunta,
                      textAlign: TextAlign.center,
                    ),
                    Row(children: [
                      Row(children: [
                        Radio<ActividadRequisitoRepuesta>(
                          value: ActividadRequisitoRepuesta.SI,
                          groupValue: widget.actividad.requisitosPreguntas[i].respuesta,
                          onChanged: (ActividadRequisitoRepuesta? value) {
                            setStateDialog(() {
                              widget.actividad.requisitosPreguntas[i].respuesta = value;
                              _errorRequisitos = false;
                            });
                          },
                        ),
                        Text("Si"),
                      ],),
                      const SizedBox(width: 16,),
                      Row(children: [
                        Radio<ActividadRequisitoRepuesta>(
                          value: ActividadRequisitoRepuesta.NO,
                          groupValue: widget.actividad.requisitosPreguntas[i].respuesta,
                          onChanged: (ActividadRequisitoRepuesta? value) {
                            setStateDialog(() {
                              widget.actividad.requisitosPreguntas[i].respuesta = value;
                              _errorRequisitos = false;
                            });
                          },
                        ),
                        Text("No"),
                      ],),
                    ], mainAxisSize: MainAxisSize.min,),
                    const SizedBox(height: 16,),
                  ],),
                if(_errorRequisitos)
                  const Text("Por favor responde todas las preguntas",
                    style: TextStyle(color: constants.redAviso, fontSize: 12,),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: (){
                _verificarRequisitos(setStateDialog);
              },
              child: const Text("Unirme"),
            ),
          ],
        );
      });
    });
  }

  Future<void> _unirseActividad() async {
    setState(() {
      _enviando = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    bool isShowed = prefs.getBool(SharedPreferencesKeys.isShowedAyudaActividadIngreso) ?? false;
    if(!isShowed){
      _showDialogAvisoLimite();
    }


    var response = await HttpService.httpPost(
      url: constants.urlActividadUnirse,
      body: {
        "actividad_id": widget.actividad.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        datosJson = datosJson['data'];

        if(widget.actividad.privacidadTipo == ActividadPrivacidadTipo.PUBLICO){

          if(datosJson['chat'] != null){
            // Siempre tiene que devolver el chat
            widget.actividad.ingresoEstado = ActividadIngresoEstado.INTEGRANTE;
            widget.actividad.chat = Chat(
                id: datosJson['chat']['id'].toString(),
                tipo: ChatTipo.GRUPAL,
                numMensajesPendientes: null,
                actividadChat: widget.actividad
            );
          }

        } else if(widget.actividad.privacidadTipo == ActividadPrivacidadTipo.PRIVADO){

          widget.actividad.ingresoEstado = ActividadIngresoEstado.PENDIENTE;

        } else if(widget.actividad.privacidadTipo == ActividadPrivacidadTipo.REQUISITOS){

          if(widget.actividad.requisitosEnviado){
            _showDialogRequisitosEnviado();
          } else {
            _showDialogRequisitos();
          }

        }

        // Actualiza el estado de card_actividad que abrio actividad_page
        if(widget.onChangeIngreso != null) widget.onChangeIngreso!();

      } else {

        if(datosJson['error_tipo'] == 'limite_ingresos'){
          _showDialogLimiteAlcanzado();
        } else if(datosJson['error_tipo'] == 'limite_integrantes'){
          _showSnackBar("El chat grupal está lleno. No pueden unirse más usuarios.");
        } else if(datosJson['error_tipo'] == 'limite_tiempo'){
          _showSnackBar("No puedes unirte. La actividad fue creada días atrás.");
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviando = false;
    });
  }

  Future<void> _cancelarPeticionUnirse(setStateDialog) async {
    setStateDialog(() {
      _enviando = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlActividadCancelarSolicitud,
      body: {
        "actividad_id": widget.actividad.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){
        widget.actividad.ingresoEstado = ActividadIngresoEstado.NO_INTEGRANTE;
        setState(() {});

        // Actualiza el estado de card_actividad que abrio actividad_page
        if(widget.onChangeIngreso != null) widget.onChangeIngreso!();

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviando = false;
    });

    Navigator.of(context).pop();
  }

  void _verificarRequisitos(setStateDialog){
    _errorRequisitos = false;
    for(var pregunta in widget.actividad.requisitosPreguntas){
      if(pregunta.respuesta == ActividadRequisitoRepuesta.SIN_RESPONDER){
        _errorRequisitos = true;
        break;
      }
    }
    setStateDialog(() {});

    if(!_errorRequisitos){
      bool respuestasCorrecta = true;

      Navigator.of(context).pop();

      if(respuestasCorrecta){
        widget.actividad.ingresoEstado = ActividadIngresoEstado.INTEGRANTE;
        _showDialogRequisitosCorrecto();
      } else {
        widget.actividad.requisitosEnviado = true;
        _showDialogRequisitosIncorrecto();
      }
    }

    setState(() {});
  }

  void _showDialogRequisitosCorrecto(){
    showDialog(context: context, builder: (context){
      return const AlertDialog(
        content: Text("¡Cumples con las respuestas requeridas!", textAlign: TextAlign.center,),
      );
    }, barrierDismissible: false,);

    Future.delayed(const Duration(seconds: 2), (){
      Navigator.of(context).pop();
    });
  }

  void _showDialogRequisitosIncorrecto(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: const Text("No cumples con las respuestas solicitadas para unirte", textAlign: TextAlign.center,),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      );
    });
  }

  void _showDialogRequisitosEnviado(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: const Text("No cumples con las respuestas solicitadas para unirte.\n\n"
            "El cuestionario solo puede ser respondido una vez.",
          textAlign: TextAlign.center,
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

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}