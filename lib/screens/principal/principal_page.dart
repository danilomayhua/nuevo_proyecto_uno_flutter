import 'package:flutter/material.dart';
import 'package:nuevoproyectouno/screens/crear_actividad/crear_actividad_page.dart';
import 'package:nuevoproyectouno/screens/principal/views/home_page.dart';
import 'package:nuevoproyectouno/screens/principal/views/mensajes_page.dart';
import 'package:nuevoproyectouno/screens/principal/views/mis_actividades_page.dart';
import 'package:nuevoproyectouno/screens/principal/views/perfil_page.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({Key? key}) : super(key: key);

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  int _currentIndex = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

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
  List<Widget> pages = [ //Comprobar si no son llamados la primera vez todos
    HomePage(),
    MisActividadesPage(),
    Container(),
    MensajesPage(),
    PerfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        child: pages[_currentIndex],
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
              child: Icon(Icons.library_books),
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
              child: Icon(Icons.near_me),
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
}