class Sticker {
  final String id;
  final int cantidadSatoshis;
  String? stickerValorId;
  int? numeroDisponibles;

  Sticker({
    required this.id,
    required this.cantidadSatoshis,
    this.stickerValorId,
    this.numeroDisponibles = 1,
  });

  String? getImageAssetName(){
    if(id == "1"){
      return "assets/sticker_propina.gif";
    } else if(id == "2"){
      return "assets/sticker_cafe.gif";
    } else if(id == "3"){
      return "assets/sticker_sandwich.gif";
    } else if(id == "4"){
      return "assets/sticker_batido.gif";
    } else if(id == "5"){
      return "assets/sticker_pizza.gif";
    } else if(id == "6"){
      return "assets/sticker_menuburger.gif";
    } else {
      return null;
    }
  }
}