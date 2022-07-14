import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/models/usuario.dart';
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/screens/user/user_page.dart';
import 'package:nuevoproyectouno/services/http_service.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class ContactosPage extends StatefulWidget {
  const ContactosPage({Key? key}) : super(key: key);

  @override
  State<ContactosPage> createState() => _ContactosPageState();
}

class _ContactosPageState extends State<ContactosPage> {

  List<Usuario> _contactos = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingContactos = false;
  bool _verMasContactos = false;
  String _ultimoContactos = "false";

  @override
  void initState() {
    super.initState();

    _cargarContactos();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingContactos && _verMasContactos){
          _cargarContactos();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contactos"),
      ),
      body: (_contactos.isEmpty) ? Center(

        child: _loadingContactos ? CircularProgressIndicator() : const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("No tienes contactos aún.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ),

      ) : ListView.builder(
        controller: _scrollController,
        itemCount: _contactos.length + 2, // +1 mostrar texto cabecera, +1 mostrar cargando
        itemBuilder: (context, index){
          if(index == 0){
            return _buildTextoCabecera();
          }

          index = index - 1;

          if(index == _contactos.length){
            return _buildLoadingContactos();
          }

          return _buildUsuario(_contactos[index]);
        },
      ),
    );
  }

  Widget _buildTextoCabecera(){
    return const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
      child: Text("Solo tú puedes ver tu lista completa de contactos. Otros usuarios pueden ver únicamente los contactos que tienen en común.",
        style: TextStyle(color: constants.grey, fontSize: 12,),
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

  Widget _buildLoadingContactos(){
    if(_loadingContactos){
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

  Future<void> _cargarContactos() async {
    setState(() {
      _loadingContactos = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlMisContactos,
      queryParams: {
        "ultimo_id": _ultimoContactos
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoContactos = datosJson['data']['ultimo_id'].toString();
        _verMasContactos = datosJson['data']['ver_mas'];

        List<dynamic> contactos = datosJson['data']['contactos'];
        for (var element in contactos) {
          _contactos.add(Usuario(
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
      _loadingContactos = false;
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