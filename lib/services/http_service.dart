import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nuevoproyectouno/models/usuario_sesion.dart';
import 'package:nuevoproyectouno/utilities/constants.dart' as constants;

class HttpService {

  static const String _urlBase = constants.urlBase;

  static Map<String, String> _getHeaders({UsuarioSesion? usuarioSesion}){
    Map<String, String> headers;

    if(usuarioSesion != null){
      headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${usuarioSesion.authToken}',
      };
    } else {
      headers = {
        'Content-Type': 'application/json',
      };
    }

    return headers;
  }

  static Future<http.Response> httpGet({required String url, required Map<String, String> queryParams, UsuarioSesion? usuarioSesion}) async {

    http.Response response = await http.get(
      Uri.parse(_urlBase + url).replace(queryParameters: queryParams,),
      headers: _getHeaders(usuarioSesion: usuarioSesion),
    );

    return response;
  }

  static Future<http.Response> httpPost({required String url, required Map<String, dynamic> body, UsuarioSesion? usuarioSesion}) async {

    http.Response response = await http.post(
      Uri.parse(_urlBase + url),
      headers: _getHeaders(usuarioSesion: usuarioSesion),
      body: jsonEncode(body),
    );

    return response;
  }

}