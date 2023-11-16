import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/models/mensaje_sugerencia_texto.dart';
import 'package:tenfo/models/usuario_sesion.dart';
import 'package:tenfo/services/http_service.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

typedef SendMessageCallback = void Function(String text);

class MessageEntry extends StatefulWidget {
  final SendMessageCallback onSendMessageRequested;

  const MessageEntry({
    Key? key,
    required this.onSendMessageRequested,
  }) : super(key: key);

  @override
  MessageEntryState createState() => MessageEntryState();
}

class MessageEntryState extends State<MessageEntry> {
  final _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  var _sendEnabled = false;
  bool _inputEnabled = true;

  bool _showSugerencias = false;
  bool _loadingSugerenciasTexto = false;
  List<MensajeSugerenciaTexto> _mensajeSugerenciasTexto = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12, width: 0.3,)),
      ),
      child: Column(
        children: [

          if(_showSugerencias)
            ...[
              const SizedBox(height: 16,),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16,),
                width: double.infinity,
                child: const Text("Opciones:", textAlign: TextAlign.left,
                  style: TextStyle(color: constants.blackGeneral, fontSize: 12,),
                ),
              ),
              const SizedBox(height: 8,),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16,),
                alignment: Alignment.centerLeft,
                height: 70,
                child: _loadingSugerenciasTexto ? const CircularProgressIndicator() : ListView.builder(itemBuilder: (context, index){

                  return InkWell(
                    onTap: (){
                      if(_mensajeSugerenciasTexto[index].requiereCompletar){
                        _textController.text = _mensajeSugerenciasTexto[index].texto + ' ';

                        _textFocusNode.requestFocus();
                        _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
                      } else {
                        _textController.text = _mensajeSugerenciasTexto[index].texto;

                        _textFocusNode.unfocus();
                      }
                      setState(() {});
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8,),
                      decoration: BoxDecoration(
                        border: Border.all(color: constants.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(_mensajeSugerenciasTexto[index].requiereCompletar
                          ? (_mensajeSugerenciasTexto[index].texto + '...') : _mensajeSugerenciasTexto[index].texto,
                        style: const TextStyle(
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 3,
                      ),
                    ),
                  );

                }, scrollDirection: Axis.horizontal, itemCount: _mensajeSugerenciasTexto.length, shrinkWrap: true,),
              ),

              const SizedBox(height: 16,),
            ],

          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  focusNode: _textFocusNode,
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: _inputEnabled
                        ? 'Escribe un mensaje...'
                        : 'No puedes enviar mensajes a este chat',
                    hintStyle: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  minLines: 1,
                  maxLines: 6,
                  maxLength: 1000,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16,),
                  enabled: _inputEnabled,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _sendEnabled ? _sendMessage : null,
                icon: Icon(
                  Icons.send,
                  color: _sendEnabled ? constants.blueGeneral : constants.blueDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextEvents);
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _textController.addListener(_handleTextEvents);
  }

  void _handleTextEvents() {
    setState(() => _sendEnabled = _textController.text.isNotEmpty);
  }

  Future<void> _sendMessage() async {
    widget.onSendMessageRequested(_textController.text);
    _textController.text = '';

    if(_showSugerencias){
      // El delayed solo es un efecto visual. Es para no quitar rapidamente las sugerencias al enviar el mensaje.
      await Future.delayed(const Duration(seconds: 1));
      _showSugerencias = false;
      setState(() {});
    }
  }

  void userBlocked(){
    setState(() {
      _textController.text = '';
      _inputEnabled = false;
      _sendEnabled = false;
      _showSugerencias = false;
    });
  }

  void setShowSugerencias(bool value, String? chatId){
    setState(() {
      _showSugerencias = value;
    });

    if(_showSugerencias && chatId != null){
      _cargarSugerenciasTexto(chatId);
    }
  }

  Future<void> _cargarSugerenciasTexto(String chatId) async {
    setState(() {
      _loadingSugerenciasTexto = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    UsuarioSesion usuarioSesion = UsuarioSesion.fromSharedPreferences(prefs);

    var response = await HttpService.httpGet(
      url: constants.urlChatSugerencias,
      queryParams: {
        "chat_id": chatId
      },
      usuarioSesion: usuarioSesion,
    );

    if(response.statusCode == 200){
      var datosJson = await jsonDecode(response.body);

      if(datosJson['error'] == false){

        _mensajeSugerenciasTexto.clear();

        List<dynamic> mensajeSugerencias = datosJson['data']['mensaje_sugerencias_texto'];
        for (var element in mensajeSugerencias) {
          _mensajeSugerenciasTexto.add(MensajeSugerenciaTexto(
            texto: element['texto'],
            requiereCompletar: element['requiere_completar'],
          ));
        }

      } else {
        _showSnackBar("Se produjo un error inesperado");
      }
    }

    setState(() {
      _loadingSugerenciasTexto = false;
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
