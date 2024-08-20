import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:tenfo/widgets/icon_universidad_verificada.dart';

class VerificarUniversidadPage extends StatefulWidget {
  const VerificarUniversidadPage({Key? key}) : super(key: key);

  @override
  State<VerificarUniversidadPage> createState() => _VerificarUniversidadPageState();
}

class _VerificarUniversidadPageState extends State<VerificarUniversidadPage> {

  final PageController _pageController = PageController();
  int _pageCurrent = 0;

  String? _universidadId;

  String _email = '';

  bool _enviandoEmail = false;
  final TextEditingController _emailController = TextEditingController();
  String? _emailErrorText;
  final RegExp _emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  bool _enviandoCodigo = false;
  final TextEditingController _codigoController = TextEditingController();
  String? _codigoErrorText;

  @override
  void initState() {
    super.initState();

    _emailController.text = '';
    _codigoController.text = '';

    _pageController.addListener(() {
      if(_pageController.page != null && _pageCurrent != _pageController.page!.toInt()){
        _pageCurrent = _pageController.page!.toInt();
        setState(() {});
      }
    });

    _obtenerUniversidad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const BackButtonIcon(),
          onPressed: (){
            if(_pageCurrent == 0){
              Navigator.of(context).pop();
            } else {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index){
          WidgetsBinding.instance?.focusManager.primaryFocus?.unfocus();
        },
        children: [
          _contenidoParteUno(),
          _contenidoParteDos(),
        ],
      ),
    );
  }

  Future<void> _obtenerUniversidad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);


    _universidadId = usuarioSesion.universidad_id;

    setState(() {});
  }

  Widget _contenidoParteUno(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [

          const SizedBox(height: 16,),

          const Text("¿Cuál es tu email?",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),
          const SizedBox(height: 24,),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Se enviará un código de confirmación",
              style: TextStyle(color: constants.grey,),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 16,),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "nombre@universidad.edu",
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
              onPressed: _enviandoEmail ? null : () => _validarEmail(),
              child: const Text("Enviar código"),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
              ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
            ),
          ),
          const SizedBox(height: 24,),

          Align(
            alignment: Alignment.centerLeft,
            child: _buildTextInfo(),
          ),
          const SizedBox(height: 16,),

        ],),
      ),
    );
  }

  Widget _buildTextInfo(){
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
        text: "Recuerda que la verificación solo está disponible para correos universitarios. ",
        children: [
          TextSpan(
            text: "Más información.",
            style: const TextStyle(color: constants.grey, decoration: TextDecoration.underline,),
            recognizer: TapGestureRecognizer()..onTap = (){
              _showDialogMasInformacion();
            },
          ),
        ],
      ),
    );
  }

  void _showDialogMasInformacion(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            const Text("Debes verificarte con el correo universitario de tu universidad. Esto se hace para asegurar que cada perfil "
                "sea un estudiante y aumentar la confianza entre los usuarios.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
            ),
            const SizedBox(height: 16,),
            const Text("Estos son los correos universitarios disponibles para la verificación:",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
            ),

            if(_universidadId == "9")
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 24, bottom: 24,),
                child: Text("• nombre@maimonidesvirtual.com.ar",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                ),
              ),

            if(_universidadId == "7")
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 24, bottom: 24,),
                child: Text("• nombre@ucema.edu.ar",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                ),
              ),

            if(_universidadId == "8")
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 24, bottom: 24,),
                child: Text("• nombre@alumnos.uai.edu.ar",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                ),
              ),

            if(_universidadId == "3")
              ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 24,),
                  child: Text("• nombre@palermo.edu",
                    style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16,),
                  child: Text("• nombre@palermo.edu.ar",
                    style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 24,),
                  child: Text("• nombre@up.edu.ar",
                    style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                  ),
                ),
              ],

            if(_universidadId == "4")
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 24, bottom: 24,),
                child: Text("• nombre@comunidad.ub.edu.ar",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                ),
              ),

            if(_universidadId == "1")
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 24, bottom: 24,),
                child: Text("• nombre@uade.edu.ar",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                ),
              ),

            if(_universidadId == "2")
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 24, bottom: 24,),
                child: Text("• nombre@uca.edu.ar",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                ),
              ),

          ], mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      );
    });
  }

  void _validarEmail(){
    _emailErrorText = null;

    _emailController.text = _emailController.text.trim();
    if(!_emailRegExp.hasMatch(_emailController.text)){
      _emailErrorText = 'Ingrese un email válido.';
      setState(() {});
      return;
    }

    _enviarEmail(_emailController.text);
  }

  Future<void> _enviarEmail(String email) async {
    setState(() {
      _enviandoEmail = true;
    });

    _email = email;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlConfiguracionEmailEnviarCodigo,
      body: {
        "email": email,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

      } else {

        if(datosJson['error_tipo'] == 'email_registrado'){

          _emailErrorText = 'Este email ya está registrado.';

        } else if(datosJson['error_tipo'] == 'usuario_no_habilitado'){

          _emailErrorText = 'Este email fue inhabilitado con un usuario dado de baja.';

        } else if(datosJson['error_tipo'] == 'email_no_permitido'){

          _emailErrorText = 'Este email no está disponible para verificarse. Revisa abajo en "Más información".';

        } else if(datosJson['error_tipo'] == 'email_ingresado'){

          _emailErrorText = 'Ya tienes un email vinculado a tu cuenta.';

          var email = datosJson['data']['email_actual'];
          usuarioSesion.email = email;
          prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

        } else if(datosJson['error_tipo'] == 'universidad_no_coincide'){

          _emailErrorText = 'El correo universitario no coincide con la universidad vinculada a tu cuenta.';

        } else if(datosJson['error_tipo'] == 'codigo_enviado'){

          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          _showSnackBar("Ya se envió anteriormente un código a este email. Podría estar en la sección de spam.");

        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoEmail = false;
    });
  }

  Widget _contenidoParteDos(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [
          const SizedBox(height: 16,),

          const Text("Escribe el código",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),
          const SizedBox(height: 24,),

          Align(
            alignment: Alignment.centerLeft,
            child: Text("Se envió un código a $_email\nPodría estar en la sección de spam.",
              style: const TextStyle(color: constants.grey,),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 16,),
          TextField(
            controller: _codigoController,
            decoration: InputDecoration(
              hintText: "",
              border: const OutlineInputBorder(),
              counterText: '',
              errorText: _codigoErrorText,
              errorMaxLines: 2,
            ),
            maxLength: 100,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16,),
          Container(
            constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviandoCodigo ? null : () => _verificarCodigo(),
              child: const Text("Enviar"),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
              ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
            ),
          ),
          const SizedBox(height: 16,),
        ],),
      ),
    );
  }

  Future<void> _verificarCodigo() async {
    _codigoErrorText = null;

    setState(() {
      _enviandoCodigo = true;
    });

    String codigo = _codigoController.text.trim();
    if(codigo.isEmpty){
      _codigoErrorText = 'Ingresa un código.';
      setState(() {_enviandoCodigo = false;});
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlConfiguracionEmailVerificarCodigo,
      body: {
        "email": _email,
        "codigo": codigo
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        var email = datosJson['data']['email'];

        usuarioSesion.email = email;
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));

        _showDialogVerificacionExitosa();

      } else {

        if(datosJson['error_tipo'] == 'codigo_expirado'){
          _codigoErrorText = 'El código ya expiró. Vuelve a solicitar otro.';
        } else if(datosJson['error_tipo'] == 'codigo_anulado'){
          _codigoErrorText = 'El código fue anulado. Vuelve a solicitar otro.';
        } else if(datosJson['error_tipo'] == 'codigo_incorrecto'){
          _codigoErrorText = 'Código incorrecto.';
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoCodigo = false;
    });
  }

  void _showDialogVerificacionExitosa(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [

            IconUniversidadVerificada(size: 40,),

            SizedBox(height: 24,),
            Text("¡Listo! Tu perfil ya está verificado",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16, fontWeight: FontWeight.bold,),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16,),

          ], mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      );
    }).then((value) {

      Navigator.pop(context, true);

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