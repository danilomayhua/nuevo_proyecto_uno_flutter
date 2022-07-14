import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/models/usuario.dart';
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/screens/user/user_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilPage extends StatefulWidget {
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {

  Usuario? _usuario;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _usuario = Usuario(
        id: usuarioSesion.id,
        nombre: usuarioSesion.nombre_completo,
        username: usuarioSesion.username,
        foto: usuarioSesion.foto,
      );

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return _usuario != null
        ? UserPage(usuario: _usuario!, isFromProfile: true,)
        : Container();
  }
}