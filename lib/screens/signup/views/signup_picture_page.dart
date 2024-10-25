import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/signup_permisos_estado.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/signup/views/signup_friends_page.dart';
import 'package:tenfo/screens/signup/views/signup_tutorial_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class SignupPicturePage extends StatefulWidget {
  const SignupPicturePage({Key? key, required this.isFromSignup, this.signupPermisosEstado}) : super(key: key);

  final bool isFromSignup;
  final SignupPermisosEstado? signupPermisosEstado;

  @override
  State<SignupPicturePage> createState() => _SignupPicturePageState();
}

class _SignupPicturePageState extends State<SignupPicturePage> {

  bool _isAvailableBotonOmitir = false;

  bool _enviandoFotoPerfil = false;

  @override
  void initState() {
    super.initState();

    _checkShowBotonOmitir();

    if(widget.isFromSignup){

      // Envia historial del usuario
      _enviarHistorialUsuario(HistorialUsuario.getAgregarFoto(widget.signupPermisosEstado));

    } else {
      // Envia historial del usuario
      _enviarHistorialUsuario(HistorialUsuario.getAgregarFoto(null));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if(_isAvailableBotonOmitir)
            TextButton(
              onPressed: () async {
                // Envia historial del usuario
                _enviarHistorialUsuario(HistorialUsuario.getAgregarFotoOmitir());

                // Si usa el boton Omitir, no lo muestra la proxima vez
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setInt(SharedPreferencesKeys.totalIntentosAgregarFoto, 0);

                _continuarRegistro();
              },
              child: const Text("Omitir"),
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            const Text("Foto de perfil",
              style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
            ),
            const SizedBox(height: 24,),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("¡Listo para empezar! Completa tu perfil con una foto de perfil tuya.",
                style: TextStyle(color: constants.grey,),
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 48,),

            Container(
              child: GestureDetector(
                onTap: _enviandoFotoPerfil ? null : () => _galleryPhoto(),
                child: _enviandoFotoPerfil
                    ? const CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.transparent,
                      child: CircularProgressIndicator(),
                    )
                    : const CircleAvatar(
                      radius: 80,
                      backgroundColor: constants.greyBackgroundImage,
                      child: Icon(Icons.photo_camera, size: 32, color: constants.blackGeneral,),
                    ),
              ),
            ),

            const SizedBox(height: 48,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviandoFotoPerfil ? null : () => _galleryPhoto(),
                child: const Text("Agregar foto"),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),
            const SizedBox(height: 16,),
          ],),
        ),
      ),
    );
  }

  Future<void> _checkShowBotonOmitir() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int totalIntentosFoto = prefs.getInt(SharedPreferencesKeys.totalIntentosAgregarFoto) ?? 0;

    // Puede haber un error(cierra la app) al abrir galeria en algunos dispositivos
    // Si despues de 15 intentos aun no agrego la foto, permitir omitir esta pantalla
    if(totalIntentosFoto >= 15){
      _isAvailableBotonOmitir = true;
      setState(() {});
    }
  }

  Future<void> _galleryPhoto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int totalIntentosFoto = prefs.getInt(SharedPreferencesKeys.totalIntentosAgregarFoto) ?? 0;
    prefs.setInt(SharedPreferencesKeys.totalIntentosAgregarFoto, totalIntentosFoto + 1);


    XFile? image;
    
    try {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch(e) {
      if(e is PlatformException && e.code == 'photo_access_denied'){
        _showSnackBar("Los permisos están denegados. Permite el acceso a la galería desde Ajustes en la app.");
        return;
      } else {
        //
      }
    }

    if (image != null) {
      _enviandoFotoPerfil = true;
      setState(() {});

      _cropImage(image);
    }
  }

  Future<void> _cropImage(XFile image) async {

    int imageLength = await image.length();
    int limit = 3000000; // 3MB aprox

    File? fileCropped;

    if(imageLength > limit){
      fileCropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1,),
        cropStyle: CropStyle.circle,
        compressQuality: 50,
      );
    } else {
      fileCropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1,),
        cropStyle: CropStyle.circle,
      );
    }

    if(fileCropped == null){
      _enviandoFotoPerfil = false;
      setState(() {});
      return;
    }

    int fileCroppedLength = fileCropped.lengthSync();
    if(fileCroppedLength > limit){

      _showSnackBar("La imagen es muy pesada. Por favor elija otra.");
      _enviandoFotoPerfil = false;
      setState(() {});

    } else {
      _guardarFoto(fileCropped);
    }
  }

  Future<void> _guardarFoto(File imageFile) async {
    setState(() {
      _enviandoFotoPerfil = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpMultipart(
      url: constants.urlCambiarFotoPerfil,
      field: 'foto_perfil',
      file: imageFile,
      usuarioSesion: usuarioSesion,
      additionalFields: {
        "enviado_desde" : "registro",
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        String fotoUrl = constants.urlBase + datosJson['data']['foto_url_nuevo'];

        // Al cambiar la logica aqui, cambiar tambien en UserPage
        usuarioSesion.foto = fotoUrl;
        usuarioSesion.isUsuarioSinFoto = false;
        await prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

        _continuarRegistro();

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoFotoPerfil = false;
    });
  }

  void _continuarRegistro(){

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
        builder: (context) => const SignupTutorialPage()
    ), (root) => false);

    /*if(widget.isFromSignup){

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) => const PrincipalPage(principalPageView: PrincipalPageView.home, isFromSignup: true,)
      ), (root) => false);

    } else {

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) => const PrincipalPage()
      ), (root) => false);

    }*/
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