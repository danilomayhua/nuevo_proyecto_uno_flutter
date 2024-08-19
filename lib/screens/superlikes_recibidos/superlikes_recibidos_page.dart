import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/superlike_recibido.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/widgets/dialogbottom_comprar_premium.dart';

class SuperlikesRecibidosPage extends StatefulWidget {
  const SuperlikesRecibidosPage({Key? key}) : super(key: key);

  @override
  State<SuperlikesRecibidosPage> createState() => _SuperlikesRecibidosPageState();
}

class _SuperlikesRecibidosPageState extends State<SuperlikesRecibidosPage> {

  bool? _isUsuarioPremium;

  List<SuperlikeRecibido> _superlikesRecibidos = [];

  final ScrollController _scrollController = ScrollController();
  bool _loadingSuperlikes = false;
  bool _verMasSuperlikes = false;
  String _ultimoSuperlikes = "false";

  @override
  void initState() {
    super.initState();

    _cargarSuperlikesRecibidos();

    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
        if(!_loadingSuperlikes && _verMasSuperlikes){
          _cargarSuperlikesRecibidos();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Incentivos recibidos"),
        actions: [],
      ),
      body: (_superlikesRecibidos.isEmpty) ? Center(

        child: _loadingSuperlikes ? const CircularProgressIndicator() : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: const [
            Text("No tienes incentivos recibidos aún.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8,),
            Text("Crea una actividad o únete a las actividades disponibles para conectar con nuevas personas.",
              style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
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
      itemCount: _superlikesRecibidos.length + 1, // +1 mostrar cargando
      itemBuilder: (context, index){
        if(index == _superlikesRecibidos.length){
          return _buildLoadingSuperlikes();
        }

        return _buildSuperlikeRecibido(_superlikesRecibidos[index]);
      },
    );
  }

  Widget _buildBodyUsuarioNoPremium(){
    return Stack(children: [
      ListView.builder(
        controller: _scrollController,
        itemCount: _superlikesRecibidos.length + 1, // +1 mostrar cargando
        itemBuilder: (context, index){
          if(index == _superlikesRecibidos.length){
            return _buildLoadingSuperlikes();
          }

          return _buildSuperlikeRecibido(_superlikesRecibidos[index]);
        },
      ),
      Positioned(
        bottom: 24,
        left: 24,
        right: 24,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, minHeight: 48,),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showDialogComprarPremium(),
            child: const Text("¿Quién envió esto? 👀"),
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
          ),
        ),
      ),
    ],);
  }

  Widget _buildSuperlikeRecibido(SuperlikeRecibido superlikeRecibido){
    if(superlikeRecibido.autor != null){
      return ListTile(
        title: Text("${superlikeRecibido.autor!.nombreCompleto} quiere que hagas una actividad.",
          style: TextStyle(
            fontSize: 14,
            color: constants.blackGeneral,
            fontWeight: superlikeRecibido.isNuevo ? FontWeight.bold : null,
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundColor: constants.greyBackgroundImage,
          backgroundImage: CachedNetworkImageProvider(superlikeRecibido.autor!.foto),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            margin: const EdgeInsets.only(left: 24, top: 24,),
            child: const Icon(CupertinoIcons.heart_circle_fill, color: Colors.lightGreen, size: 16,),
          ),
        ),
        trailing: Text(superlikeRecibido.fecha,
          style: const TextStyle(fontSize: 10, color: constants.grey,),
        ),
        onTap: (){
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => UserPage(usuario: superlikeRecibido.autor!.toUsuario(),)),
          );
        },
        tileColor: superlikeRecibido.isNuevo ? constants.greenLightBackground : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16,),
      );
    }

    String? universidadNombre = superlikeRecibido.previsualizacionAutor!.universidadNombre;

    return ListTile(
      title: Text("Un/a estudiante ${universidadNombre == null ? "" : "de la "+universidadNombre+" "}(${superlikeRecibido.previsualizacionAutor!.edad} años) "
          "quiere que hagas una actividad.",
        style: TextStyle(
          fontSize: 14,
          color: constants.blackGeneral,
          fontWeight: superlikeRecibido.isNuevo ? FontWeight.bold : null,
        ),
      ),
      leading: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          //border: Border.all(color: constants.greyLight, width: 0.5,),
        ),
        height: 40,
        width: 40,
        alignment: Alignment.center,
        child: const Icon(CupertinoIcons.heart_circle_fill, color: Colors.lightGreen, size: 40,),
      ),
      trailing: Text(superlikeRecibido.fecha,
        style: const TextStyle(fontSize: 10, color: constants.grey,),
      ),
      onTap: () => _showDialogComprarPremium(),
      tileColor: superlikeRecibido.isNuevo ? constants.greenLightBackground : Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16,),
    );
  }

  Widget _buildLoadingSuperlikes(){
    if(_loadingSuperlikes){
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
          titulo: "¿Quién envió esto?",
          onCompraExitosa: (){
            if(!isClosed){
              // Nunca entraria aqui, porque si cierra el dialog, no puede procesar los eventos de la compra
              Navigator.pop(context);
            }

            _recargarSuperlikesRecibidos();
          },
          onCompraError: (errorMensaje){
            if(!isClosed){
              // Nunca entraria aqui, porque si cierra el dialog, no puede procesar los eventos de la compra
              Navigator.pop(context);
            }
            _showSnackBar(errorMensaje);
          },
          fromPantalla: ComprarPremiumFromPantalla.superlikes_recibidos,
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

  void _recargarSuperlikesRecibidos(){
    _loadingSuperlikes = true;
    _verMasSuperlikes = false;
    _ultimoSuperlikes = "false";

    _superlikesRecibidos = [];

    _cargarSuperlikesRecibidos();
  }

  Future<void> _cargarSuperlikesRecibidos() async {
    setState(() {
      _loadingSuperlikes = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlSuperlikesRecibidos,
      queryParams: {
        "ultimo_id": _ultimoSuperlikes
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _ultimoSuperlikes = datosJson['data']['ultimo_id'].toString();
        _verMasSuperlikes = datosJson['data']['ver_mas'];

        List<dynamic> superlikes = datosJson['data']['superlikes_recibidos'];
        for (var element in superlikes) {

          SuperlikeRecibidoPrevisualizacionAutor? previsualizacionAutor;
          if(element['previsualizacion_autor_usuario'] != null){
            previsualizacionAutor = SuperlikeRecibidoPrevisualizacionAutor(
              edad: element['previsualizacion_autor_usuario']['edad'].toString(),
              universidadNombre: element['previsualizacion_autor_usuario']['universidad_nombre'],
              isVerificadoUniversidad: element['previsualizacion_autor_usuario']['is_verificado_universidad'],
              verificadoUniversidadNombre: element['previsualizacion_autor_usuario']['verificado_universidad_nombre'],
            );
          }

          SuperlikeRecibidoAutor? autor;
          if(element['autor_usuario'] != null){
            autor = SuperlikeRecibidoAutor(
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

          _superlikesRecibidos.add(SuperlikeRecibido(
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
      _loadingSuperlikes = false;
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