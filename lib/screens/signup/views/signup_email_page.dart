import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/screens/signup/views/signup_invitation_page.dart';
import 'package:tenfo/screens/signup/views/signup_location_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class SignupEmailPage extends StatefulWidget {
  const SignupEmailPage({Key? key, this.codigoInvitacion}) : super(key: key);

  final String? codigoInvitacion;

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

  bool _tieneCodigoInvitacion = false;

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

    _tieneCodigoInvitacion = widget.codigoInvitacion != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: _tieneCodigoInvitacion
              ? _pageCurrent == 0 ? const Icon(Icons.clear) : const BackButtonIcon()
              : const BackButtonIcon(),
          onPressed: (){
            if(_pageCurrent == 0){
              if(_tieneCodigoInvitacion){
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                    builder: (context) => const WelcomePage()
                ), (route) => false);
              } else {
                Navigator.of(context).pop();
              }
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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16,),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height
              - MediaQuery.of(context).padding.top
              - MediaQuery.of(context).padding.bottom
              - kToolbarHeight,
        ),
        child: Column(children: [

          Column(children: [
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
          ]),

          Column(children: [
            if(!_tieneCodigoInvitacion)
              ...[
                const SizedBox(height: 16,),
                GestureDetector(
                  child: const Text("¿Tienes un código de invitación?",
                    style: TextStyle(color: constants.blueGeneral, decoration: TextDecoration.underline,),
                  ),
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const SignupInvitationPage(),
                    ));
                  },
                ),
              ],
            const SizedBox(height: 16,),
          ]),

        ], mainAxisAlignment: MainAxisAlignment.spaceBetween,),
      ),
    );
  }

  Widget _buildTextInfo(){
    if(_tieneCodigoInvitacion){
      return RichText(
        text: TextSpan(
          style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
          text: "Si no tienes un correo universitario habilitado, podrás registrarte si la persona que te compartió "
              "el código posee invitaciones directas sin uso. ",
          children: [
            TextSpan(
              text: "Más información.",
              style: TextStyle(color: constants.grey, decoration: TextDecoration.underline,),
              recognizer: TapGestureRecognizer()..onTap = (){
                _showDialogMasInformacionCodigoInvitacion();
              },
            ),
          ],
        ),
      );
    } else {
      return RichText(
        text: TextSpan(
          style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
          text: "Recuerda que el registro solo está disponible para correos preseleccionados y estudiantes de algunas "
              "universidades en Buenos Aires. ",
          children: [
            TextSpan(
              text: "Más información.",
              style: TextStyle(color: constants.grey, decoration: TextDecoration.underline,),
              recognizer: TapGestureRecognizer()..onTap = (){
                _showDialogMasInformacion();
              },
            ),
          ],
        ),
      );
    }
  }

  void _showDialogMasInformacion(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("Actualmente, la app tiene un registro solo con correo universitario. Esto se hace para asegurar que cada perfil "
                "sea un estudiante y aumentar la confianza entre los usuarios.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
            ),
            SizedBox(height: 16,),
            Text("Estos son los correos universitarios disponibles para el registro:",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
            ),

            Padding(
              padding: EdgeInsets.only(left: 16, top: 24,),
              child: Text("• nombre@ucema.edu.ar",
                style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16, top: 16,),
              child: Text("• nombre@comunidad.ub.edu.ar",
                style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 24,),
              child: Text("• nombre@palermo.edu",
                style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
              ),
            ),

            /*RichText(
              text: TextSpan(
                style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
                text: "Puedes revisar nuestro instagram ",
                children: [
                  TextSpan(
                    text: "@tenfo.app",
                    style: const TextStyle(color: constants.grey, decoration: TextDecoration.underline,),
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
                    text: " para ver la lista actualizada de universidades disponibles.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16,),*/

            Text("Si fuiste invitado directamente, puedes registrarte utilizando el correo que diste.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
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

  void _showDialogMasInformacionCodigoInvitacion(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: constants.blackGeneral, fontSize: 16, height: 1.3,),
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
                    text: " para ver la lista actualizada de universidades disponibles.\n\n"
                        "Si no tienes un correo universitario, pero el código que estás usando es de una persona que aún tiene "
                        "invitaciones directas, puedes registrarte con tu correo común.\nCada usuario tiene una cantidad limitada de invitaciones directas.\n\n"
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
    String origenPlataforma = "android";
    if(Platform.isIOS){
      origenPlataforma = "iOS";
    }
    String codigoInvitacion = widget.codigoInvitacion ?? "";

    var response = await HttpService.httpPost(
      url: constants.urlRegistroEnviarCodigo,
      body: {
        "email": email,
        "plataforma": origenPlataforma,
        "codigo_invitacion": codigoInvitacion
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

          if(_tieneCodigoInvitacion){
            _emailErrorText = 'Este email no está disponible para registrarse y el código no posee invitaciones directas. Revisa en "Más información".';
          } else {
            _emailErrorText = 'Este email no está disponible para registrarse. Revisa abajo en "Más información".';
          }

        } else if(datosJson['error_tipo'] == 'codigo_enviado'){

          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          _showSnackBar("Ya se envió anteriormente un código a este email. Podría estar en la sección de spam.");

        } else if(datosJson['error_tipo'] == 'codigo_invitacion_invalido'){
          _showDialogCodigoInvitacionInvalido();
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoEmail = false;
    });
  }

  void _showDialogCodigoInvitacionInvalido(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: const [
            Text("Lo sentimos, el código invitación introducido anteriormente, ya fue utilizado en estos momentos.\n\n"
                "Tendrás que ingresar otro código de invitación o hacer el registro directamente.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16, height: 1.3,),
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
    }).then((value){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) => const WelcomePage()
      ), (route) => false);
    });
  }

  Widget _contenidoParteDos(){
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [
          const SizedBox(height: 16,),

          const Text("Escribe el código",
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
            builder: (context) => SignupLocationPage(
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