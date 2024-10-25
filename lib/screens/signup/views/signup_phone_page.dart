import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:tenfo/models/signup_permisos_estado.dart';
import 'package:tenfo/screens/signup/views/signup_profile_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class SignupPhonePage extends StatefulWidget {
  const SignupPhonePage({Key? key, required this.universidadId, required this.signupPermisosEstado}) : super(key: key);

  final String universidadId;
  final SignupPermisosEstado signupPermisosEstado;

  @override
  State<SignupPhonePage> createState() => _SignupPhonePageState();
}

class _SignupPhonePageState extends State<SignupPhonePage> with SingleTickerProviderStateMixin {

  final PageController _pageController = PageController();
  int _pageCurrent = 0;

  late TabController _tabController;

  bool _enviandoTelefonoOEmail = false;

  String _telefonoText = '';
  String _telefonoE164 = '';
  PhoneNumber? _phoneNumber = PhoneNumber(isoCode: 'AR');
  final TextEditingController _telefonoController = TextEditingController();
  String? _telefonoErrorText;

  String _email = '';
  final RegExp _emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  final TextEditingController _emailController = TextEditingController();
  String? _emailErrorText;

  bool _isRegistroEmail = false;

  bool _enviandoCodigo = false;
  final TextEditingController _codigoController = TextEditingController();
  String? _codigoErrorText;

