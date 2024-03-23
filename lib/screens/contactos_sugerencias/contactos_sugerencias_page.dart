import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/screens/user/user_page.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/utilities/historial_usuario.dart';
import 'package:tenfo/utilities/share_utils.dart';

class ContactosSugerenciasPage extends StatefulWidget {
  const ContactosSugerenciasPage({Key? key}) : super(key: key);

  @override
  State<ContactosSugerenciasPage> createState() => _ContactosSugerenciasPageState();
}

class _ContactosSugerenciasPageState extends State<ContactosSugerenciasPage> {

  bool _isPermisoTelefonoContactos = false;

  List<Contact> _telefonoContactos = [];
  List<Contact> _filteredTelefonoContactos = [];

  List<Usuario> _sugerencias = [];

  bool _loadingContactosSugerencias = false;

  @override
  void initState() {
    super.initState();

    _cargarTelefonoContactos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar amigos"),
      ),
      body: (_loadingContactosSugerencias || !_isPermisoTelefonoContactos) ? Center(

        child: _loadingContactosSugerencias ? const CircularProgressIndicator() : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [

            const SizedBox(height: 16,),
            const Icon(Icons.contacts_outlined, size: 40, color: constants.grey,),
            const SizedBox(height: 24,),
            Text(Platform.isIOS
                ? "Permite los contactos para poder sugerirte amigos y cocrear actividades fácilmente."
                : "Tenfo requiere acceso a la lista de contactos para poder sugerirte amigos. "
                "Esto se envía a nuestros servidores para mostrarte las sugerencias de posibles amigos. No lo compartimos con terceros.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24,),
            Container(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 40,),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _habilitarTelefonoContactos(),
                child: const Text('Aceptar'),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
              ),
            ),
            const SizedBox(height: 16,),

          ], mainAxisSize: MainAxisSize.min,),
        ),

      ) : ListView.builder(
        itemCount: _sugerencias.length + 1 + _filteredTelefonoContactos.length + 1, // 2 listas y 2 texto cabecera
        itemBuilder: (context, index){
          if(index == 0){
            return _buildCabeceraSugerencias();
          }

          if (index < _sugerencias.length + 1) {
            return _buildUsuario(_sugerencias[index - 1]);
          }

          if (index == _sugerencias.length + 1) {
            return _buildCabeceraTelefonoContactos();
          }

          return _buildTelefonoContacto(_filteredTelefonoContactos[index - _sugerencias.length - 2]);
        },
      ),
    );
  }

  Widget _buildCabeceraSugerencias(){
    return Column(children: [
      Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
        child: const Text("Sugerencias",
          style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
        ),
      ),

      if(_sugerencias.isEmpty)
        ...[
          const SizedBox(height: 48,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16,),
            child: const Text("No hay sugerencias para mostrar",
              style: TextStyle(color: constants.blackGeneral, fontSize: 14,
                height: 1.3, fontWeight: FontWeight.bold,),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24,),
        ],
    ],);
  }

  Widget _buildCabeceraTelefonoContactos(){
    return Column(children: [
      const SizedBox(height: 24,),
      const Divider(color: constants.greyLight, height: 0.5,),
      const SizedBox(height: 24,),

      Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 12,),
        child: const Text("Invitar amigos",
          style: TextStyle(color: constants.blackGeneral, fontSize: 16,),
        ),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        child: TextField(
          decoration: const InputDecoration(
            isDense: true,
            hintText: "Buscar...",
            counterText: '',
            border: OutlineInputBorder(),
          ),
          maxLength: 200,
          minLines: 1,
          maxLines: 1,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14,),
          onChanged: (text){
            setState(() {
              _filteredTelefonoContactos = _telefonoContactos
                  .where((contact) => contact.displayName.toLowerCase().contains(text.toLowerCase()))
                  .toList();
            });
          },
        ),
      ),

      const SizedBox(height: 16,),

      if(_filteredTelefonoContactos.isEmpty)...[
        const SizedBox(height: 48,),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16,),
          child: const Text("No hay resultados encontrados",
            style: TextStyle(color: constants.blackGeneral, fontSize: 14,
              height: 1.3, fontWeight: FontWeight.bold,),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48,),
      ],
    ],);
  }

  Widget _buildUsuario(Usuario usuario){
    return ListTile(
      title: Text(usuario.nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(usuario.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        backgroundImage: CachedNetworkImageProvider(usuario.foto),
      ),
      onTap: (){
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UserPage(usuario: usuario,)),
        );
      },
    );
  }

  Widget _buildTelefonoContacto(Contact contact){
    Phone? phone = contact.phones.isNotEmpty ? contact.phones.first : null;
    String primeraLetra = contact.displayName.substring(0, 1).toUpperCase();

    return ListTile(
      title: Text(contact.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: constants.greyBackgroundImage,
        child: Text(primeraLetra,
          style: const TextStyle(color: constants.blackGeneral, fontSize: 18, fontWeight: FontWeight.bold,),
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () async {
          // Envia historial del usuario
          _enviarHistorialUsuario(HistorialUsuario.getContactosSugerenciasInvitarAmigo(phone?.number ?? ""));


          // Elimina cualquier caracter que no sea un digito del numero
          String? cleanedPhoneNumber = phone?.number.replaceAll(RegExp(r'[^\d]'), '');

          ShareUtils.shareProfileWhatsappNumber(cleanedPhoneNumber ?? "");
        },
        child: const Text("Invitar", style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8,),
        ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0),),
      ),
    );
  }

  Future<void> _habilitarTelefonoContactos() async {
    bool permisoTelefonoContactos = false;

    try {

      permisoTelefonoContactos = await FlutterContacts.requestPermission();

    } catch(e){
      // Captura error, por si surge algun posible error con el paquete
    }

    if(!permisoTelefonoContactos){
      _showSnackBar("Los permisos están denegados. Permite los contactos desde Ajustes en la app.");
      return;
    }

    _isPermisoTelefonoContactos = true;
    _cargarTelefonoContactos();
  }

  Future<void> _cargarTelefonoContactos() async {
    _loadingContactosSugerencias = true;
    setState(() {});


    _isPermisoTelefonoContactos = true;

    final PermissionStatus permissionStatus = await Permission.contacts.status;
    if(!permissionStatus.isGranted){
      _isPermisoTelefonoContactos = false;

      _loadingContactosSugerencias = false;
      setState(() {});
      return;
    }


    _telefonoContactos = await FlutterContacts.getContacts(withProperties: true,);
    _filteredTelefonoContactos = _telefonoContactos;


    // Si no tiene contactos, muestra el mensaje de que no hay sugerencias
    if(_telefonoContactos.isEmpty){
      _loadingContactosSugerencias = false;
      setState(() {});

      return;
    }


    List<String> listaTelefonosE164 = [];

    for (var element in _telefonoContactos) {
      Phone? phone = element.phones.isNotEmpty ? element.phones.first : null;

      try {
        // TODO : se demora segundos en formatear todos los numeros (ver como mejorar)

        // De momento solo permite registros en Argentina, asi que por defecto la region es "AR"
        PhoneNumber parsedPhoneNumber = await PhoneNumber.getRegionInfoFromPhoneNumber(phone?.number ?? "", 'AR');

        String? telefonoE164 = parsedPhoneNumber.phoneNumber; // Devuelve en formato E.164, transforma el "15" a "9"

        if(telefonoE164 != null){
          if (telefonoE164.startsWith("+54")) {
            if (!telefonoE164.startsWith("+549")) {
              telefonoE164 = telefonoE164.replaceFirst("+54", "+549");
            }
          }

          listaTelefonosE164.add(telefonoE164);
        }

      } catch (e) {
        // Error al formatear numero
      }
    }

    _cargarSugerencias(listaTelefonosE164);
  }

  Future<void> _cargarSugerencias(List<String> telefonoContactosNumero) async {
    setState(() {
      _loadingContactosSugerencias = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlSugerenciasTelefonoContactos,
      body: {
        "telefono_contactos_numero": telefonoContactosNumero
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        List<dynamic> sugerencias = datosJson['data']['sugerencias'];
        for (var element in sugerencias) {
          _sugerencias.add(Usuario(
            id: element['id'],
            nombre: element['nombre_completo'],
            username: element['username'],
            foto: constants.urlBase + element['foto_url'],
          ));
        }

        // TODO : eliminar los usuarios de sugerencias en _telefonoContactos

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingContactosSugerencias = false;
    });
  }

  Future<void> _enviarHistorialUsuario(Map<String, dynamic> historialUsuario) async {
    //setState(() {});

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpPost(
      url: constants.urlCrearHistorialUsuarioActivo,
      body: {
        "historiales_usuario_activo": [historialUsuario],
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){
        //
      } else {
        //_showSnackBar("Se produjo un error inesperado");
      }
    }

    //setState(() {});
  }

  void _showSnackBar(String texto){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(texto, textAlign: TextAlign.center,)
    ));
  }
}