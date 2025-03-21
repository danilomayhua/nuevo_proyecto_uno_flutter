import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/item_sticker_recibido.dart';
import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/sticker_recibido.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/retiro_moneda/retiro_moneda_page.dart';
import 'package:tenfo/screens/stickers_canjeados/stickers_canjeados_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class CanjearStickersPage extends StatefulWidget {
  const CanjearStickersPage({Key? key}) : super(key: key);

  @override
  State<CanjearStickersPage> createState() => _CanjearStickersPageState();
}

enum _PopupMenuOption { verStickersCanjeados }

class _CanjearStickersPageState extends State<CanjearStickersPage> {

  List<ItemStickerRecibido> _itemsStickerRecibido = [];
  int _totalSatoshis = 0;

  final ScrollController _scrollController = ScrollController();
  bool _loadingStickersRecibido = false;
  bool _verMasStickersRecibido = false;
  String _ultimoStickersRecibido = "false";

  double? _cotizacionActualSatoshi;
  int _limiteSatoshisRetiro = 2000000;

  int? _retiroComisionPorcentaje;

  @override
  void initState() {
    super.initState();

    _obtenerCotizacionBitcoinARS();

    _cargarStickersRecibido();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingStickersRecibido && _verMasStickersRecibido){
          _cargarStickersRecibido();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Canjear stickers"),
        actions: [
          PopupMenuButton<_PopupMenuOption>(
            onSelected: (_PopupMenuOption result) {
              if(result == _PopupMenuOption.verStickersCanjeados) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => StickersCanjeadosPage(),
                ));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<_PopupMenuOption>>[
              const PopupMenuItem<_PopupMenuOption>(
                value: _PopupMenuOption.verStickersCanjeados,
                child: Text('Ver stickers canjeados'),
              ),
            ],
          ),
        ],
      ),
      body: (_itemsStickerRecibido.isEmpty) ? Center(

        child: _loadingStickersRecibido ? CircularProgressIndicator() : const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("No tienes stickers disponibles a canjear. Aquí podrás canjear los stickers que te regalen otros usuarios.\n\n\n"
              "Si hubo algún fallo al canjear un sticker, comunícate con nosotros al email soporte@tenfo.app",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ),

      ) : Column(children: [
        Expanded(
          child: SingleChildScrollView(
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
                  itemCount: _itemsStickerRecibido.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: (){
                        _itemsStickerRecibido[index].seleccionado = !_itemsStickerRecibido[index].seleccionado;

                        if(_itemsStickerRecibido[index].seleccionado){
                          if((_totalSatoshis + _itemsStickerRecibido[index].stickerRecibido.sticker.cantidadSatoshis) < _limiteSatoshisRetiro){
                            _totalSatoshis = _totalSatoshis + _itemsStickerRecibido[index].stickerRecibido.sticker.cantidadSatoshis;
                          } else {
                            // No puede agregar más stickers
                            _itemsStickerRecibido[index].seleccionado = false;
                          }

                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        } else {
                          _totalSatoshis = _totalSatoshis - _itemsStickerRecibido[index].stickerRecibido.sticker.cantidadSatoshis;
                        }

                        setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _itemsStickerRecibido[index].seleccionado ? Colors.black12 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildSticker(_itemsStickerRecibido[index].stickerRecibido),
                      ),
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
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: constants.grey, width: 0.5,),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16,),
          child: Column(children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (){
                  _validarRetiroSeleccion();
                },
                child: const Text("Canjear"),
              ),
            ),
            Text(_totalSatoshis == 0 ? ""
                : "$_totalSatoshis sats" +
                ((_cotizacionActualSatoshi != null) ? " ≈ ARS \$ ${_satoshisToARS(_totalSatoshis)}" : ""),
              style: const TextStyle(color: constants.grey, fontSize: 12,),
            ),
          ],),
        ),
      ],),
    );
  }

  Widget _buildTextoCabecera(){
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8,),
      alignment: Alignment.center,
      child: const Text("Selecciona para canjear los stickers que te regalaron otros usuarios. Los stickers canjeados también se seguirán "
          "mostrando en tu perfil.\n\n"
          "Si hubo algún fallo al canjear un sticker, comunícate con nosotros en soporte@tenfo.app",
        style: TextStyle(color: constants.grey, fontSize: 12,),
      ),
    );
  }

  Widget _buildSticker(StickerRecibido stickerRecibido){
    return Column(children: [
      Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 8,),
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

  int _satoshisToARS(int cantidadSatoshis){
    return (cantidadSatoshis * _cotizacionActualSatoshi!).round();
  }

  Future<void> _obtenerCotizacionBitcoinARS() async {
    setState(() {
      //_loading = true;
    });

    var response = await HttpService.httpGetExterno(
      url: constants.urlExternoCotizacionBTC,
      queryParams: {},
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['totalAsk'] != null){

        num cotizacionBtc = datosJson['totalAsk']; // totalAsk puede ser int o double
        _cotizacionActualSatoshi = cotizacionBtc / 100000000;

      }
    }

    setState(() {
      //_loading = false;
    });
  }

  Future<void> _cargarStickersRecibido() async {
    setState(() {
      _loadingStickersRecibido = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlRetiroStickersDisponibles,
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
          _itemsStickerRecibido.add(ItemStickerRecibido(
            stickerRecibido: StickerRecibido(
              id: element['id'].toString(),
              sticker: Sticker(
                id: element['sticker']['id'].toString(),
                cantidadSatoshis: element['sticker']['valor_satoshis'],
              ),
            ),
          ));
        }

        _retiroComisionPorcentaje = datosJson['data']['retiro_comision_porcentaje'];

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingStickersRecibido = false;
    });
  }

  void _validarRetiroSeleccion(){
    List<StickerRecibido> stickersSeleccionados = [];

    for(ItemStickerRecibido itemStickerRecibido in _itemsStickerRecibido){
      if(itemStickerRecibido.seleccionado){
        stickersSeleccionados.add(itemStickerRecibido.stickerRecibido);
      }
    }

    if(stickersSeleccionados.isEmpty){
      _showSnackBar("Selecciona al menos un sticker para canjear");
      return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => RetiroMonedaPage(stickersRecibido: stickersSeleccionados, comisionPorcentaje: _retiroComisionPorcentaje!,),
    ));
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}