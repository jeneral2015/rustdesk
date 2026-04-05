import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/chat_page.dart';
import 'package:flutter_hbb/models/chat_model.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_hbb/main.dart';

/// Chat Window Screen - Draggable chat window without taskbar icon
class ChatWindowScreen extends StatefulWidget {
  final String peerId;
  final int connId;

  const ChatWindowScreen({
    Key? key,
    required this.peerId,
    required this.connId,
  }) : super(key: key);

  @override
  State<ChatWindowScreen> createState() => _ChatWindowScreenState();
}

class _ChatWindowScreenState extends State<ChatWindowScreen> {
  late MessageKey _messageKey;

  @override
  void initState() {
    super.initState();
    _messageKey = MessageKey(widget.peerId, widget.connId);

    // Register this chat window
    gFFI.chatModel.registerOpenChatWindow(_messageKey);
    gFFI.chatModel.changeCurrentKey(_messageKey);
  }

  @override
  void dispose() {
    gFFI.chatModel.unregisterOpenChatWindow(_messageKey);
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    WindowController.fromWindowId(kWindowId!).startDragging();
  }

  void _onDragUpdate(DragUpdateDetails details) async {
    // startDragging handles it natively
  }

  void _onDragEnd(DragEndDetails details) {
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: MyTheme.accent.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Draggable title bar
                GestureDetector(
                  onPanStart: _onDragStart,
                  onPanUpdate: _onDragUpdate,
                  onPanEnd: _onDragEnd,
                  child: _buildTitleBar(),
                ),
                // Chat content
                Expanded(
                  child: ChatPage(
                    type: ChatPageType.desktopCM,
                    messageKey: _messageKey,
                    isStandalone: true,
                    hideControlButtons: true,
                    onClose: () async {
                      gFFI.chatModel.unregisterOpenChatWindow(_messageKey);
                      await WindowController.fromWindowId(kWindowId!).close();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MyTheme.accent,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14), // Slightly smaller than container
        ),
      ),
      child: Row(
        children: [
          // Drag handle
          MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Icon(
              Icons.drag_indicator,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // Peer name
          Expanded(
            child: Text(
              widget.peerId,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Minimize button
          IconButton(
            onPressed: () async {
              await WindowController.fromWindowId(kWindowId!).minimize();
            },
            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
            tooltip: 'Minimize',
            splashRadius: 16,
          ),
          // Close button
          IconButton(
            onPressed: () async {
              gFFI.chatModel.unregisterOpenChatWindow(_messageKey);
              await WindowController.fromWindowId(kWindowId!).close();
            },
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            tooltip: 'Close',
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}
