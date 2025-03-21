import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/canjear_stickers/canjear_stickers_page.dart';
import 'package:tenfo/screens/settings/views/settings_contrasena_page.dart';
import 'package:tenfo/screens/settings/views/settings_cuenta_page.dart';
import 'package:tenfo/screens/settings/views/settings_cuenta_pro_page.dart';
import 'package:tenfo/screens/settings/views/settings_descripcion_page.dart';
import 'package:tenfo/screens/settings/views/settings_email_page.dart';
import 'package:tenfo/screens/settings/views/settings_feedback_page.dart';
import 'package:tenfo/screens/settings/views/settings_instagram_page.dart';
import 'package:tenfo/screens/settings/views/settings_invitaciones_page.dart';
import 'package:tenfo/screens/settings/views/settings_nacimiento_page.dart';
import 'package:tenfo/screens/settings/views/settings_nombre_page.dart';
import 'package:tenfo/screens/settings/views/settings_privacidad_page.dart';
import 'package:tenfo/screens/settings/views/settings_telefono_page.dart';
import 'package:tenfo/screens/settings/views/settings_username_page.dart';
import 'package:tenfo/screens/signup/views/signup_friends_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key, required this.usuario}) : super(key: key);

  Usuario usuario;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  bool _enviandoCerrarSesion = false;

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);
      _isAdmin = usuarioSesion.isAdmin;

      setState(() {});
    });
  }

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
              backgroundImage: CachedNetworkImageProvider(widget.usuario.foto),
            ),
          ),
          const SizedBox(height: 24,),

          /*
          _buildFila(titulo: "Invitaciones directas", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsInvitacionesPage()
            ));
          }, color: constants.blueGeneral,),
          */

          /*
          if(!Platform.isIOS)
            _buildFila(titulo: "Canjear stickers", onTap: () async {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const CanjearStickersPage()
              ));
            }, color: constants.blueGeneral,),
          */

          // Es solo para probar que esta pantalla ande bien
          if(_isAdmin)
            _buildFila(titulo: "Agregar amigos", onTap: () async {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const SignupFriendsPage()
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

          _buildFila(titulo: "Número de teléfono", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsTelefonoPage()
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

          _buildFila(titulo: "Cuenta Pro", onTap: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SettingsCuentaProPage()
            ));
          },),

          _buildFila(titulo: "Cerrar sesión", onTap: () async {
            _showDialogCerrarSesion();
          }, color: constants.redAviso,),

          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: constants.grey, width: 0.2,))),
            height: 1,
            width: double.infinity,
          ),

          const SizedBox(height: 24,),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16,),
            child: OutlinedButton.icon(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const SettingsFeedbackPage()
                ));
              },
              icon: const Icon(Icons.feedback_outlined,),
              label: const Text("Ayuda y comentarios",),
              style: OutlinedButton.styleFrom(
                primary: constants.blueGeneral,
                side: const BorderSide(color: constants.blueGeneral, width: 0.5,),
                shape: const StadiumBorder(),
              ),
            ),
          ),

          const SizedBox(height: 40,),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16,),
            alignment: Alignment.center,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: constants.grey, fontSize: 12,),
                children: [
                  TextSpan(
                    text: "Términos",
                    style: const TextStyle(decoration: TextDecoration.underline,),
                    recognizer: TapGestureRecognizer()..onTap = () async {
                      String urlString = "https://tenfo.app/politica.html";
                      Uri url = Uri.parse(urlString);

                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication,);
                      } catch (e){
                        throw 'Could not launch $urlString';
                      }
                    },
                  ),
                  const TextSpan(
                    text: " y ",
                  ),
                  TextSpan(
                    text: "Política de Privacidad",
                    style: const TextStyle(decoration: TextDecoration.underline,),
                    recognizer: TapGestureRecognizer()..onTap = () async {
                      String urlString = "https://tenfo.app/politica.html#politica-privacidad";
                      Uri url = Uri.parse(urlString);

                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication,);
                      } catch (e){
                        throw 'Could not launch $urlString';
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24,),

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