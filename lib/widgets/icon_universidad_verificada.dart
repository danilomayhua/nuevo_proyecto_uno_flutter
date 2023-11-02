import 'package:flutter/material.dart';

class IconUniversidadVerificada extends StatelessWidget {
  const IconUniversidadVerificada({Key? key, required this.size}) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.verified, size: size, color: Colors.blue,),
        Icon(Icons.circle, size: (size / 100 * 70), color: Colors.blue,),
        Icon(Icons.school_outlined, size: (size / 2), color: Colors.white,),
      ],
    );
  }
}