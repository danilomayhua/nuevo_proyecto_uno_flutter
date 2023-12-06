import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';

class ShareUtils {
  static void shareActivityCocreatorCode(String code, String activityTitle) {

    String textoCompartir = "Unite como cocreador de mi actividad \"$activityTitle\" en Tenfo.\n"
        "Ingresa el siguiente código de invitación al unirte:\n\n"
        "${code.split('').join(' ')}\n\n"
        "Link en App Store: https://apps.apple.com/ar/app/tenfo/id6443714838\n\n"
        "Link en Google Play: https://play.google.com/store/apps/details?id=app.tenfo.mobile";

    Share.share(textoCompartir);
  }

  static Future<void> shareProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    String textoCompartir = "Agregame en Tenfo con mi usuario @${usuarioSesion.username}\n\n"
        "Link en App Store: https://apps.apple.com/ar/app/tenfo/id6443714838\n\n"
        "Link en Google Play: https://play.google.com/store/apps/details?id=app.tenfo.mobile";

    Share.share(textoCompartir);
  }

  static void shareActivity(String activityTitle) async {
    String textoCompartir = "Ingresá a esta actividad en Tenfo:\n\n"
        "$activityTitle\n\n\n"
        "Link en App Store: https://apps.apple.com/ar/app/tenfo/id6443714838\n\n"
        "Link en Google Play: https://play.google.com/store/apps/details?id=app.tenfo.mobile";

    Share.share(textoCompartir);
  }
}