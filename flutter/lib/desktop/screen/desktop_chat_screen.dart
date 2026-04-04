import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/chat_page.dart';
import 'package:flutter_hbb/models/chat_model.dart';
import 'package:window_manager/window_manager.dart';

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

class _ChatWindowScreenState extends State<ChatWindowScreen>
    with WindowListener {
  late MessageKey _messageKey;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initializeWindow();
    _messageKey = MessageKey(widget.peerId, widget.connId);

    // Register this chat window
    gFFI.chatModel.registerOpenChatWindow(_messageKey);
    gFFI.chatModel.changeCurrentKey(_messageKey);
  }

  Future<void> _initializeWindow() async {
    // Set window properties for chat-only mode
    await windowManager.setSize(Size(450, 600));
    await windowManager.setMinimumSize(Size(350, 400));
    await windowManager.setMaximumSize(Size(800, 900));
    await windowManager.center();

    // Make window always on top for chat visibility
    await windowManager.setAlwaysOnTop(true);

    // Show the window
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    gFFI.chatModel.unregisterOpenChatWindow(_messageKey);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    gFFI.chatModel.unregisterOpenChatWindow(_messageKey);
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) async {
    final currentPos = await windowManager.getPosition();
    await windowManager.setPosition(
      Offset(
        currentPos.dx + details.delta.dx,
        currentPos.dy + details.delta.dy,
      ),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    onClose: () {
                      gFFI.chatModel.unregisterOpenChatWindow(_messageKey);
                      windowManager.close();
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
              await windowManager.minimize();
            },
            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
            tooltip: 'Minimize',
            splashRadius: 16,
          ),
          // Close button
          IconButton(
            onPressed: () {
              gFFI.chatModel.unregisterOpenChatWindow(_messageKey);
              windowManager.close();
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
