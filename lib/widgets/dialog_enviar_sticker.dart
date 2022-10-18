import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tenfo/models/chat.dart';
import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/comprar_stickers/comprar_stickers_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class DialogEnviarSticker extends StatefulWidget {
  const DialogEnviarSticker({Key? key, required this.isGroup, this.usuario, this.chat}) : super(key: key);

  final bool isGroup;
  final Usuario? usuario;
  final Chat? chat;

  @override
  _DialogEnviarStickerState createState() => _DialogEnviarStickerState();
}

class _DialogEnviarStickerState extends State<DialogEnviarSticker> {
  List<Sticker> _stickers = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingStickers = false;
  bool _verMasStickers = false;
  String _ultimoStickers = "false";

  int? _selectedStickerIndex;
  bool _enviandoSticker = false;

  @override
  void initState() {
    super.initState();

    _cargarStickers();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingStickers && _verMasStickers){
          _cargarStickers();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Platform.isIOS ? _buildContenidoBloqueado() : _buildContenido(),
      actions: [
        TextButton(
          onPressed: _enviandoSticker ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _selectedStickerIndex == null
              ? null
              : _enviandoSticker ? null : () => _enviarSticker(),
          child: const Text('Enviar'),
        ),
      ],
    );
  }

  Widget _buildContenidoBloqueado(){
    if(_stickers.isEmpty){
      return Padding(
        padding: const EdgeInsets.only(top: 16,),
        child: Row(children: const [
          Icon(Icons.lock_outline, color: constants.blackGeneral,),
          SizedBox(width: 8,),
          Text("Próximamente",
            style: TextStyle(fontSize: 16, color: constants.blackGeneral),
          ),
        ], mainAxisAlignment: MainAxisAlignment.center,),
      );
    } else {
      return _buildContenido();
    }
  }

  Widget _buildContenido(){
    return Column(children: [
      Text(Platform.isIOS ? 'Elige uno a enviar:' : 'Elige un sticker a enviar:',
        style: TextStyle(color: constants.grey, fontSize: 12,),
      ),
      const SizedBox(height: 8,),
      Flexible(child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(children: [
          (_stickers.isEmpty && !_loadingStickers)
          ? Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(Platform.isIOS ? "No tienes propinas para enviar actualmente.": "No tienes stickers actualmente.",
              style: TextStyle(
                color: constants.blackGeneral,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          )
          : Flexible(child: Container(
            width: double.maxFinite,
            //constraints: const BoxConstraints(maxWidth: 400,),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
                mainAxisSpacing: 8,
              ),
              itemCount: _loadingStickers ? (_stickers.length + 1) : _stickers.length, // Necesario verificar _loadingStickers (Si no, cuando ocupa una fila, el loading oculto agrega otra fila abajo)
              itemBuilder: (BuildContext context, int index) {
                if(index == _stickers.length){
                  return _buildLoadingStickers();
                }

                return GestureDetector(
                  onTap: _enviandoSticker ? null : () => setState(() => _selectedStickerIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedStickerIndex == index ? Colors.black12 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildSticker(_stickers[index]),
                  ),
                );
              },
            ),
          ),),
          const SizedBox(height: 8,),
          if(!_loadingStickers)
            OutlinedButton(
              onPressed: (){
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ComprarStickersPage(),
                ));
              },
              child: Text(_stickers.length == 0 ? "Conseguir" : "Conseguir más",
                style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12,),
              ),
              style: OutlinedButton.styleFrom(
                primary: constants.blueGeneral,
                backgroundColor: Colors.white,
                //onSurface: constants.grey,
                side: const BorderSide(color: constants.blueGeneral, width: 0.5,),
                shape: const StadiumBorder(),
              ),
            ),
        ], mainAxisSize: MainAxisSize.min,),
      )),
    ], mainAxisSize: MainAxisSize.min,);
  }

  Widget _buildSticker(Sticker sticker){
    return Column(children: [
      Text("Disponib. ${sticker.numeroDisponibles}",
        style: const TextStyle(color: constants.blackGeneral, fontSize: 10,),
      ),
      Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 8,),
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

  Widget _buildLoadingStickers(){
    if(_loadingStickers){
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Container();
    }
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
        Navigator.of(context).pop();

        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingStickers = false;
    });
  }

  Future<void> _enviarSticker() async {
    setState(() {
      _enviandoSticker = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response;

    if(widget.isGroup){
      response = await HttpService.httpPost(
        url: constants.urlEnviarStickerChatGrupal,
        body: {
          "chat_id": widget.chat!.id,
          "sticker_valor_id": _stickers[_selectedStickerIndex!].stickerValorId,
        },
        usuarioSesion: usuarioSesion,
      );
    } else {
      response = await HttpService.httpPost(
        url: constants.urlEnviarStickerChatIndividual,
        body: {
          "usuario_id": widget.usuario!.id,
          "sticker_valor_id": _stickers[_selectedStickerIndex!].stickerValorId,
        },
        usuarioSesion: usuarioSesion,
      );
    }

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        Navigator.of(context).pop();

        _showSnackBar("¡El sticker fue enviado!");

      } else {

        Navigator.of(context).pop();

        if(datosJson['error_tipo'] == 'cocreadores_vacio'){
          _showSnackBar("No puedes enviar stickers a este chat. Los co-creadores ya no forman parte.");
        } else if(datosJson['error_tipo'] == 'cocreador_unico_autor'){
          _showSnackBar("No puedes enviar stickers a este chat. Solamente otros integrantes pueden enviarte stickers a ti como co-creador.");
        } else{
          _showSnackBar("Se produjo un error inesperado");
        }

      }
    }

    setState(() {
      _enviandoSticker = false;
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