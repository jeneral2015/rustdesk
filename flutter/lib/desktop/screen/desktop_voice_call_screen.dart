import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/audio_input.dart';
import 'package:flutter_hbb/models/chat_model.dart';
import 'package:get/get.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_hbb/main.dart';

/// Voice Call Window Screen - Standalone voice call window without close buttons
class VoiceCallWindowScreen extends StatefulWidget {
  final String peerId;
  final int connId;

  const VoiceCallWindowScreen({
    Key? key,
    required this.peerId,
    required this.connId,
  }) : super(key: key);

  @override
  State<VoiceCallWindowScreen> createState() => _VoiceCallWindowScreenState();
}

class _VoiceCallWindowScreenState extends State<VoiceCallWindowScreen> {
  late MessageKey _messageKey;

  @override
  void initState() {
    super.initState();
    _messageKey = MessageKey(widget.peerId, widget.connId);

    // Register this voice call window
    gFFI.chatModel.changeCurrentKey(_messageKey);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    WindowController.fromWindowId(kWindowId!).startDragging();
  }

  void _onDragUpdate(DragUpdateDetails details) async {
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
              color: Colors.black.withValues(alpha: 0.3),
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
                color: MyTheme.accent.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Draggable title bar - no close button
                GestureDetector(
                  onPanStart: _onDragStart,
                  onPanUpdate: _onDragUpdate,
                  onPanEnd: _onDragEnd,
                  child: _buildTitleBar(),
                ),
                // Voice call content
                Expanded(
                  child: _buildVoiceCallContent(),
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MyTheme.accent,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          // Drag handle
          MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Icon(
              Icons.drag_indicator,
              color: Colors.white.withValues(alpha: 0.7),
              size: 18,
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
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Voice call indicator
          Icon(
            Icons.call,
            color: Colors.white.withValues(alpha: 0.8),
            size: 18,
          ),
          const SizedBox(width: 8),
          // Only minimize button - no close button
          IconButton(
            onPressed: () async {
              await WindowController.fromWindowId(kWindowId!).minimize();
            },
            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
            tooltip: 'Minimize',
            splashRadius: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCallContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Voice call icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: MyTheme.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.call,
              color: MyTheme.accent,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          // Status text
          Obx(() {
            final status = gFFI.chatModel.voiceCallStatus.value;
            String statusText;
            switch (status) {
              case VoiceCallStatus.waitingForResponse:
                statusText = "Calling...";
                break;
              case VoiceCallStatus.connected:
                statusText = "Connected";
                break;
              case VoiceCallStatus.incoming:
                statusText = "Incoming Call";
                break;
              default:
                statusText = "Call Ended";
            }
            return Text(
              translate(statusText),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            );
          }),
          const SizedBox(height: 16),
          // Audio device selector
          AudioInput(
            builder: (devices, currentDevice, setDevice) {
              if (devices.isEmpty) {
                return Text(
                  translate("No audio devices"),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                );
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentDevice,
                    isDense: true,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, size: 18),
                    items: devices
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                d,
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDevice(v);
                    },
                  ),
                ),
              );
            },
            isCm: false,
            isVoiceCall: true,
          ),
          const SizedBox(height: 8),
          // Note: No disconnect button - call continues automatically
          Text(
            translate("Voice call active"),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
