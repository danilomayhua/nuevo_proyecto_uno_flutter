import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/screens/crear_actividad/crear_actividad_page.dart';
import 'package:nuevoproyectouno/screens/principal/views/home_page.dart';
import 'package:nuevoproyectouno/screens/principal/views/mensajes_page.dart';
import 'package:nuevoproyectouno/screens/principal/views/mis_actividades_page.dart';
import 'package:nuevoproyectouno/screens/principal/views/perfil_page.dart';
import 'package:nuevoproyectouno/services/http_service.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({Key? key}) : super(key: key);

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  int _currentIndex = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  bool _showBadgeMisActividades = false;
  bool _showBadgeMensajes = false;
  final GlobalKey<MisActividadesPageState> _keyMisActividadesPage = GlobalKey();
  bool _showBadgeNotificaciones = false;

  /*_cargarPantalla() {
    if(widget.screenSelect == PantallasHome.Temas){

      setState(() {
        currentScreen = HomePage(key: _keyHome, showBadge: _showBadgeHome, updateBadge: _updateBadge);
      });

    } else if(widget.screenSelect == PantallasHome.Posts){

      setState(() {
        currentScreen = PostsPage();
      });

    } else if(widget.screenSelect == PantallasHome.Notificaciones){

      setState(() {
        currentScreen = NotificationsPage();
      });

    } else if(widget.screenSelect == PantallasHome.Perfil){

      //SharedPreferences prefs = await SharedPreferences.getInstance();
      //String usuarioId = prefs.getString('usuario_id');
      setState(() {
        currentScreen = UserPage(usuario_id: usuarioId, is_profile: true);
      });

    }
  }*/

  @override
  void initState() {
    super.initState();

    _cargarNumeroPendientesNotificacionesAvisos();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> getPages(){
      return [
        HomePage(),
        MisActividadesPage(
          key: _keyMisActividadesPage,
          showBadgeNotificaciones: _showBadgeNotificaciones,
          setShowBadge: (value){
            _showBadgeMisActividades = value;
            _showBadgeNotificaciones = value;
            setState(() {});
          },
        ),
        Container(),
        MensajesPage(),
        PerfilPage(),
      ];
    }

    return Scaffold(
      body: PageStorage(
        child: getPages()[_currentIndex],
        bucket: _bucket,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 0 ? Colors.black12 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: Icon(Icons.home),
            ),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 1 ? Colors.black12 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: Badge(
                child: Icon(Icons.library_books),
                showBadge: _showBadgeMisActividades,
                badgeColor: constants.blueGeneral,
                padding: EdgeInsets.all(6),
                position: BadgePosition.topEnd(end: -8,),
              ),
              //child: Icon(Icons.library_books),
            ),
            label: "Mis activ.",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 2 ? Colors.black12 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: Icon(Icons.add_circle_outline),
            ),
            label: "Crear",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 3 ? Colors.black12 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: Badge(
                child: Icon(Icons.near_me),
                showBadge: _showBadgeMensajes,
                badgeColor: constants.blueGeneral,
                padding: EdgeInsets.all(6),
                position: BadgePosition.topEnd(end: -8,),
              ),
            ),
            label: "Mensajes",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 4 ? Colors.black12 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: Icon(Icons.person),
            ),
            label: "Perfil",
          ),
        ],
        onTap: (index){
          if(index == 2){
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => CrearActividadPage(),
            ));
          } else {

            if(index == 1){
              _showBadgeMisActividades = false;
            } else if(index == 3){
              _showBadgeMensajes = false;
            }

            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        selectedItemColor: Colors.black54,
        unselectedItemColor: Colors.black45,
        elevation: 4,
      ),
    );
  }

  Future<void> _cargarNumeroPendientesNotificacionesAvisos() async {
    //setState(() {});

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlNumeroPendientesNotificacionesAvisos,
      queryParams: {},
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        int numeroNotificaciones = datosJson['data']['numero_notificaciones'];
        int numeroChats = datosJson['data']['numero_chats'];

        if(numeroNotificaciones > 0){
          _showBadgeMisActividades = true;

          _showBadgeNotificaciones = true;
          if(_keyMisActividadesPage.currentState != null){
            _keyMisActividadesPage.currentState!.setShowBadgeNotificaciones(true);
          }
        }

        if(numeroChats > 0){
          _showBadgeMensajes = true;
        }

      } else {
        //_showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {});
  }
}