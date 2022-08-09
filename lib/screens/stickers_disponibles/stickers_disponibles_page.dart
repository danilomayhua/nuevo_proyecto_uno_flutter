import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class StickersDisponiblesPage extends StatefulWidget {
  const StickersDisponiblesPage({Key? key}) : super(key: key);

  @override
  State<StickersDisponiblesPage> createState() => _StickersDisponiblesPageState();
}

class _StickersDisponiblesPageState extends State<StickersDisponiblesPage> {

  List<Sticker> _stickers = [];

  bool _loadingStickers = false;

  @override
  void initState() {
    super.initState();

    _cargarStickers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stickers disponibles"),
      ),
      body: (_stickers.isEmpty) ? Center(

        child: _loadingStickers ? CircularProgressIndicator() : const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("No tienes stickers comprados para usar.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ),

      ) : SingleChildScrollView(child: Column(
        children: [
          _buildTextoCabecera(),
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
                mainAxisSpacing: 8,
              ),
              itemCount: _stickers.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  child: _buildSticker(_stickers[index]),
                );
              },
            ),
          ),
        ],
      ),),
    );
  }

  Widget _buildTextoCabecera(){
    return const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 24,),
      child: Text("Estos son tus stickers disponibles para enviar a otros usuarios o actividades.",
        style: TextStyle(color: constants.grey, fontSize: 12,),
      ),
    );
  }

  Widget _buildSticker(Sticker sticker){
    return Column(children: [
      Text("Disponib. ${sticker.numeroDisponibles}",
        style: const TextStyle(color: constants.blackGeneral, fontSize: 10,),
      ),
      SizedBox(
        width: 50,
        height: 50,
        child: sticker.getImageAssetName() != null ? Image.asset(sticker.getImageAssetName()!) : null,
      ),
      Text("${sticker.cantidadSatoshis} sats",
        style: const TextStyle(
          color: constants.blackGeneral,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ], mainAxisAlignment: MainAxisAlignment.center,);
  }

  Future<void> _cargarStickers() async {
    setState(() {
      _loadingStickers = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlStickersDisponiblesEnvio,
      queryParams: {},
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        List<dynamic> stickers = datosJson['data']['stickers_stock'];
        for (var element in stickers) {
          _stickers.add(Sticker(
            id: element['id'].toString(),
            cantidadSatoshis: element['valor_satoshis'],
            stickerValorId: element['sticker_valor_id'].toString(),
            numeroDisponibles: element['cantidad_disponible'],
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingStickers = false;
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