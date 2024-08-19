import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/models/visita_instagram.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/dialogbottom_comprar_premium.dart';

class VisitasInstagramPage extends StatefulWidget {
  const VisitasInstagramPage({Key? key}) : super(key: key);

  @override
  State<VisitasInstagramPage> createState() => _VisitasInstagramPageState();
}

class _VisitasInstagramPageState extends State<VisitasInstagramPage> {

  bool? _isUsuarioPremium;

  List<VisitaInstagram> _visitasInstagram = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingVisitasInstagram = false;
  bool _verMasVisitasInstagram = false;
  String _ultimoVisitasInstagram = "false";

  @override
  void initState() {
    super.initState();

    _cargarVisitasInstagram();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingVisitasInstagram && _verMasVisitasInstagram){
          _cargarVisitasInstagram();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Visualizaciones"),
      ),
      body: (_visitasInstagram.isEmpty) ? Center(

        child: _loadingVisitasInstagram ? const CircularProgressIndicator() : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: const [
            Text("No hay visualizaciones nuevas a tu perfil de Instagram.",
              style: TextStyle(color: constants.grey, fontSize: 16,),
              textAlign: TextAlign.center,
            ),
          ], mainAxisSize: MainAxisSize.min,),
        ),

      ) : (_isUsuarioPremium ?? false)
          ? _buildBodyUsuarioPremium()
          : _buildBodyUsuarioNoPremium()
      ,
    );
  }

  Widget _buildBodyUsuarioPremium(){
    return ListView.builder(
      controller: _scrollController,
      itemCount: _visitasInstagram.length + 1, // +1 mostrar cargando
      itemBuilder: (context, index){
        if(index == _visitasInstagram.length){
          return _buildLoadingVisitaInstagram();
        }

        return _buildVisitaInstagram(_visitasInstagram[index]);
      },
    );
  }

  Widget _buildBodyUsuarioNoPremium(){
    return Stack(children: [
      ListView.builder(
        controller: _scrollController,
        itemCount: _visitasInstagram.length + 1, // +1 mostrar cargando
        itemBuilder: (context, index){
          if(index == _visitasInstagram.length){
            return _buildLoadingVisitaInstagram();
          }

          return _buildVisitaInstagram(_visitasInstagram[index]);
        },
      ),
      Positioned(
        bottom: 40,
        left: 24,
        right: 24,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, minHeight: 48,),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showDialogComprarPremium(),
            child: const Text("¿Quién vio mi Instagram? 👀"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),
      ),
    ],);
  }

  Widget _buildVisitaInstagram(VisitaInstagram visitaInstagram){
    if(visitaInstagram.autor != null){
      return ListTile(
        title: Text("${visitaInstagram.autor!.nombreCompleto} visitó tu perfil de Instagram.",
          style: TextStyle(
            fontSize: 14,
            color: constants.blackGeneral,
            fontWeight: visitaInstagram.isNuevo ? FontWeight.bold : null,
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundColor: constants.greyBackgroundImage,
          backgroundImage: CachedNetworkImageProvider(visitaInstagram.autor!.foto),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            margin: const EdgeInsets.only(left: 24, top: 24,),
            height: 16,
            width: 16,
            padding: const EdgeInsets.all(3),
            child: Image.asset("assets/instagram_logo.png"),
          ),
        ),
        trailing: Text(visitaInstagram.fecha,
          style: const TextStyle(fontSize: 10, color: constants.grey,),
        ),
        onTap: (){
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => UserPage(usuario: visitaInstagram.autor!.toUsuario(),)),
          );
        },
        tileColor: visitaInstagram.isNuevo ? constants.greenLightBackground : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16,),
      );
    }

    String? universidadNombre = visitaInstagram.previsualizacionAutor!.universidadNombre;

    return ListTile(
      title: Text("Un/a estudiante ${universidadNombre == null ? "" : "de la "+universidadNombre+" "}(${visitaInstagram.previsualizacionAutor!.edad} años) "
          "visitó tu perfil de Instagram.",
        style: TextStyle(
          fontSize: 14,
          color: constants.blackGeneral,
          fontWeight: visitaInstagram.isNuevo ? FontWeight.bold : null,
        ),
      ),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: constants.greyLight, width: 0.5,),
        ),
        height: 40,
        width: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Image.asset("assets/instagram_logo.png"),
      ),
      trailing: Text(visitaInstagram.fecha,
        style: const TextStyle(fontSize: 10, color: constants.grey,),
      ),
      onTap: () => _showDialogComprarPremium(),
      tileColor: visitaInstagram.isNuevo ? constants.greenLightBackground : Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16,),
    );
  }

  Widget _buildLoadingVisitaInstagram(){
    if(_loadingVisitasInstagram){
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Container();
    }
  }

  void _showDialogComprarPremium(){
    bool isClosed = false;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context){
        return DialogbottomComprarPremium(
          titulo: "¿Quién vio mi Instagram?",
          onCompraExitosa: (){
            if(!isClosed){
              // Nunca entraria aqui, porque si cierra el dialog, no puede procesar los eventos de la compra
              Navigator.pop(context);
            }

            _recargarVisitasInstagram();
          },
          onCompraError: (errorMensaje){
            if(!isClosed){
              // Nunca entraria aqui, porque si cierra el dialog, no puede procesar los eventos de la compra
              Navigator.pop(context);
            }
            _showSnackBar(errorMensaje);
          },
          fromPantalla: ComprarPremiumFromPantalla.visitas_instagram,
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0),),
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
    ).then((value){
      isClosed = true;
    });
  }

  void _recargarVisitasInstagram(){
    _loadingVisitasInstagram = true;
    _verMasVisitasInstagram = false;
    _ultimoVisitasInstagram = "false";

    _visitasInstagram = [];

    _cargarVisitasInstagram();
  }

  Future<void> _cargarVisitasInstagram() async {
    setState(() {
      _loadingVisitasInstagram = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlVisitasUsuarioInstagram,
      queryParams: {
        "ultimo_id": _ultimoVisitasInstagram
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoVisitasInstagram = datosJson['data']['ultimo_id'].toString();
        _verMasVisitasInstagram = datosJson['data']['ver_mas'];

        List<dynamic> visitasInstagram = datosJson['data']['visitas_instagram'];
        for (var element in visitasInstagram) {

          VisitaInstagramPrevisualizacionAutor? previsualizacionAutor;
          if(element['previsualizacion_autor_usuario'] != null){
            previsualizacionAutor = VisitaInstagramPrevisualizacionAutor(
              edad: element['previsualizacion_autor_usuario']['edad'].toString(),
              universidadNombre: element['previsualizacion_autor_usuario']['universidad_nombre'],
              isVerificadoUniversidad: element['previsualizacion_autor_usuario']['is_verificado_universidad'],
              verificadoUniversidadNombre: element['previsualizacion_autor_usuario']['verificado_universidad_nombre'],
            );
          }

          VisitaInstagramAutor? autor;
          if(element['autor_usuario'] != null){
            autor = VisitaInstagramAutor(
              id: element['autor_usuario']['id'],
              nombre: element['autor_usuario']['nombre'],
              nombreCompleto: element['autor_usuario']['nombre_completo'],
              username: element['autor_usuario']['username'],
              foto: constants.urlBase + element['autor_usuario']['foto_url'],
              edad: element['autor_usuario']['edad'].toString(),
              universidadNombre: element['autor_usuario']['universidad_nombre'],
              isVerificadoUniversidad: element['autor_usuario']['is_verificado_universidad'],
              verificadoUniversidadNombre: element['autor_usuario']['verificado_universidad_nombre'],
            );
          }

          _visitasInstagram.add(VisitaInstagram(
            autor: autor,
            previsualizacionAutor: previsualizacionAutor,
            fecha: element['fecha_texto'],
            isNuevo: element['visto'] == "NO",
          ));
        }

        _isUsuarioPremium = datosJson['data']['is_premium'];

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingVisitasInstagram = false;
    });
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}