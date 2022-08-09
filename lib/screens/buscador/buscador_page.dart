import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class BuscadorPage extends StatefulWidget {
  const BuscadorPage({Key? key}) : super(key: key);

  @override
  State<BuscadorPage> createState() => _BuscadorPageState();
}

class _BuscadorPageState extends State<BuscadorPage> {

  List<Usuario> _usuarios = [];

  bool _loadingUsuarios = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Buscar usuarios...",
            counterText: '',
            border: InputBorder.none,
          ),
          maxLength: 200,
          /*enableSuggestions: false,
          autocorrect: false,*/
          onChanged: (text){
            _timer?.cancel();

            setState(() {
              _loadingUsuarios = true;
            });

            _timer = Timer(const Duration(milliseconds: 500), (){
              _cargarResultados(text);
            });
          },
        ),
      ),
      body: (_loadingUsuarios) ? const Center(

        child: CircularProgressIndicator(),

      ) : ListView.builder(
        itemCount: _usuarios.length,
        itemBuilder: (context, index){

          return _buildUsuario(_usuarios[index]);

        },
      ),
    );
  }

  Widget _buildUsuario(Usuario usuario){
    return ListTile(
      title: Text(usuario.nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(usuario.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: NetworkImage(usuario.foto),
      ),
      onTap: (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UserPage(usuario: usuario,)),
        );
      },
    );
  }

  Future<void> _cargarResultados(String texto) async {
    setState(() {
      _loadingUsuarios = true;
    });

    if(texto.trim() == ''){
      _usuarios.clear();
      setState(() {_loadingUsuarios = false;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlBuscador,
      queryParams: {
        "texto": texto
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _usuarios.clear();

        List<dynamic> usuarios = datosJson['data']['usuarios'];
        for (var element in usuarios) {
          _usuarios.add(Usuario(
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

    setState(() {
      _loadingUsuarios = false;
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