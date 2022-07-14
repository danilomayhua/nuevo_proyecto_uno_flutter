import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/models/sticker_recibido.dart';
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/services/http_service.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class RetiroMonedaPage extends StatefulWidget {
  const RetiroMonedaPage({Key? key, required this.stickersRecibido, required this.comisionPorcentaje}) : super(key: key);

  final List<StickerRecibido> stickersRecibido;
  final int comisionPorcentaje;

  @override
  State<RetiroMonedaPage> createState() => _RetiroMonedaPageState();
}

class _RetiroMonedaPageState extends State<RetiroMonedaPage> {

  int _totalPrevioSatoshis = 0;
  int _totalSatoshis = 0;
  double _totalBitcoins = 0;

  final TextEditingController _walletController = TextEditingController();
  String? _walletErrorText;

  bool _enviando = false;

  String _wallet = "";
  bool _pagoEnviado = false;

  @override
  void initState() {
    super.initState();

    for(StickerRecibido stickerRecibido in widget.stickersRecibido){
      _totalPrevioSatoshis = _totalPrevioSatoshis + stickerRecibido.sticker.cantidadSatoshis;
    }

    _totalSatoshis = (_totalPrevioSatoshis - (_totalPrevioSatoshis / 100 * widget.comisionPorcentaje)).floor();
    _totalBitcoins = _totalSatoshis / 100000000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Retiro"),
      ),
      body: _pagoEnviado ? Center(child: SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Text("¡Pago realizado con éxito! El monto fue enviado a la dirección:\n\n$_wallet",
            style: const TextStyle(color: constants.grey, fontSize: 16, height: 1.3,),
            textAlign: TextAlign.left,
          ),
        ),

      )) : SingleChildScrollView(
        child: Column(children: [
          ExpansionTile(
            title: const Text("Detalles",
              style: TextStyle(color: constants.blackGeneral),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 0, right: 16, bottom: 16,),
                child: RichText(text: TextSpan(
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
                  children: [
                    const TextSpan(text: "Stickers = "),
                    TextSpan(text: "$_totalPrevioSatoshis sats",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 0, right: 16, bottom: 16,),
                child: RichText(text: TextSpan(
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
                  children: [
                    const TextSpan(text: "Comisión/servicio (5%) = "),
                    TextSpan(text: "-${(_totalPrevioSatoshis - _totalSatoshis)} sats",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 0, right: 16, bottom: 16,),
                child: RichText(text: TextSpan(
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
                  children: [
                    const TextSpan(text: "Total = "),
                    TextSpan(text: "$_totalSatoshis sats",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )),
              ),
            ],
            iconColor: constants.blackGeneral,
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
          ),
          const SizedBox(height: 8,),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16,),
            child: Text("Retirar Bitcoin con Lightning Network",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
            ),
          ),
          const SizedBox(height: 16,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("Total: $_totalSatoshis sats ($_totalBitcoins btc)",
              style: const TextStyle(color: constants.blackGeneral, fontSize: 16,),
            ),
          ),
          const SizedBox(height: 24,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _walletController,
              decoration: InputDecoration(
                isDense: true,
                hintText: "Pegar dirección Lightning Network...",
                counterText: '',
                border: OutlineInputBorder(),
                errorText: _walletErrorText,
              ),
              maxLength: 3900,
              style: const TextStyle(fontSize: 12,),
            ),
          ),
          const SizedBox(height: 24,),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _enviando ? null : () => _validarDatosEnviar(),
              icon: const Icon(CupertinoIcons.bitcoin),
              label: const Text("Recibir pago"),
            ),
          ),
          const SizedBox(height: 16,),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Por favor verifica al copiar la dirección que es la correcta. Esta acción no se podrá deshacer.",
              style: TextStyle(color: constants.grey, fontSize: 12,),
            ),
          ),
          const SizedBox(height: 16,),
        ], crossAxisAlignment: CrossAxisAlignment.start,),
      ),
    );
  }

  void _validarDatosEnviar(){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    _walletController.text = _walletController.text.trim();
    if(_walletController.text == ""){
      _showSnackBar("Debes agregar una dirección");
      return;
    }

    _obtenerRetiro();
  }

  Future<void> _obtenerRetiro() async {
    setState(() {
      _enviando = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    List<dynamic> retiroStickers = [];
    for(StickerRecibido stickerRecibido in widget.stickersRecibido){
      retiroStickers.add(stickerRecibido.id);
    }
    _wallet = _walletController.text.trim();

    var response = await HttpService.httpPost(
      url: constants.urlCrearRetiro,
      body: {
        "retiro_stickers_recibidos": retiroStickers,
        "wallet_lightning_network": _wallet,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _pagoEnviado = true;

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviando = false;
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