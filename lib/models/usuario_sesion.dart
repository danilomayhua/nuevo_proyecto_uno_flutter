import 'dart:convert';

import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:tenfo/utilities/shared_preferences_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioSesion {

  String authToken;

  String id;
  String nombre_completo;
  String username;
  String foto;

  String nombre;
  String apellido;
  String? email;
  String? email_secundario; // email_secundario se guarda por primera vez cuando ingresa a Perfil
  String? telefono_numero;
  DateTime nacimiento_fecha;
  String? universidad_id;
  String? universidad_nombre; // universidad_nombre se guarda por primera vez cuando ingresa a Perfil
  String? descripcion;
  String? instagram;
  List<String> interesesId;
  bool isAdmin;
  bool isUsuarioSinFoto;

  UsuarioSesion({required this.authToken, required this.id, required this.nombre_completo,
    required this.username, required this.foto, required this.nombre, required this.apellido,
    required this.email, this.email_secundario, required this.telefono_numero, required this.nacimiento_fecha,
    required this.universidad_id, this.universidad_nombre,
    required this.descripcion, required this.instagram,
    required this.interesesId, required this.isAdmin, required this.isUsuarioSinFoto});

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
      email_secundario: json['usuario']['email_secundario'],
      telefono_numero: json['usuario']['telefono_numero'],
      // 'isUtc' Necesario para que no muestre en dia local (en local podria mostrar un dia antes del nacimiento)
      nacimiento_fecha: DateTime.fromMillisecondsSinceEpoch(json['usuario']['nacimiento_fecha'], isUtc: true,),
      universidad_id: json['usuario']['universidad_id']?.toString(),
      universidad_nombre: json['usuario']['universidad_nombre'],
      descripcion: json['usuario']['descripcion'],
      instagram: json['usuario']['instagram'],
      interesesId: intereses,
      isAdmin: json['usuario']['is_admin'],
      // isUsuarioSinFoto no existia antes, asi que en usuarios viejos puede ser null la primera vez
      isUsuarioSinFoto: json['usuario']['is_usuario_sin_foto'] ?? false,
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
      'email_secundario': email_secundario,
      'telefono_numero': telefono_numero,
      'nacimiento_fecha': nacimiento_fecha.millisecondsSinceEpoch,
      'universidad_id': universidad_id,
      'universidad_nombre': universidad_nombre,
      'descripcion': descripcion,
      'instagram': instagram,
      'intereses': interesesId,
      'is_admin': isAdmin,
      'is_usuario_sin_foto': isUsuarioSinFoto,
    },
  };
}