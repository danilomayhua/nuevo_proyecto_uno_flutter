import 'package:flutter/material.dart';

class IconUniversidadVerificada extends StatelessWidget {
  const IconUniversidadVerificada({Key? key, required this.size, this.isEnabled = true}) : super(key: key);

  final double size;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.verified, size: size, color: isEnabled ? Colors.blue : Colors.blueGrey,),
        Icon(Icons.circle, size: (size / 100 * 70), color: isEnabled ? Colors.blue : Colors.blueGrey,),
        Icon(Icons.school_outlined, size: (size / 2), color: Colors.white,),
      ],
    );
  }
}