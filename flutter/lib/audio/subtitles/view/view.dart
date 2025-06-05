import 'package:flutter/material.dart';

import 'package:ai_agent_quickstart_flutter/audio/subtitles/protocol/message_model.dart';
import 'model.dart';

/// 字幕消息列表视图
class ZegoSubtitlesView extends StatefulWidget {
  final ZegoSubtitlesViewModel model;

  const ZegoSubtitlesView({
    super.key,
    required this.model,
  });

  @override
  State<ZegoSubtitlesView> createState() => ZegoSubtitlesViewState();
}

class ZegoSubtitlesViewState extends State<ZegoSubtitlesView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ZegoSubtitlesMessageModel>>(
      valueListenable: widget.model.historyNotifier,
      builder: (context, messages, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMine = msg.isMine;
            return Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isMine
                        ? const Color(0xFF3370FF)
                        : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isMine ? Colors.white : const Color(0xFF222222),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
