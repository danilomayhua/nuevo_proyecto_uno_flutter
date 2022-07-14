import 'dart:convert';

import 'package:nuevoproyectouno/utilities/constants.dart' as constants;
import 'package:nuevoproyectouno/utilities/shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioSesion {

  String authToken;

  String id;
  String nombre_completo;
  String username;
  String foto;

  String nombre;
  String apellido;
  String email;
  String? descripcion;
  String? instagram;
  List<String> interesesId;
  bool isAdmin;

  UsuarioSesion({required this.authToken, required this.id, required this.nombre_completo,
    required this.username, required this.foto, required this.nombre, required this.apellido,
    required this.email, required this.descripcion, required this.instagram,
    required this.interesesId, required this.isAdmin});

  factory UsuarioSesion.fromJson(Map<String, dynamic> json){

    List<String> intereses = [];
    for(int i = 0; i < json['usuario']['intereses'].length; i++) {
      intereses.add(json['usuario']['intereses'][i].toString());
    }

    return UsuarioSesion(
      authToken: json['token'],
      id: json['usuario']['id'],
      nombre_completo: json['usuario']['nombre'] + ' ' + json['usuario']['apellido'],
      username: json['usuario']['username'],
      foto: constants.urlBase + json['usuario']['foto_url'],
      nombre: json['usuario']['nombre'],
      apellido: json['usuario']['apellido'],
      email: json['usuario']['email'],
      descripcion: json['usuario']['descripcion'],
      instagram: json['usuario']['instagram'],
      interesesId: intereses,
      isAdmin: json['usuario']['is_admin'],
    );
  }

  factory UsuarioSesion.fromSharedPreferences(SharedPreferences sharedPreferences){
    String? sesionJson = sharedPreferences.getString(SharedPreferencesKeys.usuarioSesion);
    return UsuarioSesion.fromJson(jsonDecode(sesionJson!));
  }

  Map<String, dynamic> toJson() => {
    'token': authToken,
    'usuario': {
      'id' : id,
      'nombre': nombre,
      'apellido': apellido,
      'username': username,
      'foto_url': foto.substring(constants.urlBase.length), // Elimina urlBase agregado al principio
      'email': email,
      'descripcion': descripcion,
      'instagram': instagram,
      'intereses': interesesId,
      'is_admin': isAdmin,
    },
  };
}