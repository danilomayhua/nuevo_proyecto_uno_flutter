import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

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

  static Map<String, String> _getHeadersMultipart({UsuarioSesion? usuarioSesion}){
    Map<String, String> headers;

    if(usuarioSesion != null){
      headers = {
        'Content-Type': 'multipart/form-data',
        'Authorization': 'Bearer ${usuarioSesion.authToken}',
      };
    } else {
      headers = {
        'Content-Type': 'multipart/form-data',
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

  static Future<http.Response> httpMultipart({required String url, required String field, required File file, UsuarioSesion? usuarioSesion}) async {

    http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse(_urlBase + url));

    request.headers.addAll(_getHeadersMultipart(usuarioSesion: usuarioSesion));

    String? mimeType = lookupMimeType(file.path);

    if(mimeType != null && ['image/jpeg','image/jpg','image/png'].contains(mimeType)){
      http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
        field,
        file.path,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);
    }

    var response = await request.send();
    http.Response responseString = await http.Response.fromStream(response);

    return responseString;
  }

}