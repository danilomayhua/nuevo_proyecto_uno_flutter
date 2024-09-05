import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/disponibilidad.dart';
import 'package:tenfo/models/sugerencia_usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

// Es importante no cambiar los nombres de este enum (se envian al backend)
enum SuperlikeServiceFromPantalla { perfil_usuario, card_disponibilidad, scrollsnap_disponibilidad, card_sugerencia_usuario, scrollsnap_sugerencia_usuario }

class SuperlikeService {

  static Future<void> enviarSuperlike({
    required String usuarioId,
    required void Function({bool isSuperliked, bool enviando}) onChange,
    required BuildContext context,
    Disponibilidad? fromDisponibilidad,
    SugerenciaUsuario? fromSugerenciaUsuario,
    SuperlikeServiceFromPantalla? fromPantalla,
  }) async {

    bool isSuperliked = true;
    bool enviando = true;

    onChange(isSuperliked: isSuperliked, enviando: enviando,);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);


    if(fromPantalla == SuperlikeServiceFromPantalla.perfil_usuario){
      // Tooltip de ayuda a los usuarios nuevos para enviar superlike desde un perfil. Actualiza valor para no volver a mostrar.
      bool isShowedSuperlike = prefs.getBool(SharedPreferencesKeys.isShowedAyudaPerfilSuperlike) ?? false;
      if(!isShowedSuperlike){
        prefs.setBool(SharedPreferencesKeys.isShowedAyudaPerfilSuperlike, true);
      }
    } else if(fromPantalla == SuperlikeServiceFromPantalla.card_disponibilidad){
      // Tooltip de ayuda a los usuarios nuevos para enviar superlike desde disponibilidad. Actualiza valor para no volver a mostrar.
      bool isShowedSuperlike = prefs.getBool(SharedPreferencesKeys.isShowedAyudaDisponibilidadSuperlike) ?? false;
      if(!isShowedSuperlike){
        prefs.setBool(SharedPreferencesKeys.isShowedAyudaDisponibilidadSuperlike, true);
      }
    }


    var response = await HttpService.httpPost(
      url: constants.urlEnviarSuperlike,
      body: {
        "usuario_id": usuarioId,

        // Envia para analizar comportamiento
        "datos_enviado_desde": (fromDisponibilidad == null && fromSugerenciaUsuario == null && fromPantalla == null)
            ? null
            : {
              "disponibilidad_id" : fromDisponibilidad?.id,
              "sugerencia_usuario_id" : fromSugerenciaUsuario?.id,
              "pantalla" : fromPantalla?.name,
            },
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200) {
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        // Los cambios ya fueron agregados al principio de la funcion

      } else {
        if(datosJson['error_tipo'] == 'superlike_existente'){

          //isSuperliked = true;

        } else if(datosJson['error_tipo'] == 'limite_superlikes'){

          isSuperliked = false;
          _showSnackBar(context, "Alcanzaste el límite de incentivos por hoy");

        } else {

          isSuperliked = false;
          _showSnackBar(context, "Se produjo un error inesperado");

        }
      }
    }

    enviando = false;
    onChange(isSuperliked: isSuperliked, enviando: enviando,);
  }

  static void intentarPresionarSuperliked({
    required String usuarioNombre,
    required BuildContext context,
  }) {
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Tienes que esperar un tiempo para enviarle otro Incentivo a ${usuarioNombre} nuevamente.\n\n"
                  "Envía incentivos a más personas para convencerlos a hacer actividades. Los incentivos son anónimos y no muestran tu nombre.",
                style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),),
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

  static void _showSnackBar(BuildContext context, String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}