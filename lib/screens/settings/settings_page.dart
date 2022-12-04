import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/canjear_stickers/canjear_stickers_page.dart';
import 'package:tenfo/screens/settings/views/settings_contrasena_page.dart';
import 'package:tenfo/screens/settings/views/settings_cuenta_page.dart';
import 'package:tenfo/screens/settings/views/settings_descripcion_page.dart';
import 'package:tenfo/screens/settings/views/settings_email_page.dart';
import 'package:tenfo/screens/settings/views/settings_instagram_page.dart';
import 'package:tenfo/screens/settings/views/settings_invitaciones_page.dart';
import 'package:tenfo/screens/settings/views/settings_nacimiento_page.dart';
import 'package:tenfo/screens/settings/views/settings_nombre_page.dart';
import 'package:tenfo/screens/settings/views/settings_privacidad_page.dart';
import 'package:tenfo/screens/settings/views/settings_username_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key, required this.usuario}) : super(key: key);

  Usuario usuario;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  bool _enviandoCerrarSesion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurar cuenta"),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 16,),

          ListTile(
            title: Text(widget.usuario.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(widget.usuario.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: CircleAvatar(
              backgroundColor: constants.greyBackgroundImage,
              backgroundImage: NetworkImage(widget.usuario.foto),
            ),
          ),
          const SizedBox(height: 24,),

          _buildFila(titulo: "Invitaciones", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsInvitacionesPage()
            ));
          }, color: constants.blueGeneral,),

          if(!Platform.isIOS)
            _buildFila(titulo: "Canjear stickers", onTap: () async {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const CanjearStickersPage()
              ));
            }, color: constants.blueGeneral,),

          _buildFila(titulo: "Descripción", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsDescripcionPage()
            ));
          },),

          _buildFila(titulo: "Instagram", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsInstagramPage()
            ));
          },),

          _buildFila(titulo: "Privacidad", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsPrivacidadPage()
            ));
          },),

          _buildFila(titulo: "Usuario", onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsUsernamePage()
            ));
          },),

          _buildFila(titulo: "Nombre", onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsNombrePage()
            ));
          },),

          _buildFila(titulo: "Cumpleaños", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsNacimientoPage()
            ));
          },),

          _buildFila(titulo: "Email", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsEmailPage()
            ));
          },),

          _buildFila(titulo: "Contraseña", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsContrasenaPage()
            ));
          },),

          _buildFila(titulo: "Cuenta", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsCuentaPage()
            ));
          },),

          _buildFila(titulo: "Cerrar sesión", onTap: () async {
            _showDialogCerrarSesion();
          }, color: constants.redAviso,),

          const SizedBox(height: 16,),

        ],),
      ),
    );
  }

  Widget _buildFila({required String titulo, required Future<void> Function() onTap, Color? color}){
    return ListTile(
      title: Text(titulo, style: TextStyle(color: color),),
      onTap: () async {
        await onTap();

        // Actualiza los datos, por si hubo algun cambio
        SharedPreferences.getInstance().then((prefs){
          UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

          widget.usuario = Usuario(
            id: usuarioSesion.id,
            nombre: usuarioSesion.nombre_completo,
            username: usuarioSesion.username,
            foto: usuarioSesion.foto,
          );

          setState(() {});
        });

      },
      shape: const Border(top: BorderSide(color: constants.grey, width: 0.2,),),
    );
  }

  void _showDialogCerrarSesion(){
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('¿Seguro que quieres salir de tu cuenta?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: _enviandoCerrarSesion ? null : () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Cerrar sesión'),
              style: TextButton.styleFrom(
                primary: constants.redAviso,
              ),
              onPressed: _enviandoCerrarSesion ? null : () => _cerrarSesion(setStateDialog),
            ),
          ],
        );
      });
    });
  }

  Future<void> _cerrarSesion(setStateDialog) async {
    setStateDialog(() {
      _enviandoCerrarSesion = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    String? firebaseToken;
    try {
      firebaseToken = await FirebaseMessaging.instance.getToken();
    } catch(e) {
      //
    }

    var response = await HttpService.httpPost(
      url: constants.urlLogout,
      body: {
        "firebase_token": firebaseToken ?? ""
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool logout = await prefs.clear();

        if(logout){
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (context) => const WelcomePage()
          ), (route) => false);
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setStateDialog(() {
      _enviandoCerrarSesion = false;
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