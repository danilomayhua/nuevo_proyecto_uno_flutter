import 'package:share_plus/share_plus.dart';

class ShareUtils {
  static void shareActivityCocreatorCode(String code, String activityTitle) {

    String textoCompartir = "Unite como cocreador de mi actividad \"$activityTitle\" en Tenfo.\n"
        "Ingresa el siguiente código de invitación al unirte:\n\n"
        "${code.split('').join(' ')}\n\n"
        "Link en App Store: https://apps.apple.com/ar/app/tenfo/id6443714838\n\n"
        "Link en Google Play: https://play.google.com/store/apps/details?id=app.tenfo.mobile";

    Share.share(textoCompartir);
  }
}