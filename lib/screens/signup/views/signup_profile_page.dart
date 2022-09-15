import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class SignupProfilePage extends StatefulWidget {
  const SignupProfilePage({Key? key, required this.email,
    required this.codigo, required this.registroActivadoToken}) : super(key: key);

  final String email;
  final String codigo;
  final String registroActivadoToken;

  @override
  State<SignupProfilePage> createState() => _SignupProfilePageState();
}

class _SignupProfilePageState extends State<SignupProfilePage> {

  final PageController _pageController = PageController();
  int _pageCurrent = 0;

  bool _enviandoNombreCompleto = false;
  final TextEditingController _nombreController = TextEditingController(text: '');
  String? _nombreErrorText;
  final TextEditingController _apellidoController = TextEditingController(text: '');
  String? _apellidoErrorText;

  bool _enviandoNacimiento = false;
  DateTime _nacimientoDateTime = DateTime(DateTime.now().year - 21);
  String _nacimientoFechaString = "";
  String? _nacimientoErrorText;

  final TextEditingController _usuarioController = TextEditingController(text: '');
  String? _usuarioErrorText;
  final TextEditingController _contrasenaController = TextEditingController(text: '');
  String? _contrasenaErrorText;
  bool _isContrasenaOculta = true;

  bool _enviandoRegistro = false;

