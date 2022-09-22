import 'package:flutter/material.dart';
import 'package:tenfo/screens/bloqueados/bloqueados_page.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SettingsPrivacidadPage extends StatefulWidget {
  const SettingsPrivacidadPage({Key? key}) : super(key: key);

  @override
  State<SettingsPrivacidadPage> createState() => _SettingsPrivacidadPageState();
}

class _SettingsPrivacidadPageState extends State<SettingsPrivacidadPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacidad"),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          ListTile(
            title: const Text("Usuarios bloqueados"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const BloqueadosPage()
              ));
            },
            shape: const Border(bottom: BorderSide(color: constants.grey, width: 0.2,),),
          ),
          const SizedBox(height: 16,),
        ],),
      ),
    );
  }
}