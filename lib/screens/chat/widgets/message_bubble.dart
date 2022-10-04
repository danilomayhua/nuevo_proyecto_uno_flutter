import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/models/mensaje.dart';
import 'package:tenfo/models/usuario.dart';
import 'package:tenfo/utilities/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';

enum _Corner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

typedef ProfileRequestCallback = void Function(Usuario usuario);

class MessageBubble extends StatefulWidget {
  final bool isGroup;
  final Mensaje message;
  final Mensaje? nextMessage;
  final Mensaje? previousMessage;
  final ProfileRequestCallback onProfileRequested;
  final RegExp regExUrl = RegExp(r'(?:https?://)?(?:www\.)?[a-zA-Z0-9@:%._+~#=]+\.[a-z]{2,6}\b(?:\.?[-a-zA-Z0-9@:%_+~#=?&/])*');

  MessageBubble({
    Key? key,
    this.isGroup = false,
    required this.message,
    required this.nextMessage,
    required this.previousMessage,
    required this.onProfileRequested,
  }) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {

  bool _showDate = false;
  bool _showStickerAnimated = true;

  @override
  Widget build(BuildContext context) {
    var paddingTop = widget.nextMessage != null ? 0.0 : 8.0;
    var paddingBottom = widget.previousMessage != null
        ? widget.message.autorUsuario.id == widget.previousMessage!.autorUsuario.id
        ? 4.0
        : 8.0
        : 8.0;

    if ([MensajeTipo.GRUPO_INGRESO, MensajeTipo.GRUPO_SALIDA, MensajeTipo.GRUPO_ELIMINAR_USUARIO,
      MensajeTipo.GRUPO_ENCUENTRO_FECHA, MensajeTipo.GRUPO_ENCUENTRO_LINK].contains(widget.message.tipo)) {
      return Center(
        child: Container(
          child: RichText(
            text: TextSpan(
              children: [
                if (widget.message.isEntrante)
                  TextSpan(
                    recognizer: TapGestureRecognizer()..onTap = () => widget.onProfileRequested(widget.message.autorUsuario),
                    style: TextStyle(
                      color: constants.usernameColors[widget.message.autorUsuario.username.hashCode % constants.usernameColors.length],
                      fontWeight: FontWeight.w600,
                    ),
                    text: widget.message.autorUsuario.username,
                  ),
                TextSpan(
                  text: widget.message.tipo == MensajeTipo.GRUPO_INGRESO
                      ? widget.message.isEntrante
                        ? ' se unió al grupo'
                        : 'Te has unido al grupo'
                    : widget.message.tipo == MensajeTipo.GRUPO_SALIDA
                      ? widget.message.isEntrante
                        ? ' salió del grupo'
                        : 'Saliste del grupo'
                    : widget.message.tipo == MensajeTipo.GRUPO_ELIMINAR_USUARIO
                      ? widget.message.isEntrante
                      ? ' eliminó a '
                      : 'Eliminaste a '
                    : widget.message.tipo == MensajeTipo.GRUPO_ENCUENTRO_FECHA
                      ? widget.message.isEntrante
                        ? ' estableció fecha de encuentro. ${Mensaje.grupoEncuentroFechaToText(widget.message.grupoEncuentroFecha!)}.'
                        : 'Estableciste fecha de encuentro. ${Mensaje.grupoEncuentroFechaToText(widget.message.grupoEncuentroFecha!)}.'
                    : widget.message.isEntrante
                      ? ' estableció un link de encuentro. Ver en Info de grupo.'
                      : 'Estableciste un link de encuentro. Ver en Info de grupo.',
                  style: const TextStyle(
                    color: constants.grey,
                  ),
                ),
                if (widget.message.tipo == MensajeTipo.GRUPO_ELIMINAR_USUARIO)
                  TextSpan(
                    recognizer: TapGestureRecognizer()..onTap = () => widget.onProfileRequested(widget.message.grupoEliminadoUsuario!),
                    style: TextStyle(
                      color: constants.usernameColors[widget.message.grupoEliminadoUsuario!.username.hashCode % constants.usernameColors.length],
                      fontWeight: FontWeight.w600,
                    ),
                    text: widget.message.grupoEliminadoUsuario!.username,
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          margin: EdgeInsets.fromLTRB(8, paddingTop, 8, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }

    var tlRadius = _shouldRound(_Corner.topLeft, widget.message, widget.nextMessage) ? 10.0 : 4.0;
    var trRadius = _shouldRound(_Corner.topRight, widget.message, widget.nextMessage) ? 10.0 : 4.0;
    var blRadius = _shouldRound(_Corner.bottomLeft, widget.message, widget.previousMessage) ? 10.0 : 4.0;
    var brRadius = _shouldRound(_Corner.bottomRight, widget.message, widget.previousMessage) ? 10.0 : 4.0;

    return Container(
      child: Column(children: [
        if (_showDate)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(widget.message.fecha, style: const TextStyle(color: constants.grey, fontSize: 12),),
          ),
        Row(
          children: [
            if (widget.message.isEntrante && widget.isGroup)
              Container(
                child: widget.previousMessage == null || widget.previousMessage!.tipo != null &&
                    [MensajeTipo.GRUPO_INGRESO, MensajeTipo.GRUPO_SALIDA, MensajeTipo.GRUPO_ELIMINAR_USUARIO,
                      MensajeTipo.GRUPO_ENCUENTRO_FECHA, MensajeTipo.GRUPO_ENCUENTRO_LINK].contains(widget.previousMessage!.tipo) ||
                    widget.previousMessage!.autorUsuario.id != widget.message.autorUsuario.id
                    ? InkWell(
                      child: CircleAvatar(
                        backgroundColor: Colors.black12,
                        backgroundImage: NetworkImage(widget.message.autorUsuario.foto),
                      maxRadius: 16,
                      ),
                      onTap: () => widget.onProfileRequested(widget.message.autorUsuario),
                    ) : null,
                height: 32,
                margin: const EdgeInsets.only(right: 4),
                width: 32,
              ),
            Flexible(
              child: GestureDetector(
                onTap: () => {
                  setState(() => {_showDate = !_showDate})
                },
                child: Container(
                  child: Column(
                    children: [
                      if (widget.message.isEntrante &&
                          widget.isGroup &&
                          (widget.nextMessage == null ||
                              widget.nextMessage!.tipo != null &&
                                  [MensajeTipo.GRUPO_INGRESO, MensajeTipo.GRUPO_SALIDA, MensajeTipo.GRUPO_ELIMINAR_USUARIO,
                                    MensajeTipo.GRUPO_ENCUENTRO_FECHA, MensajeTipo.GRUPO_ENCUENTRO_LINK].contains(widget.nextMessage!.tipo) ||
                              widget.nextMessage!.autorUsuario.id != widget.message.autorUsuario.id))
                        Column(
                          children: [
                            InkWell(
                              child: Text(
                                widget.message.autorUsuario.username,
                                style: TextStyle(
                                  color: widget.message.isEntrante
                                      ? constants.usernameColors[widget.message.autorUsuario.username.hashCode % constants.usernameColors.length]
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () => widget.onProfileRequested(widget.message.autorUsuario),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),

                      if(widget.message.tipo == MensajeTipo.PROPINA_STICKER)
                        Column(children: [
                          Container(
                            width: 150,
                            height: 150,
                            padding: const EdgeInsets.symmetric(vertical: 16,),
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8,),
                            child: widget.message.propinaSticker!.sticker.getImageAssetName() != null
                                ? Image.asset(widget.message.propinaSticker!.sticker.getImageAssetName()!)
                                : null,
                            /*child: GestureDetector(
                              child: _showStickerAnimated ? Image.asset("assets/sticker_propina.gif") : Image.asset("assets/sticker_propina_stop.gif") ,
                              onTap: (){
                                setState(() => {_showStickerAnimated = !_showStickerAnimated});
                              },
                            ),*/
                          ),
                          Text("${widget.message.propinaSticker!.sticker.cantidadSatoshis} sats",
                            style: TextStyle(
                              color: widget.message.isEntrante ? Colors.black87 : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if(widget.isGroup)
                            Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 4,),
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(widget.message.propinaSticker!.isRecibido
                                  ? "El sticker lo recibe aleatoriamente alguno de los co-creadores. Tú recibiste este sticker."
                                  : "El sticker lo recibe aleatoriamente alguno de los co-creadores.",
                                style: TextStyle(
                                  color: widget.message.isEntrante ? constants.grey : Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ], mainAxisAlignment: MainAxisAlignment.center,),

                      if(widget.message.contenido != null)
                        Text.rich(
                          TextSpan(children: _linkify(widget.message.contenido!)),
                          style: TextStyle(
                            color: widget.message.isEntrante ? Colors.black87 : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(tlRadius),
                      topRight: Radius.circular(trRadius),
                      bottomLeft: Radius.circular(blRadius),
                      bottomRight: Radius.circular(brRadius),
                    ),
                    color: widget.message.isEntrante ? Colors.grey.shade200 : constants.blueLight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: widget.message.isEntrante ? MainAxisAlignment.start : MainAxisAlignment.end,
        ),
      ],),
      padding: EdgeInsets.fromLTRB(8, paddingTop, 8, paddingBottom),
    );
  }

  WidgetSpan _buildLinkComponent(String link) => WidgetSpan(
    child: InkWell(
      child: Text(
        link,
        style: TextStyle(
          color: widget.message.isEntrante ? Colors.black87 : Colors.white,
          decoration: TextDecoration.underline,
          fontSize: 16,
        ),
      ),
      onTap: () async {
        var realLink = link.startsWith('http') ? link : 'https://$link';

        Uri url = Uri.parse(realLink);

        try {
          // Tiene que estar dentro de try-catch (no usar canLaunchUrl)

          // Si no se usa LaunchMode.externalApplication, algunos link(por ej. youtube.com) no los abre
          await launchUrl(url, mode: LaunchMode.externalApplication,);

        } catch(e) {
          throw 'Could not launch $realLink';
        }
      },
    ),
  );

  List<InlineSpan> _linkify(String text) {
    var list = <InlineSpan>[];
    var match = widget.regExUrl.firstMatch(text);

    // If there are no matches, return all the text
    if (match == null) {
      list.add(TextSpan(text: text));
      return list;
    }

    // If there is some text before the match, add it to the list
    if (match.start > 0) list.add(TextSpan(text: text.substring(0, match.start)));

    list.add(_buildLinkComponent(match.group(0)!));

    // Call this function again and concatenate its list to ours
    list.addAll(_linkify(text.substring(match.start + match.group(0)!.length)));

    return list;
  }

  bool _shouldRound(_Corner corner, Mensaje message, Mensaje? messageToCompare) {
    switch (corner) {
      case _Corner.topLeft:
      case _Corner.bottomLeft:
        if (message.isEntrante &&
            messageToCompare != null &&
            (messageToCompare.tipo == null ||
                ![MensajeTipo.GRUPO_INGRESO, MensajeTipo.GRUPO_SALIDA, MensajeTipo.GRUPO_ELIMINAR_USUARIO,
                  MensajeTipo.GRUPO_ENCUENTRO_FECHA, MensajeTipo.GRUPO_ENCUENTRO_LINK].contains(messageToCompare.tipo)) &&
            message.autorUsuario.id == messageToCompare.autorUsuario.id) return false;

        break;
      case _Corner.topRight:
      case _Corner.bottomRight:
        if (!message.isEntrante &&
            messageToCompare != null &&
            (messageToCompare.tipo == null ||
                ![MensajeTipo.GRUPO_INGRESO, MensajeTipo.GRUPO_SALIDA, MensajeTipo.GRUPO_ELIMINAR_USUARIO,
                  MensajeTipo.GRUPO_ENCUENTRO_FECHA, MensajeTipo.GRUPO_ENCUENTRO_LINK].contains(messageToCompare.tipo)) &&
            message.autorUsuario.id == messageToCompare.autorUsuario.id) return false;

        break;
    }

    return true;
  }
}