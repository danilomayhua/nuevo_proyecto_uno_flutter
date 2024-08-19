import 'package:flutter/material.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilPage extends StatefulWidget {
  PerfilPage({Key? key, required this.visitasInstagramNuevos, required this.onChangeVisitasInstagramNuevos}) : super(key: key);

  int visitasInstagramNuevos;
  void Function(int) onChangeVisitasInstagramNuevos;

  @override
  State<PerfilPage> createState() => PerfilPageState();
}

class PerfilPageState extends State<PerfilPage> {

  final GlobalKey<UserPageState> _keyUserPage = GlobalKey();

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
        ? UserPage(
          key: _keyUserPage,
          usuario: _usuario!,
          isFromProfile: true,
          visitasInstagramNuevos: widget.visitasInstagramNuevos,
          onChangeVisitasInstagramNuevos: (value){
            widget.onChangeVisitasInstagramNuevos(value);
          },
        )
        : Container();
  }

  void setVisitasInstagramNuevos(int value){
    setState(() {
      widget.visitasInstagramNuevos = value;
    });
    if(_keyUserPage.currentState != null){
      _keyUserPage.currentState!.setVisitasInstagramNuevos(value);
    }
  }
}