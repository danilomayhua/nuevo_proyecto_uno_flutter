import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/contactos/contactos_page.dart';
import 'package:tenfo/screens/principal/views/home_page.dart';
import 'package:tenfo/screens/principal/views/mensajes_page.dart';
import 'package:tenfo/screens/principal/views/perfil_page.dart';
import 'package:tenfo/screens/seleccionar_crear_tipo/seleccionar_crear_tipo_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/widgets/dialog_cambiar_intereses.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({Key? key, this.principalPageView = PrincipalPageView.home, this.isFromSignup = false}) : super(key: key);

  final PrincipalPageView principalPageView;
  final bool isFromSignup;

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

enum PrincipalPageView {
  home,
  contactos,
  mensajes,
  perfil
}

class _PrincipalPageState extends State<PrincipalPage> {
  int _currentIndex = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  bool _showBadgeMensajes = false;

  final GlobalKey<HomePageState> _keyHomePage = GlobalKey();
  bool _showBadgeHome = false;
  bool _showBadgeNotificaciones = false;

  void _cargarPantalla() {
    switch(widget.principalPageView){
      case PrincipalPageView.home:
        _currentIndex = 0;
        break;
      case PrincipalPageView.contactos:
        _currentIndex = 1;
        break;
      case PrincipalPageView.mensajes:
        _currentIndex = 3;
        break;
      case PrincipalPageView.perfil:
        _currentIndex = 4;
        break;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _cargarPantalla();

    _cargarNumeroPendientesNotificacionesAvisos();

    if(widget.isFromSignup){
      // Actualmente va a Inicio desde el registro, no hay que mostrar el dialog
      //_cargarInteresesUsuarioNuevo();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> getPages(){
      return [
        HomePage(
          key: _keyHomePage,
          showBadgeNotificaciones: _showBadgeNotificaciones,
          setShowBadge: (value){
            _showBadgeHome = value;
            _showBadgeNotificaciones = value;
            setState(() {});
          },
        ),
        ContactosPage(),
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
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: Badge(
                child: const Icon(Icons.home),
                showBadge: _showBadgeHome,
                badgeColor: constants.blueGeneral,
                padding: const EdgeInsets.all(6),
                position: BadgePosition.topEnd(end: -8,),
              ),
            ),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 1 ? Colors.black12 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: const Icon(Icons.people_alt_outlined),
            ),
            label: "Amigos",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 2 ? Colors.black12 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: const Icon(Icons.add_circle_outline),
            ),
            label: "Nuevo",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 3 ? Colors.black12 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: Badge(
                child: const Icon(Icons.near_me),
                showBadge: _showBadgeMensajes,
                badgeColor: constants.blueGeneral,
                padding: const EdgeInsets.all(6),
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
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: const Icon(Icons.person),
            ),
            label: "Perfil",
          ),
        ],
        onTap: (index){
          if(index == 2){
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const SeleccionarCrearTipoPage(),
            ));
          } else {

            if(index == 0){
              _showBadgeHome = false;
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

  Future<void> _cargarInteresesUsuarioNuevo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    if(usuarioSesion.interesesId.isEmpty){
      showDialog(context: context, builder: (context) {
        return DialogCambiarIntereses(intereses: const [], onChanged: (nuevosIntereses){
          Navigator.of(context).pop();
          //_recargarActividades();
        },);
      });
    }
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
          _showBadgeHome = true;

          _showBadgeNotificaciones = true;
          if(_keyHomePage.currentState != null){
            _keyHomePage.currentState!.setShowBadgeNotificaciones(true);
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