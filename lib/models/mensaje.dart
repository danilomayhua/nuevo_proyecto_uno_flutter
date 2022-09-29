import 'package:tenfo/models/sticker.dart';
import 'package:tenfo/models/usuario.dart';

enum MensajeTipo {NORMAL, GRUPO_INGRESO, GRUPO_SALIDA, GRUPO_ELIMINAR_USUARIO, GRUPO_ENCUENTRO_FECHA, GRUPO_ENCUENTRO_LINK, PROPINA_STICKER}

class MensajePropinaSticker {
  final Sticker sticker;
  final bool isRecibido;

  MensajePropinaSticker({required this.sticker, required this.isRecibido});
}

class Mensaje {
  final String id;
  final MensajeTipo tipo;
  final String fecha;
  final String fechaCompleto;
  final String? contenido;
  final Usuario autorUsuario;
  final bool isEntrante;

  final Usuario? grupoEliminadoUsuario;
  final String? grupoEncuentroFecha;
  final MensajePropinaSticker? propinaSticker;

  Mensaje({required this.id, required this.tipo, required this.fecha, required this.fechaCompleto,
      required this.contenido, required this.autorUsuario, required this.isEntrante,
      this.grupoEliminadoUsuario, this.grupoEncuentroFecha, this.propinaSticker});

  static MensajeTipo getMensajeTipoFromString(String tipoString){
    if(tipoString == "GRUPO_INGRESO"){
      return MensajeTipo.GRUPO_INGRESO;
    } else if(tipoString == "GRUPO_SALIDA"){
      return MensajeTipo.GRUPO_SALIDA;
    } else if(tipoString == "GRUPO_ELIMINAR_USUARIO"){
      return MensajeTipo.GRUPO_ELIMINAR_USUARIO;
    } else if(tipoString == "GRUPO_ENCUENTRO_FECHA"){
      return MensajeTipo.GRUPO_ENCUENTRO_FECHA;
    } else if(tipoString == "GRUPO_ENCUENTRO_LINK"){
      return MensajeTipo.GRUPO_ENCUENTRO_LINK;
    } else if(tipoString == "PROPINA_STICKER"){
      return MensajeTipo.PROPINA_STICKER;
    } else {
      return MensajeTipo.NORMAL;
    }
  }

  static String grupoEncuentroFechaToText(String milliseconds){
    DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(milliseconds));

    String hora = date.hour.toString().padLeft(2, '0');
    String minuto = date.minute.toString().padLeft(2, '0');
    String dia = date.day.toString().padLeft(2, '0');
    String mes = date.month.toString().padLeft(2, '0');

    return "El $dia/$mes a las $hora:$minuto hs";
  }

}
