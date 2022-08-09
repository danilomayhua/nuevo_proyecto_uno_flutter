import 'package:tenfo/models/sticker_recibido.dart';

class ItemStickerRecibido {
  final StickerRecibido stickerRecibido;
  bool seleccionado;

  ItemStickerRecibido({
    required this.stickerRecibido,
    this.seleccionado = false
  });
}