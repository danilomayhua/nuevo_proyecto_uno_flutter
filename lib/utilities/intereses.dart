import 'package:flutter/material.dart';

class Intereses {

  static List<String> getListaIntereses(){
    List<String> listIntereses = [];

    listIntereses.add("5");
    listIntereses.add("3");
    listIntereses.add("2");
    listIntereses.add("4");
    listIntereses.add("1");

    /*listIntereses.add("6");
    listIntereses.add("7");*/

    return listIntereses;
  }

  static String getNombre(String interesId){
    switch(interesId){
      case "1":
        return "Otros";
        break;
      case "2":
        return "Estudios";
        break;
      case "3":
        return "Deportes";
        break;
      case "4":
        return "Videojuegos";
        break;
      case "5":
        return "Fiesta";
        break;
      /*case "6":
        return "Arte";
        break;
      case "7":
        return "Cómics/Manga/Anime";
        break;*/
      default:
        return "";
    }
  }

  static Icon getIcon(String interesId, {double? size}){
    switch(interesId){
      case "1":
        return Icon(Icons.emoji_objects_outlined, color: Colors.amber, size: size,);
        break;
      case "2":
        return Icon(Icons.school_outlined, color: Colors.purple, size: size,);
        break;
      case "3":
        return Icon(Icons.sports_outlined, color: Colors.blueGrey, size: size,);
        break;
      case "4":
        return Icon(Icons.sports_esports, color: Colors.indigoAccent, size: size,);
        break;
      case "5":
        return Icon(Icons.local_bar_outlined, color: Colors.deepOrangeAccent, size: size,);
        break;
      /*case "6":
        return Icon(Icons.color_lens_outlined, color: Colors.black,);
        break;
      case "7":
        return Icon(Icons.menu_book, color: Colors.black,);
        break;*/
      default:
        return const Icon(null);
    }
  }

  static String getDescripcion(String interesId){
    switch(interesId){
      case "1":
        return "Actividades de interés general u otros.";
        break;
      case "2":
        return "Por ej. encuentros para practicar inglés, charlar sobre un tema de estudio, encuentros para networking, etc.";
        break;
      case "3":
        return "Por ej. hacer un partido de futbol, partido de básquet, salir a una caminata, etc.";
        break;
      case "4":
        return "Por ej. hacer equipos para juegos de PC, juegos de celular, encuentros para jugar en consola, etc.";
        break;
      case "5":
        return "Por ej. hacer una juntada, previa para una fiesta, juntarse para ir a un recital, etc.";
        break;
      default:
        return "";
    }
    // return "Haz grupos para alguna actividad relacionado a este interés.";
  }
}