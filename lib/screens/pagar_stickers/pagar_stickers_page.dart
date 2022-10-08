import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PagarStickersPage extends StatefulWidget {
  const PagarStickersPage({Key? key, required this.stickers}) : super(key: key);

  final List<Sticker> stickers;

  @override
  State<PagarStickersPage> createState() => _PagarStickersPageState();
}

class _PagarStickersPageState extends State<PagarStickersPage> {

  List<Sticker> _stickersFactura = [];
  int _totalEnSatoshis = 0;
  double _totalEnBitcoins = 0;
  String _compraId = "";

  String _lightningNetworkInvoice = "";
  Timer? _timerSegundosRestantes;
  int _limiteSegundosRestantes = 0;
  Timer? _timerVerificarPago;

  bool _isLoadingFactura = false;

  @override
  void initState() {
    super.initState();

    _cargarFacturaLN();
  }

  @override
  void dispose() {
    _timerSegundosRestantes?.cancel();
    _timerVerificarPago?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pago"),
      ),
      body: _isLoadingFactura
          ? const Center(child: CircularProgressIndicator(),)
          : _buildFactura(),
    );
  }

  Widget _buildFactura(){
    return SingleChildScrollView(
      child: Column(children: [
        ExpansionTile(
          title: const Text("Detalles",
            style: TextStyle(color: constants.blackGeneral),
          ),
          children: [
            for(Sticker sticker in _stickersFactura)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 0, right: 16, bottom: 16,),
                child: RichText(text: TextSpan(
                  style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
                  children: [
                    TextSpan(text: "Sticker ${sticker.cantidadSatoshis} sats "),
                    TextSpan(text: "x${sticker.numeroDisponibles}",
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
        /*ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _isExpandedDetalles = !isExpanded;
              });
            },
            expandedHeaderPadding: EdgeInsets.all(0),
            elevation: 0,
            children: [ExpansionPanel(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  title: Text("Detalles"),
                );
              },
              body: Text("Stickers x2"),
              isExpanded: _isExpandedDetalles,
              backgroundColor: Colors.transparent,
            ),],
          ),*/
        const SizedBox(height: 8,),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          child: Text("Pagar con Bitcoin en Lightning Network",
            style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
          ),
        ),
        const SizedBox(height: 16,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Total: $_totalEnSatoshis sats ($_totalEnBitcoins btc)",
            style: const TextStyle(color: constants.blackGeneral, fontSize: 16,),
          ),
        ),
        const SizedBox(height: 24,),
        Container(
          width: double.infinity,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(_secondsToMinutes(_limiteSegundosRestantes),
            style: const TextStyle(color: constants.blackGeneral, fontSize: 12,),
          ),
        ),
        const SizedBox(height: 16,),
        /*Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () async {
              Uri url = Uri.parse("lightning:$_lightningNetworkInvoice");

              try {
                await launchUrl(url, mode: LaunchMode.externalApplication,);
              } catch(e){
                _showSnackBar("No se encontró una billetera compatible.");
              }
            },
            icon: const Icon(Icons.payment_outlined),
            label: const Text("Abrir en billetera"),
          ),
        ),
        const SizedBox(height: 16,),
        const Align(
          alignment: Alignment.center,
          //child: Text("O mostrar",
          child: Text("O copiar",
            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
          ),
        ),
        const SizedBox(height: 16,),*/
        /*Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: (){
              // Hacer que _verificarPago() cierre primero el dialog
              _showDialogCodigoQR();
            },
            icon: const Icon(Icons.qr_code_2_outlined),
            label: const Text("Código QR"),
            style: ElevatedButton.styleFrom(
              primary: Colors.white,
              onPrimary: constants.blueGeneral,
            ),
          ),
        ),
        const SizedBox(height: 24,),*/
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16,),
          //child: Text("Factura Lightning Network",
          child: Text("Copiar factura Lightning Network:",
            style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
          ),
        ),
        const SizedBox(height: 8,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: InputDecorator(
              decoration: const InputDecoration(
                enabled: false,
                isDense: true,
                hintStyle: TextStyle(fontSize: 12,),
                //counterText: '',
                border: OutlineInputBorder(),
              ),
              child: Text(_lightningNetworkInvoice,
                style: const TextStyle(fontSize: 12,),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),),
            IconButton(
              onPressed: (){
                Clipboard.setData(ClipboardData(text: _lightningNetworkInvoice))
                    .then((value) => _showSnackBar("Enlace copiado"));
              },
              icon: const Icon(Icons.content_copy_outlined,
                size: 24,
                color: constants.blackGeneral,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxWidth: 40,),
            ),
          ],),
        ),
        const SizedBox(height: 24,),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Una vez realizada la transacción, en unos segundos se agregarán los stickers.",
            style: TextStyle(color: constants.grey, fontSize: 12,),
          ),
        ),
        const SizedBox(height: 16,),
      ], crossAxisAlignment: CrossAxisAlignment.start,),
    );
  }

  void _showDialogCodigoQR(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        content: Container(
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300,),
          child: Image.asset("assets/qr_code_example.png"),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Listo"),
          ),
        ],
      );
    });
  }

  Future<void> _cargarFacturaLN() async {
    setState(() {
      _isLoadingFactura = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    List<dynamic> compraDetalles = [];
    for(Sticker sticker in widget.stickers){
      compraDetalles.add({
        "sticker_valor_id": sticker.stickerValorId,
        "cantidad": sticker.numeroDisponibles.toString()
      });
    }

    var response = await HttpService.httpPost(
      url: constants.urlCrearCompra,
      body: {
        "compra_detalles": compraDetalles
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        _compraId = datosJson['data']['compra_id'].toString();

        _lightningNetworkInvoice = datosJson['data']['pago_lightning']['invoice'];

        List<dynamic> stickers = datosJson['data']['compra_detalles'];
        for (var element in stickers) {
          _stickersFactura.add(Sticker(
            id: element['sticker_id'].toString(),
            cantidadSatoshis: element['valor_satoshis'],
            stickerValorId: element['sticker_valor_id'].toString(),
            numeroDisponibles: element['cantidad'],
          ));
        }

        _totalEnSatoshis = datosJson['data']['total_satoshis'];
        _totalEnBitcoins = _totalEnSatoshis / 100000000;

        _timerVerificarPago = Timer.periodic(const Duration(seconds: 15), (Timer timer) {
          _verificarPago(timer);
        },);

        _limiteSegundosRestantes = datosJson['data']['pago_lightning']['secondsToExpire'];
        _timerSegundosRestantes = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          if(_limiteSegundosRestantes == 0){
            setState(() {
              timer.cancel();
              _timerVerificarPago?.cancel();
            });
          } else {
            setState(() {
              _limiteSegundosRestantes--;
            });
          }
        },);

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _isLoadingFactura = false;
    });
  }

  Future<void> _verificarPago(Timer timer) async {
    // Recibir notificacion mediante firebase no haria necesario llamar al endpoint reiteradas veces

    var response = await HttpService.httpGet(
      url: constants.urlVerificarCompra,
      queryParams: {
        "compra_id": _compraId
      },
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        bool isPaid = datosJson['data']['is_paid'];
        if(isPaid){
          // dispose() no se llama en background
          timer.cancel();
          Navigator.pop(context, true);
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }
  }

  String _secondsToMinutes(int segundos){
    int min = segundos ~/ 60;
    int sec = segundos % 60;

    String parsedTime = (min < 10 ? "0$min" : "$min")
        + ":" + (sec < 10 ? "0$sec" : "$sec");

    return parsedTime;
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}