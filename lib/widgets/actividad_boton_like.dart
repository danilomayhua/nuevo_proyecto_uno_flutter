import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class ActividadBotonLike extends StatefulWidget {
  const ActividadBotonLike({Key? key, required this.actividad, this.onChange}) : super(key: key);

  final Actividad actividad;
  final void Function()? onChange;

  @override
  _ActividadBotonLikeState createState() => _ActividadBotonLikeState();
}

class _ActividadBotonLikeState extends State<ActividadBotonLike> {

  bool _enviando = false;

  @override
  Widget build(BuildContext context) {
    return widget.actividad.isLiked
        ? IconButton(
          icon: const Icon(Icons.favorite, size: 24, color: Colors.redAccent,),
          onPressed: _enviando ? null : () => _quitarLikeActividad(),
        )
        : IconButton(
          icon: const Icon(Icons.favorite_border, size: 24, color: constants.blackGeneral,),
          onPressed: _enviando ? null : () => _likeActividad(),
        );
  }

  Future<void> _likeActividad() async {
    widget.actividad.isLiked = true;
    widget.actividad.likesCount++;

    setState(() {
      _enviando = true;
    });

    // Actualiza el contador de likes y el estado de card_actividad que abrio actividad_page
    if(widget.onChange != null) widget.onChange!();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlLikeActividadAgregar,
      body: {
        "actividad_id": widget.actividad.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        // Los cambios ya fueron agregados al principio de la funcion

      } else {
        if(datosJson['error_tipo'] == 'tiene_like'){

          //widget.actividad.isLiked = true;

        } else {
          widget.actividad.isLiked = false;
          widget.actividad.likesCount--;
          _showSnackBar("Se produjo un error inesperado");

          // Actualiza el contador de likes y el estado de card_actividad que abrio actividad_page
          if(widget.onChange != null) widget.onChange!();
        }
      }
    }

    setState(() {
      _enviando = false;
    });
  }

  Future<void> _quitarLikeActividad() async {
    widget.actividad.isLiked = false;
    widget.actividad.likesCount--;

    setState(() {
      _enviando = true;
    });

    // Actualiza el contador de likes y el estado de card_actividad que abrio actividad_page
    if(widget.onChange != null) widget.onChange!();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlLikeActividadQuitar,
      body: {
        "actividad_id": widget.actividad.id
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        // Los cambios ya fueron agregados al principio de la funcion

      } else {
        if(datosJson['error_tipo'] == 'no_tiene_like'){

          //widget.actividad.isLiked = false;

        } else {
          widget.actividad.isLiked = true;
          widget.actividad.likesCount++;
          _showSnackBar("Se produjo un error inesperado");

          // Actualiza el contador de likes y el estado de card_actividad que abrio actividad_page
          if(widget.onChange != null) widget.onChange!();
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