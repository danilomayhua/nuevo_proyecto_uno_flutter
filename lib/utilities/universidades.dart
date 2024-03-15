class Universidades {

  static List<String> getListaUniversidades(){
    List<String> listUniversidades = [];

    listUniversidades.add("9");
    listUniversidades.add("7");
    listUniversidades.add("8");
    listUniversidades.add("3");
    listUniversidades.add("4");

    return listUniversidades;
  }

  static String getNombre(String universidadId){
    switch(universidadId){
      case "3":
        return "UP";
        break;
      case "4":
        return "UB";
        break;
      case "7":
        return "UCEMA";
        break;
      case "8":
        return "UAI";
        break;
      case "9":
        return "UMAI";
        break;
      default:
        return "";
    }
  }

  static String getDescripcion(String universidadId){
    switch(universidadId){
      case "3":
        return "Universidad de Palermo";
        break;
      case "4":
        return "Universidad de Belgrano";
        break;
      case "7":
        return "Universidad del CEMA";
        break;
      case "8":
        return "Universidad Abierta Interamericana";
        break;
      case "9":
        return "Universidad Maimónides";
        break;
      default:
        return "";
    }
  }
}