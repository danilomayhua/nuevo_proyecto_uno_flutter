import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tenfo/models/signup_permisos_estado.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/signup/views/signup_picture_page.dart';
import 'package:tenfo/screens/welcome/welcome_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/historial_no_usuario.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';

class SignupProfilePage extends StatefulWidget {
  const SignupProfilePage({Key? key, required this.telefono,
    required this.codigo, required this.registroActivadoToken,
    required this.universidadId, required this.signupPermisosEstado}) : super(key: key);

  final String telefono;
  final String codigo;
  final String universidadId;
  final String registroActivadoToken;
  final SignupPermisosEstado signupPermisosEstado;

  @override
  State<SignupProfilePage> createState() => _SignupProfilePageState();
}

class _SignupProfilePageState extends State<SignupProfilePage> {

  final PageController _pageController = PageController();
  int _pageCurrent = 0;

  int _pasoVisto = 1;

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
          /*
          SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: const WormEffect(activeDotColor: constants.blueGeneral,),
          ),
          */
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
              _crearHistorial();

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

  void _crearHistorial(){
    String pasoVisto = _pasoVisto.toString();

    String nombre = _nombreController.text.trim();
    String apellido = _apellidoController.text.trim();
    String nacimiento = "";
    String username = "";
    bool isContrasenaCompletado = false;

    if(_pasoVisto > 1){
      nacimiento = _nacimientoDateTime.millisecondsSinceEpoch.toString();

      if(_pasoVisto > 2){
        username = _usuarioController.text.trim();
        if(_contrasenaController.text != "") isContrasenaCompletado = true;
      }
    }

    // Envia historial no usuario
    _enviarHistorialNoUsuario(HistorialNoUsuario.getRegistroPerfilCancelar(
      pasoVisto,
      nombre.isEmpty ? null : nombre,
      apellido.isEmpty ? null : apellido,
      nacimiento.isEmpty ? null : nacimiento,
      username.isEmpty ? null : username,
      isContrasenaCompletado,
    ));
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
          constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
          width: double.infinity,
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
      // El valor tiene que ser el ultimo paso avanzado
      if(_pasoVisto < 2) _pasoVisto = 2;

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
          constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
          width: double.infinity,
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
      // El valor tiene que ser el ultimo paso avanzado
      if(_pasoVisto < 3) _pasoVisto = 3;

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
          constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _enviandoRegistro ? null : () => _validarUsuarioContrasena(),
            child: const Text("Crear usuario"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),
        const SizedBox(height: 16,),

        /*
        Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
              text: "Al continuar, aceptas los ",
              children: [
                TextSpan(
                  text: "Términos y Condiciones",
                  style: TextStyle(decoration: TextDecoration.underline,),
                  recognizer: TapGestureRecognizer()..onTap = (){
                    _showDialogTerminosCondiciones();
                  },
                ),
                TextSpan(
                  text: " y confirmas haberlos leído.",
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8,),
        */
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
    String origenPlataforma = "android";
    if(Platform.isIOS){
      origenPlataforma = "iOS";
    }

    var response = await HttpService.httpPost(
      url: constants.urlRegistroUsuarioConTelefono,
      body: {
        "nombre": nombre,
        "apellido": apellido,
        "nacimiento_fecha": nacimiento,
        "username": username,
        "contrasena": contrasena,
        "universidad_id": widget.universidadId,
        "telefono": widget.telefono,
        "codigo": widget.codigo,
        "registro_activado_token": widget.registroActivadoToken,
        "firebase_token": firebaseToken ?? "",
        "plataforma": origenPlataforma,
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
            builder: (context) => SignupPicturePage(isFromSignup: true, signupPermisosEstado: widget.signupPermisosEstado,)
        ), (root) => false);

      } else {

        if(datosJson['error_tipo'] == 'username_registrado'){
          _usuarioErrorText = 'El nombre de usuario ya está en uso.';
        } else if(datosJson['error_tipo'] == 'telefono_registrado'){
          _showSnackBar("Se produjo un error inesperado con teléfono registrado");
        } else {
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoRegistro = false;
    });
  }


  void _showDialogTerminosCondiciones(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: _terminosCondiciones(),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
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

  List<Widget> _terminosCondiciones(){
    return [
      Text("Términos y Condiciones",
        style: TextStyle(color: constants.blackGeneral, fontSize: 18, fontWeight: FontWeight.bold,),
      ),
      SizedBox(height: 8,),
      Text("Al acceder y utilizar este servicio, usted acepta y accede a estar obligado por los términos y "
          "condiciones vistos en esta página. Asimismo, al utilizar estos servicios particulares, usted estará "
          "sujeto a toda regla o guía de uso correspondiente que se haya publicado para dichos servicios. Toda participación "
          "en este servicio constituirá la aceptación de este acuerdo. Si no acepta cumplir con lo anterior, por favor, no lo utilice.",
        style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
      ),

      _subtitulo("Uso prohibido"),
      _lista("Todos los usuarios deben comprometerse con la ética y los valores, y deben abstenerse de insultar y abusar del sitio."),
      _lista("En las actividades creadas:"),
      _sublista("No se permite nombrar a ninguna persona, a no ser que esta sea un personaje público."),
      _sublista("No se permite hacer incitaciones de actos sexuales y/o violentos, incitar el odio, o hacer comentarios difamando a otra "
          "persona u organización."),
      _sublista("No se puede usar perfiles que no sean de personas(perfiles falsos)."),
      _sublista("La sección es para crear actividades, encuentros o expresar sobre temas que puedan generar una conversación."),
      _lista("No se permiten imágenes violentas o adultas."),
      _lista("Al hacer uso prohibido en la app, se le dará un aviso, pudiendo resultar en el bloqueo de su cuenta si continua "
          "infringiendo los términos."),

      _subtitulo("Política de privacidad"),
      _lista("Recopilamos información sobre su uso en Tenfo, incluyendo publicaciones vistas, interacciones con otros usuarios y "
          "otra información sobre sus interacciones. Esta información es utilizada para, entre otras cosas, personalizar su experiencia, "
          "monitorear, analizar y mejorar los servicios."),
      _lista("No venderemos, intercambiaremos, alquilaremos ni divulgaremos información a terceros desde esta plataforma o sitios fuera de "
          "nuestra red y solo divulgaremos información cuando lo solicite una entidad legal u organizacional."),
      _lista("Su nombre y nombre de usuario, siempre será publico y será visible en su perfil. Si a futuro ingresa una foto de perfil, esta "
          "también sera publica y se podrá ver en su perfil."),
      _lista("Cuando necesitamos cualquier información de usted. Le pediremos su consentimiento."),

      _subtitulo("Eliminación de contenido"),
      _lista("Tenemos el derecho de eliminar cualquier publicación, con la justificación que los administradores de la plataforma consideren adecuada."),
      _lista("Tenemos el derecho de eliminar cuentas inactivas en la duración que consideremos adecuada."),
      _lista("Tambien podemos cancelar su acceso a la app, con la justificación que los administradores de la plataforma consideren adecuada, lo cual "
          "podrá resultar en la incautación y destrucción de toda la información que esté asociada con su cuenta."),

      _subtitulo("Límites de responsabilidad"),
      _lista("Todo el contenido comunicado en la app es responsabilidad de sus autores y Tenfo no es responsable de su contenido ni de ningún daño que "
          "pueda resultar de este contenido o del uso de cualquiera de los servicios del sitio."),
      _lista("Al aceptar estos términos y condiciones, aceptas ser considerado responsable de cualquier repercusión legal que pueda provenir del "
          "contenido que publicas."),

      _subtitulo("Modificaciones de Términos y Condiciones"),
      _lista("Tenemos el derecho de modificar los términos y condiciones si es necesario y cuando sea adecuado."),
      _lista("Tenfo se reserva el derecho de modificar estas condiciones de vez en cuando según lo considere oportuno; asimismo, el uso permanente "
          "de la plataforma significará su aceptación de cualquier ajuste a tales términos. Por lo tanto, se le recomienda volver a leer esta "
          "declaración de manera regular en https://tenfo.app/terminos.html"),

      _subtitulo("Contáctenos"),
      _lista("Si desea contactarnos sobre cualquier otra cosa, puede usar el correo electrónico que se especifica a continuación: soporte@tenfo.app"),
    ];
  }

  Widget _subtitulo(String texto){
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Text("$texto",
        style: TextStyle(color: constants.blackGeneral, fontSize: 16, fontWeight: FontWeight.bold,),
      ),
    );
  }
  Widget _lista(String texto){
    return Padding(
      padding: EdgeInsets.only(left: 8, top: 4,),
      child: Text("• $texto",
        style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
      ),
    );
  }
  Widget _sublista(String texto){
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 4,),
      child: Text("◦ $texto",
        style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
      ),
    );
  }


  Future<void> _enviarHistorialNoUsuario(Map<String, dynamic> historialNoUsuario) async {
    //setState(() {});

    var response = await HttpService.httpPost(
      url: constants.urlCrearHistorialNoUsuario,
      body: {
        "historiales_no_usuario": [historialNoUsuario],
      },
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