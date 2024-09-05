import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/screens/login/login_page.dart';
import 'package:tenfo/screens/signup/signup_page.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: SingleChildScrollView(child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height
                - MediaQuery.of(context).padding.top
                - MediaQuery.of(context).padding.bottom,
          ),
          child: Column(children: [
            Column(children: [
              const SizedBox(height: 100),
              Container(
                height: 200,
                width: 200,
                child: Image.asset("assets/logo_tenfo_circular.png"),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                child: Image.asset("assets/logo_letras_tenfo.png"),
              ),
              const SizedBox(height: 24),
            ],),
            Column(children: [

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32,),
                alignment: Alignment.center,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: constants.grey, fontSize: 12,),
                    text: "Al continuar, aceptas los ",
                    children: [
                      TextSpan(
                        text: "Términos",
                        style: const TextStyle(decoration: TextDecoration.underline,),
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
                        text: "Política de Privacidad",
                        style: const TextStyle(decoration: TextDecoration.underline,),
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
                      const TextSpan(
                        text: " y confirmas haberlos leído.",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24,),

              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const SignupPage()
                    ));
                  },
                  child: const Text("Registrarse"),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 16,),
                    padding: const EdgeInsets.symmetric(vertical: 12,),
                    primary: Colors.orange,
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const LoginPage()
                    ));
                  },
                  child: const Text("Iniciar sesión"),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 16,),
                    padding: const EdgeInsets.symmetric(vertical: 12,),
                    primary: Colors.orange,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],),
          ], mainAxisAlignment: MainAxisAlignment.spaceBetween,),
        )),
      ),
    );
  }
}