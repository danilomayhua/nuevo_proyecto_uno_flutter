import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tenfo/utilities/constants.dart' as constants;

enum PopupMenuOption {
  DELETE_CHAT,
}

class ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool isGroup;
  final String title;
  final String? subtitle;
  final String? profilePictureUrl;
  final void Function() onChatInfoRequested;
  final void Function(PopupMenuOption) onPopupMenuItemSelected;

  const ChatAppBar({
    Key? key,
    required this.isGroup,
    required this.title,
    required this.subtitle,
    required this.profilePictureUrl,
    required this.onChatInfoRequested,
    required this.onPopupMenuItemSelected,
  }) : super(key: key);

  @override
  State<ChatAppBar> createState() => ChatAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class ChatAppBarState extends State<ChatAppBar> {

  bool _isIntegrante = true;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        if(!widget.isGroup)
          PopupMenuButton<PopupMenuOption>(
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('Eliminar chat'), value: PopupMenuOption.DELETE_CHAT,)
            ],
            onSelected: widget.onPopupMenuItemSelected,
          ),
        if(widget.isGroup && !_isIntegrante)
          PopupMenuButton<PopupMenuOption>(
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('Eliminar chat'), value: PopupMenuOption.DELETE_CHAT,)
            ],
            onSelected: widget.onPopupMenuItemSelected,
          ),
      ],
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const BackButton(),
              Expanded(
                child: TextButton(
                  child: Row(
                    children: [
                      Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.black12,
                            backgroundImage:
                            widget.profilePictureUrl == null ? null : CachedNetworkImageProvider("${widget.profilePictureUrl}"),
                          ),
                          Visibility(
                            visible: widget.isGroup,
                            child: const Icon(
                              Icons.groups,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      widget.isGroup ? Expanded(child: Column(
                        children: [
                          Text(widget.title,
                            style: const TextStyle(color: constants.blackGeneral, fontSize: 16,),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if(widget.subtitle != null)
                            Text(widget.subtitle!,
                              style: const TextStyle(color: constants.grey, fontSize: 12,),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),)
                      : Expanded(child: Text(widget.title,
                        style: Theme.of(context).textTheme.headline6, maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),

                    ],
                  ),
                  onPressed: widget.onChatInfoRequested,
                  style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.black12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void setIsIntegrante(bool value){
    setState(() {
      _isIntegrante = value;
    });
  }
}