  @override
  void initState() {
    super.initState();

    _telefonoController.text = '';
    _codigoController.text = '';

    _pageController.addListener(() {
      if(_pageController.page != null && _pageCurrent != _pageController.page!.toInt()){
        _pageCurrent = _pageController.page!.toInt();
        setState(() {});
      }
    });

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
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
        title: const Text("Registrarse", style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16,),),
        centerTitle: true,
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Teléfono"),
            Tab(text: "Email"),
          ],
          labelColor: constants.blackGeneral,
          padding: const EdgeInsets.symmetric(horizontal: 16,),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _contenidoTelefono(),
              _contenidoEmail(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contenidoTelefono(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [

          /*const SizedBox(height: 16,),

          const Text("¿Cuál es tu número?",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),*/
          const SizedBox(height: 24,),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Registrate con tu número de teléfono. Se enviará un código de confirmación.",
              style: TextStyle(color: constants.grey,),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 24,),


          InternationalPhoneNumberInput(
            onInputChanged: (PhoneNumber number) {
              _phoneNumber = number;
            },
            onInputValidated: (value){
              // Valida si es un numero correcto o no
            },
            selectorConfig: const SelectorConfig(
              selectorType: PhoneInputSelectorType.DIALOG,
              setSelectorButtonAsPrefixIcon: true,
              leadingPadding: 16,
              useEmoji: true,
              trailingSpace: true,
            ),
            initialValue: _phoneNumber,
            textFieldController: _telefonoController,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            inputDecoration: InputDecoration(
              hintText: "Número de teléfono",
              border: const OutlineInputBorder(),
              counterText: '',
              errorText: _telefonoErrorText,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 24,),

          Container(
            constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviandoTelefonoOEmail ? null : () => _validarTelefono(),
              child: const Text("Enviar código"),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
              ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
            ),
          ),
          const SizedBox(height: 24,),

        ],),
      ),
    );
  }

  Future<void> _validarTelefono() async {
    if(_enviandoTelefonoOEmail) return;
    _enviandoTelefonoOEmail = true;

    _telefonoErrorText = null;


    if(_phoneNumber == null){
      _enviandoTelefonoOEmail = false;
      return;
    }

    PhoneNumber phoneNumber = _phoneNumber!;
    _telefonoText = _telefonoController.text.trim();

    if(_telefonoText == ""){
      _enviandoTelefonoOEmail = false;
      return;
    }

    if(phoneNumber.parseNumber() == ""){
      _enviandoTelefonoOEmail = false;
      return;
    }


    String telefonoE164 = phoneNumber.phoneNumber ?? ""; // Devuelve en formato E.164, transforma el "15" a "9"

    if (telefonoE164.startsWith("+54")) {
      if (!telefonoE164.startsWith("+549")) {
        telefonoE164 = telefonoE164.replaceFirst("+54", "+549");
      }
    }

    _enviarTelefono(telefonoE164);
  }

  Future<void> _enviarTelefono(String telefonoE164) async {
    setState(() {
      _enviandoTelefonoOEmail = true;
    });

    _telefonoE164 = telefonoE164;
    String origenPlataforma = "android";
    if(Platform.isIOS){
      origenPlataforma = "iOS";
    }

    var response = await HttpService.httpPost(
      url: constants.urlRegistroTelefonoEnviarCodigo,
      body: {
        "telefono": telefonoE164,
        "plataforma": origenPlataforma,
        "universidad_id": widget.universidadId,
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _isRegistroEmail = false;
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

      } else {

        if(datosJson['error_tipo'] == 'telefono_invalido'){

          _telefonoErrorText = 'Formato de número de teléfono inválido.';

        } else if(datosJson['error_tipo'] == 'telefono_ubicacion_invalido'){

          _telefonoErrorText = 'Lo sentimos, la región de este número no está disponible para el registro.';

        } else if(datosJson['error_tipo'] == 'telefono_registrado'){

          _telefonoErrorText = 'Este número ya está registrado.';

        } else if(datosJson['error_tipo'] == 'usuario_no_habilitado'){

          _telefonoErrorText = 'Este número fue inhabilitado con un usuario dado de baja.';

        } else if(datosJson['error_tipo'] == 'codigo_enviado'){

          String? minutosFaltantes = datosJson['data']['minutos_faltantes']?.toString();
          String? segundosFaltantes = datosJson['data']['segundos_faltantes']?.toString();

          _isRegistroEmail = false;
          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          if(segundosFaltantes != null){
            _showSnackBar("Ya se envió anteriormente un código a este número. Debes esperar $segundosFaltantes segundos para volver a pedir otro.");
          } else {
            _showSnackBar("Ya se envió anteriormente un código a este número. Debes esperar $minutosFaltantes minutos para volver a pedir otro.");
          }

        } else if(datosJson['error_tipo'] == 'limite_registros'){

          _telefonoErrorText = 'Error';
          _showSnackBar("En estos momentos no están habilitados nuevos registros. Por favor comunícate con nosotros para notificarte cuando vuelva a habilitarse.");

        } else if(datosJson['error_tipo'] == 'limite_codigo_confirmado'){

          _telefonoErrorText = 'Debes esperar un tiempo para poder registrarte con este número.';

        } else if(datosJson['error_tipo'] == 'limite_tiempo_segundos'){

          _telefonoErrorText = 'Tienes que esperar unos segundos para volver a intentar.';

        } else if(datosJson['error_tipo'] == 'limite_tiempo_minutos'){

          _telefonoErrorText = 'Error con tu conexión. Tienes que esperar unos minutos para volver a intentar.';

        } else if(datosJson['error_tipo'] == 'limite_tiempo_horas'){

          _telefonoErrorText = 'Error con tu conexión. Por el momento no tienes permitido el registro.';

        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoTelefonoOEmail = false;
    });
  }

  Widget _contenidoEmail(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [

          const SizedBox(height: 24,),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Registrate con tu email. Se enviará un código de confirmación.",
              style: TextStyle(color: constants.grey,),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 24,),

          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Email",
              border: const OutlineInputBorder(),
              counterText: '',
              errorText: _emailErrorText,
              errorMaxLines: 2,
            ),
            maxLength: 100,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24,),

          Container(
            constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enviandoTelefonoOEmail ? null : () => _validarEmail(),
              child: const Text("Enviar código"),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
              ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
            ),
          ),
          const SizedBox(height: 24,),

        ],),
      ),
    );
  }

  Future<void> _validarEmail() async {
    if(_enviandoTelefonoOEmail) return;
    _enviandoTelefonoOEmail = true;

    _emailErrorText = null;

    _emailController.text = _emailController.text.trim();
    if(!_emailRegExp.hasMatch(_emailController.text)){
      _emailErrorText = 'Ingrese un email válido.';
      _enviandoTelefonoOEmail = false;
      setState(() {});
      return;
    }

    _enviarEmail(_emailController.text);
  }

  Future<void> _enviarEmail(String email) async {
    setState(() {
      _enviandoTelefonoOEmail = true;
    });

    _email = email;
    String origenPlataforma = "android";
    if(Platform.isIOS){
      origenPlataforma = "iOS";
    }

    var response = await HttpService.httpPost(
      url: constants.urlRegistroEmailEnviarCodigo,
      body: {
        "email": email,
        "plataforma": origenPlataforma,
        "universidad_id": widget.universidadId,
        "dispositivo_id": "INDEFINIDO", // De momento enviar "INDEFINIDO", hasta agregar un id unico por dispositivo
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _isRegistroEmail = true;
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

      } else {

        if(datosJson['error_tipo'] == 'email_registrado'){

          _emailErrorText = 'Este email ya está registrado.';

        } else if(datosJson['error_tipo'] == 'usuario_no_habilitado'){

          _emailErrorText = 'Este email fue inhabilitado con un usuario dado de baja.';

        } else if(datosJson['error_tipo'] == 'codigo_enviado'){

          String? minutosFaltantes = datosJson['data']['minutos_faltantes']?.toString();
          String? segundosFaltantes = datosJson['data']['segundos_faltantes']?.toString();

          _isRegistroEmail = true;
          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          if(segundosFaltantes != null){
            _showSnackBar("Ya se envió anteriormente un código a este email. Debes esperar $segundosFaltantes segundos para volver a pedir otro.");
          } else {
            _showSnackBar("Ya se envió anteriormente un código a este email. Debes esperar $minutosFaltantes minutos para volver a pedir otro.");
          }

        } else if(datosJson['error_tipo'] == 'limite_codigo_confirmado'){

          _emailErrorText = 'Debes esperar un tiempo para poder registrarte con este email.';

        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoTelefonoOEmail = false;
    });
  }

  Widget _contenidoParteDos(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: Column(children: [
          const SizedBox(height: 24,),

          const Text("Escribe el código",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),
          const SizedBox(height: 24,),

          if(!_isRegistroEmail)
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Se envió un código a ${_phoneNumber?.dialCode ?? ""} $_telefonoText",
                style: const TextStyle(color: constants.grey,),
                textAlign: TextAlign.left,
              ),
            ),
          if(_isRegistroEmail)
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Se envió un código a $_email\nPodría estar en la sección de spam.",
                style: TextStyle(color: constants.grey,),
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
          const SizedBox(height: 24,),

          GestureDetector(
            child: const Text("¿No recibiste el código?",
              style: TextStyle(color: constants.grey, decoration: TextDecoration.underline, fontSize: 12,),
            ),
            onTap: (){
              _showDialogCodigoNoRecibido();
            },
          ),
          const SizedBox(height: 16,),

        ],),
      ),
    );
  }

  void _showDialogCodigoNoRecibido(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
                text: "Comprueba tu señal o espera unos segundos e ingresa el ${_isRegistroEmail ? "email" : "número"} nuevamente desde la pantalla anterior.\n\n"
                    "Si continúas sin recibir el código, por favor comunícate con nosotros para poder resolverlo a través de nuestro instagram ",
                children: [
                  TextSpan(
                    text: "@tenfo_social",
                    style: const TextStyle(color: constants.grey,),
                    recognizer: TapGestureRecognizer()..onTap = () async {
                      String urlString = "https://www.instagram.com/tenfo_social";
                      Uri url = Uri.parse(urlString);

                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication,);
                      } catch (e){
                        throw 'Could not launch $urlString';
                      }
                    },
                  ),
                  const TextSpan(
                    text: " o email ",
                  ),
                  TextSpan(
                    text: "soporte@tenfo.app",
                    style: const TextStyle(color: constants.grey,),
                    recognizer: TapGestureRecognizer()..onTap = () async {
                      String urlString = "mailto:soporte@tenfo.app?subject=Consultas sobre crear cuenta en Tenfo";
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

    bool isRegistroEmail = _isRegistroEmail;

    String urlVerificarCodigo = isRegistroEmail ? constants.urlRegistroEmailVerificarCodigo : constants.urlRegistroTelefonoVerificarCodigo;
    var response = await HttpService.httpPost(
      url: urlVerificarCodigo,
      body: {
        "telefono": isRegistroEmail ? null : _telefonoE164,
        "email": isRegistroEmail ? _email : null,
        "codigo": codigo,
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        String registroActivadoToken = datosJson['data']['registro_activado_token'];

        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => SignupProfilePage(
              isRegistroEmail: isRegistroEmail,
              telefono: _telefonoE164,
              email: _email,
              codigo: codigo,
              registroActivadoToken: registroActivadoToken,
              universidadId: widget.universidadId,
              signupPermisosEstado: widget.signupPermisosEstado,
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