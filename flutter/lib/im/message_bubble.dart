import 'package:flutter/material.dart';
import 'message.dart';

class ZegoIMMessageBubble extends StatelessWidget {
  final ZegoIMMessage message;

  const ZegoIMMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 16 : 16,
          right: isUser ? 16 : 16,
          top: 8,
          bottom: 8,
        ),
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF007AFF) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF000000),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
