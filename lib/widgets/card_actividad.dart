import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/screens/actividad/actividad_page.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/actividad_boton_entrar.dart';

class CardActividad extends StatefulWidget {
  const CardActividad({Key? key, required this.actividad}) : super(key: key);

  final Actividad actividad;

  @override
  _CardActividadState createState() => _CardActividadState();
}

class _CardActividadState extends State<CardActividad> {
  String _creadoresNombre = "";

  @override
  void initState() {
    super.initState();

    if(widget.actividad.creadores.length == 1){

      _creadoresNombre = widget.actividad.creadores[0].username;

    } else if(widget.actividad.creadores.length >= 1){

      _creadoresNombre = widget.actividad.creadores[0].username;
      for(int i = 1; i < (widget.actividad.creadores.length-1); i++){
        _creadoresNombre += ", "+widget.actividad.creadores[i].username;
      }
      _creadoresNombre += " y "+widget.actividad.creadores[widget.actividad.creadores.length-1].username;

    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => ActividadPage(actividad: widget.actividad)
        ));
      },
      child: _contenido(),
    );
  }

  Widget _contenidoVersionAlternativa(){
    return Container(
      //height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: constants.grey),
        color: constants.greyBackgroundScreen,
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10),),
              color: Colors.white,
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(children: [
              Text(widget.actividad.titulo,
                style: TextStyle(color: constants.blackGeneral, fontSize: 18,
                  height: 1.3, fontWeight: FontWeight.w500,),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                //constraints: BoxConstraints(minHeight: 84),
                constraints: BoxConstraints(minHeight: 64),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(widget.actividad.descripcion ?? "",
                  style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.4,),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ], crossAxisAlignment: CrossAxisAlignment.start,),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: constants.grey)),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(widget.actividad.getPrivacidadTipoString(),
                      style: TextStyle(color: constants.grey, fontSize: 14,),
                    ),
                    const Spacer(),
                    Text(widget.actividad.fecha,
                      style: TextStyle(color: constants.grey, fontSize: 12,),
                    )
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                      child: Row(children: [
                        SizedBox(
                          width: 55, //(15 * numLista) + 10
                          height: 20,
                          child: Stack(
                            children: [
                              Container(),
                              Positioned(
                                left: 30,
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle,
                                    border: Border.all(color: constants.grey),),
                                  height: 20,
                                  width: 20,
                                ),
                              ),
                              Positioned(
                                left: 15,
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle,
                                    border: Border.all(color: constants.grey),),
                                  height: 20,
                                  width: 20,
                                ),
                              ),
                              Positioned(
                                left: 0,
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle,
                                    border: Border.all(color: constants.grey),),
                                  height: 20,
                                  width: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Text("armandocasas, estebanquito y carlos18",
                            style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],),
                    ),
                    SizedBox(width: 2,),
                    (widget.actividad.id == "2")
                        ? _versionAlternativaBotonEntrar(0)
                        : (widget.actividad.id == "3")
                        ? _versionAlternativaBotonEntrar(1)
                        : _versionAlternativaBotonEntrar(2),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              ],
            ),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Widget _versionAlternativaBotonEntrar(int estados){
    if(estados == 0){
      return OutlinedButton.icon(
        onPressed: (){},
        //onPressed: null,
        icon: const Icon(Icons.north_east, size: 16,),
        label: const Text("En espera", style: TextStyle(fontSize: 12),),
        style: OutlinedButton.styleFrom(
          primary: Colors.white,
          backgroundColor: constants.blueGeneral,
          //onSurface: constants.grey,
          side: const BorderSide(color: Colors.transparent, width: 0.5,),
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
    } else if(estados == 1){
      return OutlinedButton.icon(
        onPressed: (){},
        //onPressed: null,
        icon: const Icon(Icons.near_me, size: 16,),
        label: const Text("Ir al chat grupal", style: TextStyle(fontSize: 12),),
        style: OutlinedButton.styleFrom(
          primary: Colors.white,
          backgroundColor: constants.blueGeneral,
          //onSurface: constants.grey,
          side: const BorderSide(color: Colors.transparent, width: 0.5,),
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: (){},
        //onPressed: null,
        icon: const Icon(Icons.north_east, size: 16,),
        label: const Text("Unirse", style: TextStyle(fontSize: 12),),
        style: OutlinedButton.styleFrom(
          primary: constants.blueGeneral,
          backgroundColor: Colors.white,
          //onSurface: constants.grey,
          side: const BorderSide(color: constants.blueGeneral, width: 0.5,),
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
    }
  }

  Widget _contenido(){
    return Container(
      //height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: constants.grey),
        color: Colors.white,
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(widget.actividad.getPrivacidadTipoString(),
                style: TextStyle(color: constants.grey, fontSize: 12,),
              ),
              Text(" • " + widget.actividad.fecha,
                style: TextStyle(color: constants.greyLight, fontSize: 12,),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.end,
          ),
          const SizedBox(height: 4,),
          Text(widget.actividad.titulo,
            style: TextStyle(color: constants.blackGeneral, fontSize: 18,
              height: 1.3, fontWeight: FontWeight.w500,),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            //constraints: BoxConstraints(minHeight: 84),
            constraints: BoxConstraints(minHeight: 64),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(widget.actividad.descripcion ?? "",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.4,),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 8,),
          Row(
            children: [
              SizedBox(
                width: (15 * widget.actividad.creadores.length) + 10,
                height: 20,
                child: Stack(
                  children: [
                    Container(),
                    for (int i=(widget.actividad.creadores.length-1); i>=0; i--)
                      Positioned(
                        left: (15 * i).toDouble(),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: constants.grey),
                          ),
                          height: 20,
                          width: 20,
                          child: CircleAvatar(
                            backgroundColor: constants.greyBackgroundImage,
                            backgroundImage: NetworkImage(widget.actividad.creadores[i].foto),
                            //radius: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(_creadoresNombre,
                style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 8,),
          Align(
            alignment: Alignment.centerRight,
            child: ActividadBotonEntrar(actividad: widget.actividad),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}