import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/pagar_stickers/pagar_stickers_page.dart';
import 'package:tenfo/screens/stickers_disponibles/stickers_disponibles_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class ComprarStickersPage extends StatefulWidget {
  const ComprarStickersPage({Key? key}) : super(key: key);

  @override
  State<ComprarStickersPage> createState() => _ComprarStickersPageState();
}

class _ComprarStickersPageState extends State<ComprarStickersPage> {
  List<Sticker> _stickersVenta = [];
  int _totalSatoshis = 0;

  bool _loadingStickersVenta = false;

  double? _cotizacionActualSatoshi = null;
  int _limiteSatoshisCompra = 2000000;

  bool _isCompraRealizada = false;

  @override
  void initState() {
    super.initState();

    _obtenerCotizacionBitcoinARS();

    _cargarStickersVenta();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conseguir stickers"),
        actions: [
          IconButton(
            icon: Icon(Icons.account_balance_wallet_outlined),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => StickersDisponiblesPage()));
            },
          ),
        ],
      ),
      body: _loadingStickersVenta ? const Center(

        child: CircularProgressIndicator(),

      ): _isCompraRealizada ? _buildCompraRealizada() : Column(children: [
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _stickersVenta.length + 1, // +1 mostrar texto cabecera
            itemBuilder: (context, index){
              if(index == 0){
                return _buildTextoCabecera();
              }

              index = index - 1;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16,),
                child: _buildStickerVenta(_stickersVenta[index]),
              );
            },
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
                  _validarCompraSeleccion();
                },
                //child: const Text("Comprar"),
                child: const Text("Siguiente"),
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
    return const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8,),
      /*child: Text("Regala stickers con bitcoins. Los stickers tendran el mismo valor "
          "por el cual lo compraste. El usuario al que envies el sticker, podrá canjearlo por bitcoin al mismo valor. "
          "Da propinas o haz micro-regalos con los stickers.\nTienes que tener una billetera en bitcoin para hacer la compra. "
          "Los valores están representados en satoshis (1 sats = 0,00000001 btc). Los valores en ARS \$ es un precio aproximado de su equivalente.",
        style: TextStyle(color: constants.grey, fontSize: 12,),
      ),*/
      child: Text("Da propinas o haz pequeños regalos con stickers en bitcoin. Los stickers tendrán el mismo valor por el cual lo "
          "adquiriste. El usuario al que envíes el sticker, podrá canjearlo por bitcoin al mismo valor.\n"
          "Tienes que tener una billetera en bitcoin para hacer la adquisición. Los valores están representados en "
          "satoshis (1 sats = 0,00000001 btc). Los valores en ARS \$ es un precio aproximado de su equivalente.",
        style: TextStyle(color: constants.grey, fontSize: 12,),
      ),
    );
  }

  Widget _buildStickerVenta(Sticker sticker){
    return Row(children: [
      Container(
        width: 88,
        decoration: BoxDecoration(
          color: (sticker.numeroDisponibles! > 0) ? Colors.black12 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8,),
        child: Column(children: [
          Text("${sticker.cantidadSatoshis} sats",
            style: const TextStyle(
              color: constants.blackGeneral,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4,),
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 4,),
            child: sticker.getImageAssetName() != null ? Image.asset(sticker.getImageAssetName()!) : null,
          ),
        ],),
      ),
      Column(children: [
        const SizedBox(height: 10,),
        Text(_cotizacionActualSatoshi != null
            ? "≈ ARS \$ ${_satoshisToARS(sticker.cantidadSatoshis)}" : "",
          style: const TextStyle(color: constants.grey, fontSize: 12,),
        ),
        const SizedBox(height: 4,),
        Row(children: [
          IconButton(
            onPressed: sticker.numeroDisponibles! <= 0 ? null : (){

              sticker.numeroDisponibles = sticker.numeroDisponibles! - 1;
              _totalSatoshis = _totalSatoshis - sticker.cantidadSatoshis;
              setState(() {});

            },
            icon: Visibility(
              visible: sticker.numeroDisponibles! > 0,
              child: const Icon(Icons.remove_circle_outline, color: constants.blackGeneral,),
            ),
          ),
          Text("${sticker.numeroDisponibles}",
            style: const TextStyle(color: constants.blackGeneral, fontSize: 16,),
          ),
          IconButton(
            onPressed: (){

              ScaffoldMessenger.of(context).removeCurrentSnackBar();

              if((_totalSatoshis + sticker.cantidadSatoshis) < _limiteSatoshisCompra){
                sticker.numeroDisponibles = sticker.numeroDisponibles! + 1;
                _totalSatoshis = _totalSatoshis + sticker.cantidadSatoshis;
                setState(() {});
              }

            },
            icon: const Icon(Icons.add_circle_outline, color: constants.blackGeneral,),
          ),
        ],),
      ],),
    ], mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,);
  }

  Widget _buildCompraRealizada(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: const [
        Text("¡Compra exitosa!",
          style: TextStyle(color: constants.blackGeneral, fontSize: 28),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24,),
        Text("Los stickers fueron agregados a tu cuenta.\nYa puedes enviar a usuarios o chats grupales.",
          style: TextStyle(color: constants.grey, fontSize: 16, height: 1.3,),
          textAlign: TextAlign.center,
        ),
      ], mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,),
    );
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

  Future<void> _cargarStickersVenta() async {
    setState(() {
      _loadingStickersVenta = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlStickersEnVenta,
      queryParams: {},
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        List<dynamic> stickers = datosJson['data']['stickers'];
        for (var element in stickers) {
          _stickersVenta.add(Sticker(
            id: element['id'].toString(),
            cantidadSatoshis: element['valor_satoshis'],
            stickerValorId: element['sticker_valor_id'].toString(),
            numeroDisponibles: 0,
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingStickersVenta = false;
    });
  }

  Future<void> _validarCompraSeleccion() async {
    List<Sticker> stickersSeleccionados = [];

    for(Sticker sticker in _stickersVenta){
      if(sticker.numeroDisponibles! > 0){
        stickersSeleccionados.add(sticker);
      }
    }

    if(stickersSeleccionados.isEmpty){
      _showSnackBar("Selecciona algún sticker presionando el icono +");
      return;
    }

    var isPaid = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => PagarStickersPage(stickers: stickersSeleccionados),
    ));

    if(isPaid != null && isPaid){
      _isCompraRealizada = true;
      setState(() {});
    }
  }

  int _satoshisToARS(int cantidadSatoshis){
    return (cantidadSatoshis * _cotizacionActualSatoshi!).round();
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}