import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareUtils {
  static void shareActivityCocreatorCode(String code, String activityTitle) {

    String textoCompartir = "Unite como cocreador de mi actividad \"$activityTitle\" en Tenfo.\n"
        "Ingresa el siguiente código de invitación al unirte:\n\n"
        "${code.split('').join(' ')}\n\n"
        "Link en App Store: https://apps.apple.com/ar/app/tenfo/id6443714838\n\n"
        "Link en Google Play: https://play.google.com/store/apps/details?id=app.tenfo.mobile";

    Share.share(textoCompartir);
  }

  static Future<void> shareProfile(UsuarioSesion? usuarioSesion) async {

    if(usuarioSesion == null){
      SharedPreferences prefs = await SharedPreferences.getInstance();
      usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);
    }

    String textoCompartir = "https://tenfo.app/add-friend/${usuarioSesion.username}";

    Share.share(textoCompartir);
  }

  static Future<void> shareProfileWhatsapp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    String textoCompartir = "Unete a mi grupo de amigos en Tenfo https://tenfo.app/add-friend/${usuarioSesion.username}";

    String urlString = "https://wa.me/?text=${Uri.encodeFull(textoCompartir)}";

    Uri url = Uri.parse(urlString);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication,);
    } catch (e){
      throw 'Could not launch $urlString';
    }
  }

  static Future<void> shareProfileWhatsappNumber(String numberE164) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    String textoCompartir = "Unete a mi grupo de amigos en Tenfo https://tenfo.app/add-friend/${usuarioSesion.username}";

    String urlString = "https://wa.me/${numberE164}?text=${Uri.encodeFull(textoCompartir)}";

    Uri url = Uri.parse(urlString);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication,);
    } catch (e){
      throw 'Could not launch $urlString';
    }
  }

  static Future<void> shareActivityCocreatorWhatsappNumber(String numberE164, String invitacionCodigo) async {
    String textoCompartir = "Unite a mi actividad en Tenfo: https://tenfo.app/activity-creator/$invitacionCodigo";

    String urlString = "https://wa.me/${numberE164}?text=${Uri.encodeFull(textoCompartir)}";

    Uri url = Uri.parse(urlString);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication,);
    } catch (e){
      throw 'Could not launch $urlString';
    }
  }

  static Future<void> shareActivityCocreator(String invitacionCodigo) async {
    String textoCompartir = "Unite a mi actividad en Tenfo: https://tenfo.app/activity-creator/$invitacionCodigo";

    Share.share(textoCompartir);
  }

  static Future<void> shareActivity(String actividadId) async {
    //String textoCompartir = "Unite a esta actividad en Tenfo: https://tenfo.app/join-activity/$actividadId";
    String textoCompartir = "https://tenfo.app/join-activity/$actividadId";

    Share.share(textoCompartir);
  }

  static Future<void> shareActivityWhatsapp(String actividadId) async {
    String textoCompartir = "https://tenfo.app/join-activity/$actividadId";

    String urlString = "https://wa.me/?text=${Uri.encodeFull(textoCompartir)}";

    Uri url = Uri.parse(urlString);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication,);
    } catch (e){
      throw 'Could not launch $urlString';
    }
  }

  static Future<void> copyLinkActivity(String actividadId) async {
    String textoCompartir = "https://tenfo.app/join-activity/$actividadId";

    await Clipboard.setData(ClipboardData(text: textoCompartir));
  }
}