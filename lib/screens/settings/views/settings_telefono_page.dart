import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SettingsTelefonoPage extends StatefulWidget {
  const SettingsTelefonoPage({Key? key}) : super(key: key);

  @override
  State<SettingsTelefonoPage> createState() => _SettingsTelefonoPageState();
}

class _SettingsTelefonoPageState extends State<SettingsTelefonoPage> {

  String? _telefono;

  final TextEditingController _telefonoController = TextEditingController(text: '');
  String? _telefonoErrorText;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs){
      UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

      _telefono = usuarioSesion.telefono_numero;
      _telefonoController.text = usuarioSesion.telefono_numero ?? "";

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Número de teléfono"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            if(_telefono == null)
              ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("No tienes un número de teléfono vinculado a tu cuenta.",
                    style: TextStyle(color: constants.grey),
                  ),
                ),
              ],

            if(_telefono != null)
              ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Este valor no puede editarse actualmente.",
                    style: TextStyle(color: constants.grey),
                  ),
                ),
                const SizedBox(height: 24,),
                TextField(
                  controller: _telefonoController,
                  decoration: InputDecoration(
                    hintText: "Número de teléfono",
                    border: const OutlineInputBorder(),
                    counterText: '',
                    errorText: _telefonoErrorText,
                    errorMaxLines: 2,
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],

            const SizedBox(height: 16,),
          ],),
        ),
      ),
    );
  }
}