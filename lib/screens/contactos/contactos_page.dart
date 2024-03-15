import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/buscador/buscador_page.dart';
import 'package:tenfo/screens/contactos_sugerencias/contactos_sugerencias_page.dart';
import 'package:tenfo/screens/crear_actividad/crear_actividad_page.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/share_utils.dart';

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
        automaticallyImplyLeading: false,
        title: const Text("Amigos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BuscadorPage()));
            },
          ),
        ],
      ),
      body: (_contactos.isEmpty) ? Center(

        child: _loadingContactos ? CircularProgressIndicator() : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            const Text("No tienes amigos agregados aún.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8,),
            const Text("Agrega amigos para descubrir vínculos en común con personas en las actividades.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48,),
            _buildBotonInvitar(),
          ], mainAxisSize: MainAxisSize.min,),
        ),

      ) : ListView.builder(
        controller: _scrollController,
        itemCount: _contactos.length + 2, // +1 mostrar texto cabecera, +1 mostrar cargando o boton
        itemBuilder: (context, index){
          if(index == 0){
            return _buildTextoCabecera();
          }

          index = index - 1;

          if(index == _contactos.length){
            if(_loadingContactos){
              return _buildLoadingContactos();
            } else {
              return Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 24,),
                child: _buildBotonInvitar(),
              );
            }
          }

          return _buildUsuario(_contactos[index]);
        },
      ),
    );
  }

  Widget _buildBotonInvitar(){
    return Container(
      constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
      child: OutlinedButton.icon(
        onPressed: (){
          //ShareUtils.shareProfile();
          // Envia historial del usuario
          //_enviarHistorialUsuario(HistorialUsuario.getContactosInvitarAmigo());

          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const ContactosSugerenciasPage(),
          ));
        },
        icon: const Icon(Icons.person_add),
        label: const Text("Agregar amigos",
          style: TextStyle(fontSize: 14,),
        ),
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _buildTextoCabecera(){
    return const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
      child: Text("Agrega amigos para descubrir vínculos en común con personas en las actividades. Solo tú puedes ver tu lista completa de amigos.",
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
        backgroundImage: CachedNetworkImageProvider(usuario.foto),
      ),
      onTap: (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UserPage(usuario: usuario,)),
        );
      },
      trailing: IconButton(
        icon: const Icon(Icons.groups_outlined, color: constants.blackGeneral,),
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => CrearActividadPage(cocreadorUsuario: usuario,),
          ));
        },
      ),
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