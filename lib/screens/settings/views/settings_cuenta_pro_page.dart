import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class SettingsCuentaProPage extends StatefulWidget {
  const SettingsCuentaProPage({Key? key}) : super(key: key);

  @override
  State<SettingsCuentaProPage> createState() => _SettingsCuentaProPageState();
}

class _SettingsCuentaProPageState extends State<SettingsCuentaProPage> {

  final _productIdPremium1 = "suscripcion_premium_1";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cuenta Pro"),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          ListTile(
            title: const Text("Administrar suscripciones"),
            onTap: () {
              _openTiendaSuscripciones();
            },
            shape: const Border(bottom: BorderSide(color: constants.grey, width: 0.2,),),
          ),
          const SizedBox(height: 16,),
        ],),
      ),
    );
  }

  Future<void> _openTiendaSuscripciones() async {
    String urlString = "";

    if(Platform.isIOS){
      urlString = "https://apps.apple.com/account/subscriptions";
    } else {
      urlString = "https://play.google.com/store/account/subscriptions?sku=$_productIdPremium1&package=app.tenfo.mobile";
    }

    Uri url = Uri.parse(urlString);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication,);
    } catch (e){
      throw 'Could not launch $urlString';
    }
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}