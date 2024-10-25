import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/universidad.dart';
import 'package:tenfo/screens/signup/views/signup_location_page.dart';
import 'package:tenfo/screens/signup/views/signup_not_available_page.dart';
import 'package:tenfo/screens/signup/views/signup_send_university_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_no_usuario.dart';

class SignupUniversityPage extends StatefulWidget {
  const SignupUniversityPage({Key? key}) : super(key: key);

  @override
  State<SignupUniversityPage> createState() => _SignupUniversityPageState();
}

class _SignupUniversityPageState extends State<SignupUniversityPage> {

  List<Universidad> _universidades = [];

  String _textoBusqueda = "";
  Timer? _timer;

  bool _loadingUniversidades = false;

  @override
  void initState() {
    super.initState();

    _cargarUniversidades("");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [

            const Text("Elige tu universidad",
              style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
            ),
            const SizedBox(height: 16,),

            const Align(
              alignment: Alignment.center,
              child: Text("Este valor no se podrá cambiar.",
                style: TextStyle(color: constants.grey,),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0,),
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: "Buscar más...",
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


                  _timer?.cancel();

                  setState(() {
                    _loadingUniversidades = true;
                  });

                  _timer = Timer(const Duration(milliseconds: 500), (){
                    _cargarUniversidades(text);
                  });
                },
              ),
            ),

            const SizedBox(height: 24,),

            Expanded(child: _loadingUniversidades ? const Center(child: CircularProgressIndicator(),)
                : _universidades.isEmpty

                  ? Column(children: [
                    const SizedBox(height: 16,),
                    Text("No hay resultados encontrados",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24,),
                    Container(
                      constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
                      child: OutlinedButton(
                        onPressed: (){
                          _enviarUniversidad(_textoBusqueda);

                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => const SignupNotAvailablePage(
                              isUniversidadNoDisponible: true,
                            ),
                          ));
                        },
                        child: const Text('Encontrar mi universidad'),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                        ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                      ),
                    ),
                    const SizedBox(height: 16,),
                  ], mainAxisAlignment: MainAxisAlignment.center,)

                  : ListView.builder(
                    itemCount: _universidades.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8,),
                        child: _buildUniversidad(_universidades[index]),
                      );
                    },
                  ),
            ),

            const SizedBox(height: 16,),

          ],),
        ),
      ),
    );
  }

  Widget _buildUniversidad(Universidad universidad){
    return ListTile(
      title: Text(universidad.nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(universidad.nombreCompleto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: const CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(Icons.school_outlined, color: constants.blackGeneral,),
      ),
      onTap: (){
        // Envia historial no usuario
        _enviarHistorialNoUsuario(HistorialNoUsuario.getRegistroUniversidadElegir(universidad.id));

        Navigator.push(context, MaterialPageRoute(
            builder: (context) => SignupLocationPage(
              universidadId: universidad.id,
            )
        ));
      },
    );
  }

  Widget _buildOtraUniversidad(){
    return ListTile(
      title: const Text("Otra universidad",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: const CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(Icons.school_outlined, color: constants.blackGeneral,),
      ),
      onTap: (){
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => const SignupSendUniversityPage()
        ));
      },
    );
  }

  Future<void> _cargarUniversidades(String texto) async {
    setState(() {
      _loadingUniversidades = true;
    });

    var response = await HttpService.httpGet(
      url: constants.urlRegistroBuscarUniversidades,
      queryParams: {
        "texto": texto,
      },
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _universidades.clear();

        List<dynamic> universidades = datosJson['data']['universidades'];
        for (var element in universidades) {
          _universidades.add(Universidad(
            id: element['id'].toString(),
            nombre: element['nombre'],
            nombreCompleto: element['nombre_completo'],
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingUniversidades = false;
    });
  }

  Future<void> _enviarUniversidad(String universidad) async {
    /*setState(() {
      _enviandoUniversidad = true;
    });*/

    universidad = universidad.trim();
    if(universidad.isEmpty){
      //setState(() {_enviandoUniversidad = false;});
      return;
    }

    var response = await HttpService.httpPost(
      url: constants.urlRegistroSolicitarUniversidad,
      body: {
        "universidad_texto": universidad,
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        //

      } else {
        // _showSnackBar("Se produjo un error inesperado");
      }
    }

    /*setState(() {
      _enviandoUniversidad = false;
    });*/
  }

  Future<void> _enviarHistorialNoUsuario(Map<String, dynamic> historialNoUsuario) async {
    //setState(() {});

    var response = await HttpService.httpPost(
      url: constants.urlCrearHistorialNoUsuario,
      body: {
        "historiales_no_usuario": [historialNoUsuario],
      },
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