  @override
  void initState() {
    super.initState();

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
        leading: BackButton(
          onPressed: (){
            _handleBack();
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            constraints: BoxConstraints(maxHeight: 380,),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index){
                WidgetsBinding.instance?.focusManager.primaryFocus?.unfocus();
              },
              children: [
                _contenidoNombreCompleto(),
                _contenidoNacimiento(),
                _contenidoUsuarioContrasena(),
              ],
            ),
          ),
          SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: const WormEffect(activeDotColor: constants.blueGeneral,),
          ),
          const SizedBox(height: 16,),
        ],),
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
      _showDialogCancelarRegistro();
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showDialogCancelarRegistro() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("¿Estás seguro de que quieres cancelar el registro?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                  builder: (context) => const WelcomePage()
              ), (root) => false);
            },
            child: const Text('Eliminar registro', style: TextStyle(color: constants.redAviso),),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Continuar registro'),
          ),
        ],
      );
    });
  }

  Widget _contenidoNombreCompleto(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16,),
      child: Column(children: [
        const SizedBox(height: 16,),

        Text("¿Cuál es tu nombre?",
          style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
        ),
        const SizedBox(height: 24,),

        TextField(
          controller: _nombreController,
          decoration: InputDecoration(
            hintText: "Nombre",
            border: const OutlineInputBorder(),
            counterText: '',
            errorText: _nombreErrorText,
            errorMaxLines: 2,
          ),
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16,),
        TextField(
          controller: _apellidoController,
          decoration: InputDecoration(
            hintText: "Apellido",
            border: const OutlineInputBorder(),
            counterText: '',
            errorText: _apellidoErrorText,
            errorMaxLines: 2,
          ),
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16,),

        Container(
          constraints: BoxConstraints(minWidth: 120,),
          child: ElevatedButton(
            onPressed: _enviandoNombreCompleto ? null : () => _validarNombreCompleto(),
            child: const Text("Siguiente"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),
        const SizedBox(height: 16,),
      ],),
    );
  }

  void _validarNombreCompleto(){
    _nombreErrorText = null;
    _apellidoErrorText = null;

    RegExp regExp = RegExp(r"^[a-zA-ZñÑáéíóúÁÉÍÓÚäëïöüÄËÏÖÜ'\s]+$");

    _nombreController.text = _nombreController.text.trim();
    if(!regExp.hasMatch(_nombreController.text)){
      _nombreErrorText = 'Ingrese un nombre válido.';
    }

    _apellidoController.text = _apellidoController.text.trim();
    if(!regExp.hasMatch(_apellidoController.text)){
      _apellidoErrorText = 'Ingrese un apellido válido.';
    }

    setState(() {});

    if(_nombreErrorText == null && _apellidoErrorText == null){
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Widget _contenidoNacimiento(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16,),
      child: Column(children: [
        const SizedBox(height: 16,),

        Text("¿Cuándo es tu cumpleaños?",
          style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
        ),
        const SizedBox(height: 24,),

        GestureDetector(
          onTap: (){
            _showDialogEditarNacimiento();
          },
          child: InputDecorator(
            isEmpty: _nacimientoFechaString == "" ? true : false,
            decoration: InputDecoration(
              hintText: "dd/mm/aaaa",
              border: OutlineInputBorder(),
              //counterText: '',
              errorText: _nacimientoErrorText,
              errorMaxLines: 2,
            ),
            child: Text(_nacimientoFechaString,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 16,),

        Container(
          constraints: BoxConstraints(minWidth: 120,),
          child: ElevatedButton(
            onPressed: _enviandoNacimiento ? null : () => _validarNacimiento(),
            child: const Text("Siguiente"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),
        const SizedBox(height: 16,),
      ],),
    );
  }

  void _showDialogEditarNacimiento() async {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        content: Container(
          height: 200,
          width: MediaQuery.of(context).size.width - 80,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: (picked){
              if (picked != null){
                _nacimientoDateTime = picked;

                String year = '${picked.year}';
                String mes = picked.month < 10 ? '0${picked.month}' : '${picked.month}';
                String dia = picked.day < 10 ? '0${picked.day}' : '${picked.day}';

                _nacimientoFechaString = "$dia/$mes/$year";

                setState(() {});
              }
            },
            initialDateTime: _nacimientoDateTime,
            minimumYear: 1920,
            maximumYear: DateTime.now().year - 17,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Listo'),
          ),
        ],
      );
    });
  }

  void _validarNacimiento(){
    if(_nacimientoFechaString != ""){
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Widget _contenidoUsuarioContrasena(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16,),
      child: Column(children: [
        const SizedBox(height: 16,),

        Text("Crea un usuario y contraseña",
          style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24,),

        TextField(
          controller: _usuarioController,
          decoration: InputDecoration(
            hintText: "Usuario",
            border: const OutlineInputBorder(),
            counterText: '',
            errorText: _usuarioErrorText,
            errorMaxLines: 2,
          ),
          maxLength: 30,
        ),
        const SizedBox(height: 16,),
        TextField(
          controller: _contrasenaController,
          decoration: InputDecoration(
            hintText: "Contraseña",
            border: const OutlineInputBorder(),
            counterText: '',
            errorText: _contrasenaErrorText,
            errorMaxLines: 2,
            suffixIcon: IconButton(
              icon: _isContrasenaOculta
                  ? const Icon(Icons.visibility_off)
                  : const Icon(Icons.visibility),
              onPressed: () {
                _isContrasenaOculta = !_isContrasenaOculta;
                setState(() {});
              },
            ),
          ),
          maxLength: 60,
          keyboardType: TextInputType.visiblePassword,
          obscureText: _isContrasenaOculta,
        ),
        const SizedBox(height: 16,),

        Container(
          constraints: BoxConstraints(minWidth: 120,),
          child: ElevatedButton(
            onPressed: _enviandoRegistro ? null : () => _validarUsuarioContrasena(),
            child: const Text("Crear usuario"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),
        const SizedBox(height: 16,),
      ],),
    );
  }

  void _validarUsuarioContrasena(){
    setState(() {_enviandoRegistro = true;});

    _usuarioErrorText = null;
    _contrasenaErrorText = null;

    RegExp regExp = RegExp(r"^[a-zA-Z\d_]{4,}$");

    _usuarioController.text = _usuarioController.text.trim();
    if(!regExp.hasMatch(_usuarioController.text)){
      _usuarioErrorText = 'Ingrese un usuario válido. Solo acepta letras, números y guion bajo. Mínimo 4 caracteres.';
    }

    RegExp regExpContrasena1 = RegExp(r"[a-zA-Z]");
    RegExp regExpContrasena2 = RegExp(r"[\d]");

    if(_contrasenaController.text.length < 8){
      _contrasenaErrorText = 'Ingrese más de 8 caracteres.';
    } else if(!regExpContrasena1.hasMatch(_contrasenaController.text) || !regExpContrasena2.hasMatch(_contrasenaController.text)){
      _contrasenaErrorText = 'Ingrese mínimo una letra y un número.';
    }

    if(_usuarioErrorText == null && _contrasenaErrorText == null){
      _registrarse();
    } else {
      setState(() {_enviandoRegistro = false;});
    }
  }

  Future<void> _registrarse() async {
    setState(() {
      _enviandoRegistro = true;
    });

    String nombre = _nombreController.text;
    String apellido = _apellidoController.text;
    String nacimiento = _nacimientoDateTime.millisecondsSinceEpoch.toString();
    String username = _usuarioController.text;
    String contrasena = _contrasenaController.text;
    String? firebaseToken;
    try {
      firebaseToken = await FirebaseMessaging.instance.getToken();
    } catch(e) {
      //
    }

    var response = await HttpService.httpPost(
      url: constants.urlRegistroUsuario,
      body: {
        "nombre": nombre,
        "apellido": apellido,
        "nacimiento_fecha": nacimiento,
        "username": username,
        "contrasena": contrasena,
        "email": widget.email,
        "codigo": widget.codigo,
        "registro_activado_token": widget.registroActivadoToken,
        "firebase_token": firebaseToken ?? "",
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        UsuarioSesion usuarioSesion = UsuarioSesion.fromJson(datosJson['data']);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(SharedPreferencesKeys.usuarioSesion, jsonEncode(usuarioSesion));
        prefs.setBool(SharedPreferencesKeys.isLoggedIn, true);

        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) => const PrincipalPage(principalPageView: PrincipalPageView.mensajes,)
        ), (root) => false);

      } else {

        if(datosJson['error_tipo'] == 'username_registrado'){
          _usuarioErrorText = 'El nombre de usuario no está disponible.';
        } else if(datosJson['error_tipo'] == 'email_registrado'){
          _showSnackBar("Se produjo un error inesperado");
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoRegistro = false;
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