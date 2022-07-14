import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/models/usuario.dart';
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/screens/user/user_page.dart';
import 'package:nuevoproyectouno/services/http_service.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class ContactosMutuosPage extends StatefulWidget {

  const ContactosMutuosPage({Key? key, required this.usuario}) : super(key: key);

  final Usuario usuario;

  @override
  State<ContactosMutuosPage> createState() => _ContactosMutuosPageState();
}

class _ContactosMutuosPageState extends State<ContactosMutuosPage> {

  List<Usuario> _contactosMutuos = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingContactosMutuos = false;
  bool _verMasContactosMutuos = false;
  String _ultimoContactosMutuos = "false";

  @override
  void initState() {
    super.initState();

    _cargarContactosMutuos();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingContactosMutuos && _verMasContactosMutuos){
          _cargarContactosMutuos();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contactos en común"),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _contactosMutuos.length + 2, // +1 mostrar texto cabecera, +1 mostrar cargando
        itemBuilder: (context, index){
          if(index == 0){
            return _buildTextoCabecera();
          }

          index = index - 1;

          if(index == _contactosMutuos.length){
            return _buildLoadingContactosMutuos();
          }

          return _buildUsuario(_contactosMutuos[index]);
        },
      ),
    );
  }

  Widget _buildTextoCabecera(){
    return const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
      child: Text("Solo puedes ver los contactos que tienen en común.",
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

  Widget _buildLoadingContactosMutuos(){
    if(_loadingContactosMutuos){
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

  Future<void> _cargarContactosMutuos() async {
    setState(() {
      _loadingContactosMutuos = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlUsuarioContactosMutuos,
      queryParams: {
        "usuario_id": widget.usuario.id,
        "ultimo_id": _ultimoContactosMutuos
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoContactosMutuos = datosJson['data']['ultimo_id'].toString();
        _verMasContactosMutuos = datosJson['data']['ver_mas'];

        List<dynamic> contactos = datosJson['data']['contactos_mutuos'];
        for (var element in contactos) {
          _contactosMutuos.add(Usuario(
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
      _loadingContactosMutuos = false;
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