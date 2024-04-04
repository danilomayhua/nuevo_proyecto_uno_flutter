import 'package:flutter/material.dart';
import 'package:tenfo/screens/principal/principal_page.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

class SignupTutorialPage extends StatefulWidget {
  const SignupTutorialPage({Key? key}) : super(key: key);

  @override
  State<SignupTutorialPage> createState() => _SignupTutorialPageState();
}

class _SignupTutorialPageState extends State<SignupTutorialPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,),
          child: Column(children: [
            const SizedBox(height: 16,),

            const Text("¿Cómo funciona Tenfo?",
              style: TextStyle(color: constants.blackGeneral, fontSize: 24,),
            ),

            const SizedBox(height: 32,),

            const Align(
              alignment: Alignment.center,
              child: Text("Publica una actividad o estado para desbloquear lo que otros están compartiendo.",
                style: TextStyle(color: constants.blackGeneral, fontSize: 14,),
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 56,),

            Row(children: [
              Container(
                width: 50,
                child: const Icon(Icons.groups),
              ),
              Expanded(child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: constants.blackGeneral, fontSize: 15, height: 1.3,),
                  children: [
                    TextSpan(
                      text: "Actividad:",
                      style: TextStyle(color: constants.blackGeneral, fontWeight: FontWeight.bold, fontSize: 16,),
                    ),
                    TextSpan(
                      text: " Sugiere o invita a realizar una actividad y otros usuarios pueden unirse.",
                    )
                  ],
                ),
              ),),
            ], crossAxisAlignment: CrossAxisAlignment.start,),

            const SizedBox(height: 48,),

            Row(children: [
              Container(
                width: 50,
                child: const Icon(Icons.person),
              ),
              Expanded(child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: constants.blackGeneral, fontSize: 15, height: 1.3,),
                  children: [
                    TextSpan(
                      text: "Estado:",
                      style: TextStyle(color: constants.blackGeneral, fontWeight: FontWeight.bold, fontSize: 16,),
                    ),
                    TextSpan(
                      text: " Indica que solo estás viendo actividades para unirte.",
                    )
                  ],
                ),
              ),),
            ], crossAxisAlignment: CrossAxisAlignment.start,),

            const SizedBox(height: 56,),

            const Align(
              alignment: Alignment.center,
              child: Text("Todas las publicaciones desaparecen después de 48 horas, obteniendo más espontaneidad y privacidad 😊.",
                style: TextStyle(color: constants.blackGeneral,),
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 32,),

            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (){
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                      builder: (context) => const PrincipalPage(isFromSignup: true,)
                  ), (root) => false);
                },
                child: const Text("Comenzar"),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),
            const SizedBox(height: 16,),
          ],),
        ),
      ),),),
    );
  }
}