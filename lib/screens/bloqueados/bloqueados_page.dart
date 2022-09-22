import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class BloqueadosPage extends StatefulWidget {
  const BloqueadosPage({Key? key}) : super(key: key);

  @override
  State<BloqueadosPage> createState() => _BloqueadosPageState();
}

class _BloqueadosPageState extends State<BloqueadosPage> {

  List<Usuario> _bloqueados = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingBloqueados = false;
  bool _verMasBloqueados = false;
  String _ultimoBloqueados = "false";

  @override
  void initState() {
    super.initState();

    _cargarUsuariosBloqueados();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingBloqueados && _verMasBloqueados){
          _cargarUsuariosBloqueados();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Usuarios bloqueados"),
      ),
      body: (_bloqueados.isEmpty) ? Center(

        child: _loadingBloqueados ? CircularProgressIndicator() : const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Aquí aparecerán los usuarios que bloquees.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ),

      ) : ListView.builder(
        controller: _scrollController,
        itemCount: _bloqueados.length + 1, // +1 mostrar cargando
        itemBuilder: (context, index){
          if(index == _bloqueados.length){
            return _buildLoadingBloqueados();
          }

          return _buildUsuario(_bloqueados[index]);
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

  Widget _buildLoadingBloqueados(){
    if(_loadingBloqueados){
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Container();
    }
  }

  Future<void> _cargarUsuariosBloqueados() async {
    setState(() {
      _loadingBloqueados = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlUsuariosBloqueados,
      queryParams: {
        "ultimo_id": _ultimoBloqueados
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoBloqueados = datosJson['data']['ultimo_id'].toString();
        _verMasBloqueados = datosJson['data']['ver_mas'];

        List<dynamic> bloqueados = datosJson['data']['usuarios_bloqueados'];
        for (var element in bloqueados) {
          _bloqueados.add(Usuario(
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
      _loadingBloqueados = false;
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