import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SettingsInvitacionesPage extends StatefulWidget {
  const SettingsInvitacionesPage({Key? key}) : super(key: key);

  @override
  State<SettingsInvitacionesPage> createState() => _SettingsInvitacionesPageState();
}

class _SettingsInvitacionesPageState extends State<SettingsInvitacionesPage> {

  final RegExp _emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  final TextEditingController _emailController = TextEditingController(text: '');
  String? _emailErrorText;

  bool _enviando = false;

  bool _loadingNumeroInvitaciones = false;
  int _numeroInvitaciones = 0;
  String _email = "";

  @override
  void initState() {
    super.initState();

    _cargarInvitacionesDisponibles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invitaciones directas"),
      ),
      body: (_numeroInvitaciones == 0) ? Center(

        child: _loadingNumeroInvitaciones ? CircularProgressIndicator() : const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("No tienes invitaciones directas disponibles para usar. Desde aquí se habilita el registro a amigos ingresando su email.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ),

      ) : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            const Text("¡Invita a tus amigos que no tienen email universitario! Podrán entrar con una invitación directa tuya. Ingresa un email común de tu invitado "
                "y ya podrá registrarse con el mismo.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
            ),
            const SizedBox(height: 8,),
            const Text("Aquí hay algunas consideraciones a tener en cuenta:",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16,),
              child: Text("• Actualmente, la app solo está disponible en Buenos Aires.",
                style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16,),
              child: Text("• Al no usar un email universitario, los usuarios invitados no tendrán la verificación de universidad en su perfil.",
                style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16,),
              child: Text("• Elige bien a quiénes compartes las invitaciones. Recomendamos que sean amigos con quienes cocrearan actividades.",
                style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
              ),
            ),
            const SizedBox(height: 32,),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Email de invitado",
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _emailErrorText,
                errorMaxLines: 2,
              ),
              maxLength: 100,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : () => _enviarInvitado(),
                child: const Text("Enviar"),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),
            const SizedBox(height: 8,),

            Align(
              alignment: Alignment.center,
              child: Text("Tienes $_numeroInvitaciones invitaciones restantes",
                style: TextStyle(color: constants.grey, fontSize: 12,),
              ),
            ),
            const SizedBox(height: 16,),
          ], crossAxisAlignment: CrossAxisAlignment.start,),
        ),
      ),
    );
  }

  Future<void> _cargarInvitacionesDisponibles() async {
    setState(() {
      _loadingNumeroInvitaciones = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlInvitacionCantidadDisponible,
      queryParams: {},
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _numeroInvitaciones = datosJson['data']['invitaciones_disponibles'];

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingNumeroInvitaciones = false;
    });
  }

  Future<void> _enviarInvitado() async {
    _emailErrorText = null;

    setState(() {
      _enviando = true;
    });

    _emailController.text = _emailController.text.trim();
    _email = _emailController.text;
    if(!_emailRegExp.hasMatch(_emailController.text)){
      _emailErrorText = 'Ingrese un email válido.';
      setState(() {_enviando = false;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlInvitacionHabilitarEmail,
      body: {
        "email": _email
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _emailController.text = _email;
        _numeroInvitaciones = datosJson['data']['invitaciones_disponibles'];
        _showDialogInvitadoHabilitado();

      } else {

        if(datosJson['error_tipo'] == 'email_registrado'){
          _emailErrorText = 'El email ya está registrado.';
        } else if(datosJson['error_tipo'] == 'email_permitido'){
          _emailErrorText = 'Este email ya tiene permitido registrarse. Avisarle al propietario.';
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviando = false;
    });
  }

  void _showDialogInvitadoHabilitado(){
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text("¡Tu invitado ya se puede registrar con el email $_email!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      );
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