import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:tenfo/screens/restablecer_contrasena/views/restablecer_contrasena_nuevacontrasena_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class RestablecerContrasenaPage extends StatefulWidget {
  const RestablecerContrasenaPage({Key? key, this.isEmailSeleccionado = false}) : super(key: key);

  final bool isEmailSeleccionado;

  @override
  State<RestablecerContrasenaPage> createState() => _RestablecerContrasenaPageState();
}

class _RestablecerContrasenaPageState extends State<RestablecerContrasenaPage> {

  final PageController _pageController = PageController();
  int _pageCurrent = 0;

  String _telefonoText = '';
  String _telefonoE164 = '';
  PhoneNumber? _phoneNumber = PhoneNumber(isoCode: 'AR');
  final TextEditingController _telefonoController = TextEditingController();
  String? _telefonoErrorText;

  String _email = '';
  final RegExp _emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  final TextEditingController _emailController = TextEditingController();
  String? _emailErrorText;

  bool _enviandoMedioContacto = false;

  bool _enviandoCodigo = false;
  final TextEditingController _codigoController = TextEditingController();
  String? _codigoErrorText;

  @override
  void initState() {
    super.initState();

    _telefonoController.text = '';
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
    Widget child = Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const BackButtonIcon(),
          onPressed: (){
            _handleBack();
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

    return WillPopScope(
      child: child,
      onWillPop: (){
        _handleBack();
        return Future.value(false);
      },
    );
  }

  void _handleBack(){
    if(_pageCurrent == 0){
      Navigator.of(context).pop();
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _contenidoParteUno(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          const SizedBox(height: 16,),

          const Text("Restablecer contraseña",
            style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          ),
          const SizedBox(height: 24,),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.isEmailSeleccionado
                ? "Ingresa tu email. Se enviará un código de confirmación."
                : "Ingresa tu número de teléfono. Se enviará un código de confirmación.",
              style: TextStyle(color: constants.grey,),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 24,),

          if(!widget.isEmailSeleccionado)
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

          if(widget.isEmailSeleccionado)
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
              onPressed: _enviandoMedioContacto ? null : () => widget.isEmailSeleccionado ? _validarEmail() : _validarTelefono(),
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


  void _validarEmail(){
    _emailErrorText = null;

    _emailController.text = _emailController.text.trim();
    if(!_emailRegExp.hasMatch(_emailController.text)){
      _emailErrorText = 'Ingrese un email válido.';
      setState(() {});
      return;
    }

    _enviarMedioContacto(_emailController.text);
  }

  Future<void> _validarTelefono() async {
    if(_enviandoMedioContacto) return;
    _enviandoMedioContacto = true;

    _telefonoErrorText = null;


    if(_phoneNumber == null){
      _enviandoMedioContacto = false;
      return;
    }

    PhoneNumber phoneNumber = _phoneNumber!;
    _telefonoText = _telefonoController.text.trim();

    if(_telefonoText == ""){
      _enviandoMedioContacto = false;
      return;
    }

    if(phoneNumber.parseNumber() == ""){
      _enviandoMedioContacto = false;
      return;
    }


    String telefonoE164 = phoneNumber.phoneNumber ?? ""; // Devuelve en formato E.164, transforma el "15" a "9"

    if (telefonoE164.startsWith("+54")) {
      if (!telefonoE164.startsWith("+549")) {
        telefonoE164 = telefonoE164.replaceFirst("+54", "+549");
      }
    }

    _enviarMedioContacto(telefonoE164);
  }

  Future<void> _enviarMedioContacto(String medioContacto) async {
    setState(() {
      _enviandoMedioContacto = true;
    });

    _email = medioContacto;
    _telefonoE164 = medioContacto;

    var response = await HttpService.httpPost(
      url: constants.urlRestablecerContrasenaEnviarCodigo,
      body: {
        "medioContacto": medioContacto,
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

      } else {

        String? errorText;

        if(datosJson['error_tipo'] == 'correo_invalido'){

          errorText = 'Email inválido.';

        } else if(datosJson['error_tipo'] == 'correo_no_registrado'){

          errorText = 'El email ingresado no está registrado.';

        } else if(datosJson['error_tipo'] == 'codigo_enviado'){

          /*String? minutosFaltantes = datosJson['data']['minutos_faltantes']?.toString();
          String? segundosFaltantes = datosJson['data']['segundos_faltantes']?.toString();

          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          if(segundosFaltantes != null){
            _showSnackBar("Ya se envió anteriormente un código a este número. Debes esperar $segundosFaltantes segundos para volver a pedir otro.");
          } else {
            _showSnackBar("Ya se envió anteriormente un código a este número. Debes esperar $minutosFaltantes minutos para volver a pedir otro.");
          }*/

          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          _showSnackBar(widget.isEmailSeleccionado
              ? "Ya se envió anteriormente un código a este email. Podría estar en la sección de spam."
              : "Ya se envió anteriormente un código a este número.");

        } else if(datosJson['error_tipo'] == 'limite_codigo_enviado_dia'){

          errorText = widget.isEmailSeleccionado
              ? 'Debes esperar un tiempo para poder usar este email.'
              : 'Debes esperar un tiempo para poder usar este número.';

        } else if(datosJson['error_tipo'] == 'telefono_invalido'){

          errorText = 'Formato de número de teléfono inválido.';

        } else if(datosJson['error_tipo'] == 'telefono_ubicacion_invalido'){

          //errorText = 'Lo sentimos, la región de este número no está disponible para el registro.';
          errorText = 'El número ingresado no está registrado.';

        } else if(datosJson['error_tipo'] == 'telefono_no_registrado'){

          errorText = 'El número ingresado no está registrado.';

        } else if(datosJson['error_tipo'] == 'limite_codigos_enviados_semana'){

          errorText = 'Error';
          _showSnackBar("En estos momentos no está habilitado enviar códigos. Por favor comunícate con nosotros para notificarte cuando vuelva a habilitarse.");

        } else if(datosJson['error_tipo'] == 'limite_tiempo_segundos'){

          errorText = 'Tienes que esperar unos segundos para volver a intentar.';

        } else if(datosJson['error_tipo'] == 'limite_tiempo_minutos'){

          errorText = 'Error con tu conexión. Tienes que esperar unos minutos para volver a intentar.';

        } else if(datosJson['error_tipo'] == 'limite_tiempo_horas'){

          errorText = 'Error con tu conexión. Por el momento no tienes permitido enviar códigos.';

        } else if(datosJson['error_tipo'] == 'usuario_no_habilitado'){

          errorText = widget.isEmailSeleccionado
              ? 'Este email fue inhabilitado con un usuario dado de baja.'
              : 'Este número fue inhabilitado con un usuario dado de baja.';

        } else {
          _showSnackBar("Se produjo un error inesperado");
        }


        if(errorText != null){
          if(widget.isEmailSeleccionado){
            _emailErrorText = errorText;
          } else {
            _telefonoErrorText = errorText;
          }
        }

      }
    }

    setState(() {
      _enviandoMedioContacto = false;
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
            child: Text(widget.isEmailSeleccionado
                ? "Se envió un código a $_email\nPodría estar en la sección de spam."
                : "Se envió un código a ${_phoneNumber?.dialCode ?? ""} $_telefonoText",
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
          const SizedBox(height: 24,),

          /*GestureDetector(
            child: const Text("¿No recibiste el código?",
              style: TextStyle(color: constants.grey, decoration: TextDecoration.underline, fontSize: 12,),
            ),
            onTap: (){
              _showDialogCodigoNoRecibido();
            },
          ),
          const SizedBox(height: 16,),*/

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

    String medioContacto = widget.isEmailSeleccionado ? _email : _telefonoE164;

    var response = await HttpService.httpPost(
      url: constants.urlRestablecerContrasenaVerificarCodigo,
      body: {
        "medioContacto": medioContacto,
        "codigo": codigo
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => RestablecerContrasenaNuevacontrasenaPage(
              medioContacto: medioContacto,
              codigo: codigo,
            )
        ));

      } else {

        if(datosJson['error_tipo'] == 'codigo_no_encontrado' || datosJson['error_tipo'] == 'codigo_expirado' || datosJson['error_tipo'] == 'codigo_usado'){
          _codigoErrorText = 'El código ya expiró. Vuelve a solicitar otro.';
        } else if(datosJson['error_tipo'] == 'codigo_anulado' || datosJson['error_tipo'] == 'codigo_anulado_por_intentos'){
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