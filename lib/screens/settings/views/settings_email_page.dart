import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SettingsEmailPage extends StatefulWidget {
  const SettingsEmailPage({Key? key}) : super(key: key);

  @override
  State<SettingsEmailPage> createState() => _SettingsEmailPageState();
}

class _SettingsEmailPageState extends State<SettingsEmailPage> {

  String? _email;
  final TextEditingController _emailController = TextEditingController(text: '');
  String? _emailErrorText;

  String? _emailSecundario;
  final TextEditingController _emailSecundarioController = TextEditingController(text: '');
  String? _emailSecundarioErrorText;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _email = usuarioSesion.email;
      _emailController.text = usuarioSesion.email ?? "";

      _emailSecundario = usuarioSesion.email_secundario;
      _emailSecundarioController.text = usuarioSesion.email_secundario ?? "";

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            if(_email == null)
              ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("No tienes un email vinculado a tu cuenta.",
                    style: TextStyle(color: constants.grey),
                  ),
                ),
              ],

            if(_email != null)
              ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Este valor no puede editarse actualmente.",
                    style: TextStyle(color: constants.grey),
                  ),
                ),
                const SizedBox(height: 24,),
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
                  enabled: false,
                  style: const TextStyle(color: Colors.black54),
                ),
                if(_emailSecundario != null)
                  ...[
                    const SizedBox(height: 16,),
                    TextField(
                      controller: _emailSecundarioController,
                      decoration: InputDecoration(
                        hintText: "nombre@universidad.edu",
                        border: const OutlineInputBorder(),
                        counterText: '',
                        errorText: _emailSecundarioErrorText,
                        errorMaxLines: 2,
                      ),
                      maxLength: 100,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
              ],

            const SizedBox(height: 16,),
          ],),
        ),
      ),
    );
  }
}