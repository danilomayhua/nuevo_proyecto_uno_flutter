import 'package:flutter/material.dart';
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

  var _sendEnabled = false;
  bool _inputEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
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

  void _sendMessage() {
    widget.onSendMessageRequested(_textController.text);
    _textController.text = '';
  }

  void userBlocked(){
    setState(() {
      _textController.text = '';
      _inputEnabled = false;
      _sendEnabled = false;
    });
  }
}
