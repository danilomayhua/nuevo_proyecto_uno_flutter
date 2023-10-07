import 'package:flutter/material.dart';
import 'package:tenfo/models/actividad.dart';
import 'package:tenfo/screens/actividad/actividad_page.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/actividad_boton_entrar.dart';

class CardActividad extends StatefulWidget {
  CardActividad({Key? key, required this.actividad}) : super(key: key);

  Actividad actividad;

  @override
  _CardActividadState createState() => _CardActividadState();
}

class _CardActividadState extends State<CardActividad> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){

        // TODO : eliminar onChangeIngreso y usar provider (o algo parecido) para actualizar los estados globalmente

        Navigator.push(context, MaterialPageRoute(
            builder: (context) => ActividadPage(
              actividad: widget.actividad,
              onChangeIngreso: (Actividad actividad){
                // No hace nada si ya no existe la actividad (por ej. si se actualizó Inicio automáticamente)
                setState(() {
                  widget.actividad = actividad;
                });
              },
            )
        ));

      },
      child: _contenido(),
    );
  }

  Widget _contenido(){
    return Container(
      //height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: constants.grey),
        color: Colors.white,
      ),
      padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 4,), // bottom es menor, porque el boton inferior tiene un margen agregado
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
          const SizedBox(height: 16,),
          Align(
            alignment: Alignment.center,
            child: Text(widget.actividad.titulo,
              style: TextStyle(color: constants.blackGeneral, fontSize: 18,
                height: 1.3, fontWeight: FontWeight.w500,),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24,),
          /*
          if(widget.actividad.descripcion != null)
            Container(
              alignment: Alignment.centerLeft,
              child: Text(widget.actividad.descripcion ?? "",
                style: TextStyle(color: constants.blackGeneral, fontSize: 14, height: 1.3,),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          SizedBox(height: 24,),
          */
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
              Text(_getTextCocreadores(),
                style: TextStyle(color: constants.grey, fontSize: 12,),
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 16,),
          Align(
            alignment: Alignment.centerRight,
            child: ActividadBotonEntrar(actividad: widget.actividad),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  String _getTextCocreadores(){
    String creadoresNombre = "";

    if(widget.actividad.creadores.length == 1){

      creadoresNombre = widget.actividad.creadores[0].username;

    } else if(widget.actividad.creadores.length >= 1){

      creadoresNombre = widget.actividad.creadores[0].username;
      for(int i = 1; i < (widget.actividad.creadores.length-1); i++){
        creadoresNombre += ", "+widget.actividad.creadores[i].username;
      }
      creadoresNombre += " y "+widget.actividad.creadores[widget.actividad.creadores.length-1].username;

    }

    return creadoresNombre;
  }
}