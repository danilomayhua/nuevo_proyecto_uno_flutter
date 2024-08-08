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

  bool _enviando = false;

  @override
  void initState() {
    super.initState();

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
      print("Entro aqui A");
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: (){
      print("Entro aqui C");
      _subscription?.cancel();
    }, onError: (error){
      // handle error here.
      print("Entro aqui B");
      print(error);
    });

    _isAvailable = await _inAppPurchase.isAvailable();
    if(!_isAvailable){
      _showSnackBar("No está habilitado las compras");
      return;
    }


    const _productIds = <String>{"subscription_prueba_1",};

    final ProductDetailsResponse productDetailResponse = await _inAppPurchase.queryProductDetails(_productIds);
    _products = productDetailResponse.productDetails;

    if (productDetailResponse.error != null) {
      _showSnackBar("Se produjo un error al cargar productos");

      String error = productDetailResponse.error!.message;
      print(error);

      setState(() {});
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      _showSnackBar("No hay productos encontrados");

      setState(() {});
      return;
    }

    setState(() {});
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {

        print('purchase is in pending');
        //_showPendingUI();

      } else {

        if (purchaseDetails.status == PurchaseStatus.error) {

          print('purchase error');
          //_handleError(purchaseDetails.error!);

        } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
          if(purchaseDetails.status == PurchaseStatus.purchased){
            print('purchased');
          }
          if(purchaseDetails.status == PurchaseStatus.restored){
            print('purchase restore');
          }

          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {

            //_deliverProduct(purchaseDetails);
            _showSnackBar("¡Ahora eres usuario premium!");

          } else {
            //_handleInvalidPurchase(purchaseDetails);
            _showSnackBar("Compra no valida en backend");
            return;
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          //await InAppPurchase.instance.completePurchase(purchaseDetails);

          await _inAppPurchase.completePurchase(purchaseDetails);

          /*await _inAppPurchase.completePurchase(purchaseDetails).then((value){
            if(purchaseDetails.status == PurchaseStatus.purchased){
              //on purchase success you can call your logic and your API here.
            }
          });*/
        }

        if(purchaseDetails.status == PurchaseStatus.canceled){
          print('purchase cancel');
        }

      }
    };
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    bool result = false;

    setState(() {
      _enviando = true;
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
      _enviando = false;
    });

    return result;
  }

  Future<void> _buySuscription() async {
    if(_products.isNotEmpty){
      final purchaseParam = PurchaseParam(productDetails: _products[0]);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comprar suscripción"),
      ),
      body: Center(
        child: !_isAvailable ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Tienda no habilitada.",
            style: TextStyle(color: constants.grey, fontSize: 14,),
            textAlign: TextAlign.center,
          ),
        ) : _products.isEmpty
            ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("No hay productos para comprar.",
                style: TextStyle(color: constants.grey, fontSize: 14,),
                textAlign: TextAlign.center,
              ),
            )
            : Column(children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Actualiza a la versión premium:",
                  style: TextStyle(color: constants.grey, fontSize: 14,),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24,),
              OutlinedButton(
                onPressed: (){
                  _buySuscription();
                },
                child: const Text("Comprar"),
              ),
            ],),
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