import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/screens/crear_disponibilidad/crear_disponibilidad_page.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_usuario.dart';

class SeleccionarCrearTipoPage extends StatefulWidget {
  const SeleccionarCrearTipoPage({Key? key, this.isFromSignup = false}) : super(key: key);

  final bool isFromSignup;

  @override
  State<SeleccionarCrearTipoPage> createState() => _SeleccionarCrearTipoPageState();
}

class _SeleccionarCrearTipoPageState extends State<SeleccionarCrearTipoPage> {

  @override
  void initState() {
    super.initState();

    // Envia historial del usuario
    _enviarHistorialUsuario(HistorialUsuario.getSeleccionarCrearTipo(isFromSignup: widget.isFromSignup));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo"),
        leading: widget.isFromSignup ? null : IconButton(
          icon: const Icon(Icons.clear),
          onPressed: (){
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(children: [
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(children: [
              const Text("¿Qué tienes en mente hoy?",
                style: TextStyle(color: constants.blackGeneral, fontSize: 18,),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32,),

              if(!widget.isFromSignup)
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const CrearActividadPage(),
                      ));
                    },
                    child: const Text("Crear actividad"),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                  ),
                ),
              if(widget.isFromSignup)
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const CrearActividadPage(),
                      ));
                    },
                    child: const Text("Crear actividad"),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Expanded(
                    child: Divider(
                      color: constants.grey,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('o', style: TextStyle(color: constants.blackGeneral,),),
                  ),
                  Expanded(
                    child: Divider(
                      color: constants.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if(!widget.isFromSignup)
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const CrearDisponibilidadPage(),
                      ));
                    },
                    child: const Text("Explorar actividades"),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              if(widget.isFromSignup)
                Container(
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const CrearDisponibilidadPage(),
                      ));
                    },
                    child: const Text("Explorar actividades"),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                  ),
                ),

            ], mainAxisAlignment: MainAxisAlignment.center,),
        ),),

        if(!widget.isFromSignup)
          ...[
            TextButton(
              onPressed: (){
                _showDialogComoFunciona();
              },
              child: const Text("Cómo funciona"),
              style: TextButton.styleFrom(
                primary: constants.blackGeneral,
              ),
            ),
            const SizedBox(height: 16,),
          ],
        if(widget.isFromSignup)
          const SizedBox(height: 50,),
      ]),
    );
  }

  void _showDialogComoFunciona(){
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context){
        return SingleChildScrollView(child: Container(
          padding: const EdgeInsets.only(left: 16, top: 32, right: 15, bottom: 32,),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text("Para desbloquear lo que otros están compartiendo, puedes elegir entre dos opciones.",
                style: TextStyle(color: constants.blackGeneral, fontSize: 15, height: 1.3,),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

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
                        text: "Crear actividad:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
                      ),
                      TextSpan(
                        text: " Crea una actividad para que otros usuarios puedan unirse. En esta opción, puedes "
                            "proponer o sugerir una actividad para realizar y participar en un chat con los demás miembros.",
                      )
                    ],
                  ),
                ),),
              ], crossAxisAlignment: CrossAxisAlignment.start,),

              const SizedBox(height: 32),

              Row(children: [
                Container(
                  width: 50,
                  child: const Icon(Icons.visibility_outlined),
                ),
                Expanded(child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: constants.blackGeneral, fontSize: 15, height: 1.3,),
                    children: [
                      TextSpan(
                        text: "Explorar actividades:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
                      ),
                      TextSpan(
                        text: " Esto es un estado e indica que estás buscando actividades, pero aún no has creado ninguna. "
                            "Elige esta opción si solo quieres ver lo que otros están compartiendo.",
                      )
                    ],
                  ),
                ),),
              ], crossAxisAlignment: CrossAxisAlignment.start,),

              const SizedBox(height: 32),

              const Text("En ambas opciones, puedes unirte a las actividades que estén disponibles.",
                style: TextStyle(color: constants.blackGeneral, fontSize: 15, height: 1.3,),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Entendido"),
              ),
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