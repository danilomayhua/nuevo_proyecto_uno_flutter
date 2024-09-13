import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class DialogbottomComprarPremium extends StatefulWidget {
  const DialogbottomComprarPremium({Key? key, required this.titulo,
    required this.onCompraExitosa, required this.onCompraError, this.fromPantalla}) : super(key: key);

  final String titulo;
  final void Function() onCompraExitosa;
  final void Function(String errorMensaje) onCompraError;
  final ComprarPremiumFromPantalla? fromPantalla;

  @override
  _DialogbottomComprarPremiumState createState() => _DialogbottomComprarPremiumState();
}

// Es importante no cambiar los nombres de este enum (se envian al backend)
enum ComprarPremiumFromPantalla { superlikes_recibidos, visitas_instagram }

class _DialogbottomComprarPremiumState extends State<DialogbottomComprarPremium> {

  bool _isAvailable = true;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  final _productIdPremium1 = "suscripcion_premium_1";
  String _precioTexto = "";

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

    // TODO : poner el listen en otro lugar, porque si cierra el dialog justo cuando presiona comprar, no va poder verificar la compra

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
      // _showSnackBar("Se produjo un error al cargar productos"); // Usar _showSnackBar en initState da error

      String error = productDetailResponse.error!.message;
      print(error);

      _cargandoProductos = false;
      setState(() {});
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      // _showSnackBar("No hay productos encontrados"); // Usar _showSnackBar en initState da error

      _cargandoProductos = false;
      setState(() {});
      return;

    } else {

      // Parece que a veces hay un bug en Android que devuelve "Free" en .price (cuando tiene productos con "3-trial-days")
      final productsFinal = _products.where((d) => d.rawPrice > 0).toList();

      if(productsFinal.isNotEmpty){
        _precioTexto = productsFinal[0].price;
      } else {
        _precioTexto = "\$2.99";
      }
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

        bool? valid;

        if (purchaseDetails.status == PurchaseStatus.error) {

          widget.onCompraError("Se produjo un error con el pago.");

        } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
          // TODO : ver como manejar PurchaseStatus.restored

          valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            //widget.onCompraExitosa();
          } else {
            //widget.onCompraError("Surgió un error inesperado al validar tu compra. Por favor comunícate con nosotros.");
          }

        } else if(purchaseDetails.status == PurchaseStatus.canceled){
          print('Compra cancelada');
          // TODO : cambiar _enviandoCompra cuando se cancela la compra ?
        }

        if (purchaseDetails.pendingCompletePurchase) {
          // Completa la compra aunque haya surgido un error al verificar

          //await InAppPurchase.instance.completePurchase(purchaseDetails);
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        if(valid != null){
          // Se comprueba al final porque estas funciones cierran el dialog (aunque parece no afectar) y hay que asegurar completePurchase
          // Esto es de momento hasta que se cambie de lugar purchaseUpdated.listen
          if (valid) {
            widget.onCompraExitosa();
          } else {
            widget.onCompraError("Surgió un error inesperado al validar tu compra. Por favor comunícate con nosotros.");
          }
        }

      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //width: double.maxFinite,
      child: Column(children: [
        Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8,),
          child: GestureDetector(
            onTap: (){
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.clear_rounded, color: Colors.black54,),
          ),
        ),

        Text(widget.titulo,
          style: const TextStyle(color: constants.blackGeneral, fontSize: 20, fontWeight: FontWeight.bold,),
        ),

        if(_cargandoProductos)
          ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32,),
              child: CircularProgressIndicator(),
            ),
          ],

        if(!_cargandoProductos && !_isAvailable)
          ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32,),
              child: Text("Error: tienda no disponible.",
                style: TextStyle(color: constants.grey, fontSize: 14,),
                textAlign: TextAlign.center,
              ),
            ),
          ],

        if(!_cargandoProductos && _isAvailable && _products.isEmpty)
          ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32,),
              child: Text("Se produjo un error: no hay productos disponibles.",
                style: TextStyle(color: constants.grey, fontSize: 14,),
                textAlign: TextAlign.center,
              ),
            ),
          ],

        if(!_cargandoProductos && _isAvailable && _products.isNotEmpty)
          ...[
            const SizedBox(height: 32,),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16,),
              child: Text("Revela los perfiles siendo miembro Pro:",
                style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32,),
              child: Row(children: [
                Container(
                  height: 32,
                  width: 32,
                  child: const Icon(CupertinoIcons.heart_circle_fill, color: Colors.lightGreen, size: 32,),
                ),
                const SizedBox(width: 12,),
                const Expanded(child: Text("Revela quiénes te enviaron Incentivos y conecta más",
                  style: TextStyle(fontSize: 14, color: constants.blackGeneral, fontWeight: FontWeight.bold,),
                ),),
              ], crossAxisAlignment: CrossAxisAlignment.center,),
            ),
            const SizedBox(height: 16,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32,),
              child: Row(children: [
                Container(
                  height: 32,
                  width: 32,
                  padding: const EdgeInsets.all(3),
                  child: Image.asset("assets/instagram_logo.png"),
                ),
                const SizedBox(width: 12,),
                const Expanded(child: Text("Revela quiénes visitaron tu perfil de Instagram",
                  style: TextStyle(fontSize: 14, color: constants.blackGeneral, fontWeight: FontWeight.bold,),
                ),),
              ], crossAxisAlignment: CrossAxisAlignment.center,),
            ),

            const SizedBox(height: 32,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16,),
              child: ElevatedButton(
                onPressed: _enviandoCompra ? null : () => _buySuscription(_productIdPremium1),
                child: _enviandoCompra
                    ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2),)
                    : const Text("Revelar"),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),
            const SizedBox(height: 8,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16,),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: constants.grey, fontSize: 12,),
                  text: Platform.isIOS
                      ? "Se renueva por \$2.99 por mes. Cancela cuando quieras. | "
                      : "Se renueva por $_precioTexto por mes. Cancela cuando quieras. | ", // En Google Play rechazan la aplicacion porque debe mostrar los precios locales
                  children: [
                    TextSpan(
                      text: "Términos",
                      style: const TextStyle(fontWeight: FontWeight.bold,),
                      recognizer: TapGestureRecognizer()..onTap = () async {
                        String urlString = "https://tenfo.app/politica.html";
                        Uri url = Uri.parse(urlString);

                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication,);
                        } catch (e){
                          throw 'Could not launch $urlString';
                        }
                      },
                    ),
                    const TextSpan(
                      text: " y ",
                    ),
                    TextSpan(
                      text: "Privacidad",
                      style: const TextStyle(fontWeight: FontWeight.bold,),
                      recognizer: TapGestureRecognizer()..onTap = () async {
                        String urlString = "https://tenfo.app/politica.html#politica-privacidad";
                        Uri url = Uri.parse(urlString);

                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication,);
                        } catch (e){
                          throw 'Could not launch $urlString';
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24,),
          ],

        const SizedBox(height: 32,),

      ], mainAxisSize: MainAxisSize.min,),
    );
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

        // Envia para analizar comportamiento
        "datos_enviado_desde": (widget.fromPantalla == null) ? null : {"pantalla" : widget.fromPantalla?.name,},
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

    /*
    // Si se envio la compra, se cierra el dialog (despues de completar la compra), asi que no actualizar este valor
    setState(() {
      _enviandoCompra = false;
    });
    */

    return result;
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}