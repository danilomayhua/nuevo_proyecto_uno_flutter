import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/sticker_recibido.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class StickersCanjeadosPage extends StatefulWidget {
  const StickersCanjeadosPage({Key? key}) : super(key: key);

  @override
  State<StickersCanjeadosPage> createState() => _StickersCanjeadosPageState();
}

class _StickersCanjeadosPageState extends State<StickersCanjeadosPage> {

  List<StickerRecibido> _stickersRecibido = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingStickersRecibido = false;
  bool _verMasStickersRecibido = false;
  String _ultimoStickersRecibido = "false";

  @override
  void initState() {
    super.initState();

    _cargarStickersCanjeados();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingStickersRecibido && _verMasStickersRecibido){
          _cargarStickersCanjeados();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stickers canjeados"),
      ),
      body: (_stickersRecibido.isEmpty) ? Center(

        child: _loadingStickersRecibido ? CircularProgressIndicator() : const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Aún no has canjeado ningún sticker.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ),

      ) : SingleChildScrollView(
        controller: _scrollController,
        child: Column(children: [
          _buildTextoCabecera(),
          Flexible(child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 400,),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _stickersRecibido.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  decoration: BoxDecoration(
                    //color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildSticker(_stickersRecibido[index]),
                );
              },
            ),
          ),),
          const SizedBox(height: 8,),
          if(_loadingStickersRecibido)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ], mainAxisSize: MainAxisSize.min,),
      ),
    );
  }

  Widget _buildTextoCabecera(){
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8,),
      alignment: Alignment.center,
      child: const Text("Estos son los stickers que ya canjeaste anteriormente.",
        style: TextStyle(color: constants.grey, fontSize: 12,),
      ),
    );
  }

  Widget _buildSticker(StickerRecibido stickerRecibido){
    return Column(children: [
      SizedBox(
        width: 50,
        height: 50,
        child: stickerRecibido.sticker.getImageAssetName() != null ? Image.asset(stickerRecibido.sticker.getImageAssetName()!) : null,
      ),
      Text("${stickerRecibido.sticker.cantidadSatoshis} sats",
        style: const TextStyle(
          color: constants.blackGeneral,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ], mainAxisAlignment: MainAxisAlignment.center,);
  }

  Future<void> _cargarStickersCanjeados() async {
    setState(() {
      _loadingStickersRecibido = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlRetiroStickersCanjeados,
      queryParams: {
        "ultimo_id": _ultimoStickersRecibido
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoStickersRecibido = datosJson['data']['ultimo_id'].toString();
        _verMasStickersRecibido = datosJson['data']['ver_mas'];

        List<dynamic> stickersRecibidos = datosJson['data']['usuario_stickers_recibidos'];
        for (var element in stickersRecibidos) {
          _stickersRecibido.add(StickerRecibido(
            id: element['id'].toString(),
            sticker: Sticker(
              id: element['sticker']['id'].toString(),
              cantidadSatoshis: element['sticker']['valor_satoshis'],
            ),
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingStickersRecibido = false;
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