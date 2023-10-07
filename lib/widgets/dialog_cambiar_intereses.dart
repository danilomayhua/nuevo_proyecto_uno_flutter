import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/checkbox_item_intereses.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/intereses.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class DialogCambiarIntereses extends StatefulWidget {
  const DialogCambiarIntereses({Key? key, required this.intereses, required this.onChanged}) : super(key: key);

  final List<String> intereses;
  final void Function(List<String> nuevosIntereses) onChanged;

  @override
  _DialogCambiarInteresesState createState() => _DialogCambiarInteresesState();
}

class _DialogCambiarInteresesState extends State<DialogCambiarIntereses> {

  List<CheckboxItemIntereses> _listInteresesCheckbox = [];
  bool _enviandoIntereses = false;

  bool _isFirstTime = false;
  String _nombre = "";

  @override
  void initState() {
    super.initState();

    List<String> listIntereses = Intereses.getListaIntereses();

    _listInteresesCheckbox = [];
    listIntereses.forEach((String element) {
      _listInteresesCheckbox.add(CheckboxItemIntereses(interesId: element, seleccionado: widget.intereses.contains(element)));
    });

    _isFirstTime = widget.intereses.isEmpty;
    if(_isFirstTime){
      SharedPreferences.getInstance().then((prefs){
        UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);
        _nombre = usuarioSesion.nombre;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
          width: double.maxFinite,
          child: ListView.builder(itemBuilder: (context, index){
            if(index == 0){
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16,),
                child: Text(_isFirstTime
                    ? "¡Comencemos $_nombre! Selecciona qué tipo de actividades te gustaría ver y crear. Elige mínimo uno (1):"
                    : "Modifica tus intereses para ver y crear actividades relacionados con estos. Elige mínimo uno (1):",
                  style: const TextStyle(color: constants.grey, fontSize: 12), textAlign: TextAlign.center,),
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
          onPressed: _enviandoIntereses ? null : () => _validarInteresesNuevos(),
          child: const Text("Guardar"),
        ),
      ],
    );
  }

  void _validarInteresesNuevos(){
    setState(() {
      _enviandoIntereses = true;
    });

    List<String> nuevosIntereses = [];

    _listInteresesCheckbox.forEach((CheckboxItemIntereses element) {
      if(element.seleccionado == true){
        nuevosIntereses.add(element.interesId);
      }
    });

    if(nuevosIntereses.length < 1){

      setState(() {
        _enviandoIntereses = false;
      });

    } else {
      _enviarInteresesNuevos(nuevosIntereses);
    }
  }

  Future<void> _enviarInteresesNuevos(List<String> nuevosIntereses) async {
    setState(() {
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

        usuarioSesion.interesesId = nuevosIntereses;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

        widget.onChanged(nuevosIntereses);

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoIntereses = false;
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