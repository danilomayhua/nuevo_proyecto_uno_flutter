import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class ComprarSuscripcionPage extends StatefulWidget {
  const ComprarSuscripcionPage({Key? key}) : super(key: key);

  @override
  State<ComprarSuscripcionPage> createState() => _ComprarSuscripcionPageState();
}

class _ComprarSuscripcionPageState extends State<ComprarSuscripcionPage> {

  bool _isAvailable = true;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  final _productIdPremium1 = "suscripcion_premium_1";

  bool _cargandoProductos = false;
  bool _enviandoCompra = false;

  @override
  void initState() {
    super.initState();

    _cargandoProductos = true;
    setState(() {});

    _iniciarIAP();
  }

  @override
  void dispose() {
    _subscription?.cancel();

    super.dispose();
  }

  Future<void> _iniciarIAP() async {
    //final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;

    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: (){
      _subscription?.cancel();
    }, onError: (error){
      print("Error con _subscription:");
      print(error);
    });

    _isAvailable = await _inAppPurchase.isAvailable();
    if(!_isAvailable){
      _cargandoProductos = false;
      setState(() {});
      return;
    }


    var _productIds = <String>{_productIdPremium1,};

    final ProductDetailsResponse productDetailResponse = await _inAppPurchase.queryProductDetails(_productIds);
    _products = productDetailResponse.productDetails;

    if (productDetailResponse.error != null) {
      _showSnackBar("Se produjo un error al cargar productos");

      String error = productDetailResponse.error!.message;
      print(error);

      _cargandoProductos = false;
      setState(() {});
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      _showSnackBar("No hay productos encontrados");

      _cargandoProductos = false;
      setState(() {});
      return;
    }

    _cargandoProductos = false;
    setState(() {});
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {

        _enviandoCompra = true;
        setState(() {});

      } else {

        if (purchaseDetails.status == PurchaseStatus.error) {

          _showSnackBar("Se produjo un error con el pago.");

        } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
          // TODO : ver como manejar PurchaseStatus.restored

          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {

            _showSnackBar("¡Ahora eres usuario premium!");

          } else {
            _showSnackBar("Surgió un error inesperado al validar tu compra. Por favor comunícate con nosotros.");
          }

        } else if(purchaseDetails.status == PurchaseStatus.canceled){
          print('Compra cancelada');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          // Completa la compra aunque haya surgido un error al verificar

          //await InAppPurchase.instance.completePurchase(purchaseDetails);
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

      }
    };
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    bool result = false;

    setState(() {
      _enviandoCompra = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCompraIapVerificarSuscripcion,
      body: {
        "source": purchaseDetails.verificationData.source,
        "productId": purchaseDetails.productID,
        "verificationData": purchaseDetails.verificationData.serverVerificationData,
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = jsonDecode(response.body);

      if(datosJson['error'] == false){

        result = true;

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _enviandoCompra = false;
    });

    return result;
  }

  Future<void> _buySuscription(String productId) async {
    if(_products.isNotEmpty){

      PurchaseParam? purchaseParam;

      for (var element in _products) {
        if(element.id == productId){
          purchaseParam = PurchaseParam(productDetails: element);
          break;
        }
      }

      if(purchaseParam != null){
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comprar suscripción"),
      ),
      body: _cargandoProductos ? const Center(child: CircularProgressIndicator(),) : Center(
        child: !_isAvailable ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Tienda no habilitada.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ) : _products.isEmpty
            ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16,),
              child: Text("Se produjo un error (no hay productos para comprar).",
                style: TextStyle(color: constants.grey, fontSize: 14,),
                textAlign: TextAlign.center,
              ),
            )
            : Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_enviandoCompra ? "Enviando compra..." : "Actualiza a la versión premium:",
                  style: const TextStyle(color: constants.grey, fontSize: 14,),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24,),
              OutlinedButton(
                onPressed: _enviandoCompra ? null : () => _buySuscription(_productIdPremium1),
                child: const Text("Comprar"),
              ),
            ], mainAxisAlignment: MainAxisAlignment.center,),
      ),
    );
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}