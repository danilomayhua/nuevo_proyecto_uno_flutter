import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

    // Agrega campos sobre la app actual (no sobrescribir si ya existen campos con el mismo nombre)
    try {
      if(queryParams["app_plataforma"] == null){
        String appPlataforma = Platform.isIOS ? "iOS" : "android";
        queryParams["app_plataforma"] = appPlataforma;
      }
      if(queryParams["app_version"] == null){
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        queryParams["app_version"] = packageInfo.version;
      }
    } catch (e){
      //
    }

    http.Response response = await http.get(
      Uri.parse(_urlBase + url).replace(queryParameters: queryParams,),
      headers: _getHeaders(usuarioSesion: usuarioSesion),
    );

    return response;
  }

  static Future<http.Response> httpPost({required String url, required Map<String, dynamic> body, UsuarioSesion? usuarioSesion}) async {

    // Agrega campos sobre la app actual (no sobrescribir si ya existen campos con el mismo nombre)
    try {
      if(body["app_plataforma"] == null){
        String appPlataforma = Platform.isIOS ? "iOS" : "android";
        body["app_plataforma"] = appPlataforma;
      }
      if(body["app_version"] == null){
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        body["app_version"] = packageInfo.version;
      }
    } catch (e){
      //
    }

    http.Response response = await http.post(
      Uri.parse(_urlBase + url),
      headers: _getHeaders(usuarioSesion: usuarioSesion),
      body: jsonEncode(body),
    );

    return response;
  }

  static Future<http.Response> httpMultipart({required String url, required String field, required File file, UsuarioSesion? usuarioSesion, Map<String, String>? additionalFields}) async {

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

    if(additionalFields != null){
      request.fields.addAll(additionalFields);
    }

    // Agrega campos sobre la app actual (no sobrescribir si ya existen campos con el mismo nombre)
    try {
      if(request.fields["app_plataforma"] == null){
        String appPlataforma = Platform.isIOS ? "iOS" : "android";
        request.fields["app_plataforma"] = appPlataforma;
      }
      if(request.fields["app_version"] == null){
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        request.fields["app_version"] = packageInfo.version;
      }
    } catch (e){
      //
    }

    var response = await request.send();
    http.Response responseString = await http.Response.fromStream(response);

    return responseString;
  }

  static Future<http.Response> httpGetExterno({required String url, required Map<String, String> queryParams}) async {

    http.Response response = await http.get(
      Uri.parse(url).replace(queryParameters: queryParams,),
      headers: _getHeaders(),
    );

    return response;
  }

}