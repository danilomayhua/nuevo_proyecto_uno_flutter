import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/screens/signup/views/signup_profile_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class SignupEmailPage extends StatefulWidget {
  const SignupEmailPage({Key? key}) : super(key: key);

  @override
  State<SignupEmailPage> createState() => _SignupEmailPageState();
}

class _SignupEmailPageState extends State<SignupEmailPage> {

  final PageController _pageController = PageController();
  int _pageCurrent = 0;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: BackButton(
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

  Widget _contenidoParteUno(){
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [
          const SizedBox(height: 16,),

          Text("¿Cuál es tu email?",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),
          const SizedBox(height: 24,),

          Align(
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
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                // TODO : cambiar texto para Android
                /*text: "Recuerda que la app está en versión beta. El registro solo está disponible para correos preseleccionados "
                    "y estudiantes de algunas universidades en Buenos Aires. ",*/
                text: "Recuerda que el registro solo está disponible para correos preseleccionados y estudiantes de algunas "
                    "universidades en Buenos Aires. ",
                children: [
                  TextSpan(
                    text: "Más información.",
                    style: TextStyle(color: constants.blueGeneral, decoration: TextDecoration.underline,),
                    recognizer: TapGestureRecognizer()..onTap = (){
                      _showDialogMasInformacion();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16,),
        ],),
      ),
    );
  }

  void _showDialogMasInformacion(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: constants.blackGeneral, fontSize: 16, height: 1.3,),
                // TODO : cambiar texto para Android
                /*text: "Actualmente, la app está en versión beta y tiene un registro cerrado. Queremos dar una buena experiencia, ayudar "
                    "en la veracidad de los perfiles dentro y generar confianza entre los usuarios.\n\n"
                    "Si tienes un correo universitario de los disponibles, puedes registrarte. Puedes revisar nuestro "
                    "instagram ",*/
                text: "Actualmente, la app tiene un registro cerrado. Queremos dar una buena experiencia, ayudar "
                    "en la veracidad de los perfiles dentro y generar confianza entre los usuarios.\n\n"
                    "Si tienes un correo universitario de los disponibles, puedes registrarte. Puedes revisar nuestro "
                    "instagram ",
                children: [
                  TextSpan(
                    text: "@tenfo.app",
                    style: TextStyle(color: constants.grey, decoration: TextDecoration.underline,),
                    recognizer: TapGestureRecognizer()..onTap = () async {
                      String urlString = "https://www.instagram.com/tenfo.app";
                      Uri url = Uri.parse(urlString);

                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication,);
                      } catch (e){
                        throw 'Could not launch $urlString';
                      }
                    },
                  ),
                  const TextSpan(
                    text: " para ver la lista actualizada de universidades disponibles.\n"
                        "Si fuiste invitado directamente, puedes registrarte con el correo que diste.\n\n"
                        "Gracias por la comprensión.",
                  ),
                ],
              ),
            ),
          ], mainAxisSize: MainAxisSize.min,),
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

    var response = await HttpService.httpPost(
      url: constants.urlRegistroEnviarCodigo,
      body: {
        "email": email
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

      } else {

        if(datosJson['error_tipo'] == 'email_registrado'){
          _emailErrorText = 'Este email ya está registrado.';
        } else if(datosJson['error_tipo'] == 'email_no_permitido'){
          _emailErrorText = 'Este email no está disponible para registrarse. Revisa abajo en "Más información".';
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
        padding: EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [
          const SizedBox(height: 16,),

          Text("Escribe el código",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),
          const SizedBox(height: 24,),

          Align(
            alignment: Alignment.centerLeft,
            child: Text("Se envió un código a $_email\nPodría estar en la sección de spam.",
              style: TextStyle(color: constants.grey, /*fontSize: 12,*/),
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

    var response = await HttpService.httpPost(
      url: constants.urlRegistroVerificarCodigo,
      body: {
        "email": _email,
        "codigo": codigo
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        String registroActivadoToken = datosJson['data']['registro_activado_token'];

        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => SignupProfilePage(
              email: _email,
              codigo: codigo,
              registroActivadoToken: registroActivadoToken,
            )
        ));

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

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}