import 'package:flutter/material.dart';

import 'package:ai_agent_quickstart_flutter/local_strings.dart';
import 'package:ai_agent_quickstart_flutter/server/ai_agent_service.dart';
import 'package:ai_agent_quickstart_flutter/audio/subtitles/view/view.dart';
import 'package:ai_agent_quickstart_flutter/audio/subtitles/view/model.dart';
import 'package:ai_agent_quickstart_flutter/audio/subtitles/protocol/message_protocol.dart';
import 'package:ai_agent_quickstart_flutter/audio/subtitles/protocol/message_dispatcher.dart';

class ZegoAudioPage extends StatefulWidget {
  const ZegoAudioPage({super.key});

  @override
  State<ZegoAudioPage> createState() => _ZegoAudioPageState();
}

class _ZegoAudioPageState extends State<ZegoAudioPage>
    implements ZegoSubtitlesEventHandler {
  late ZegoAIAgentService aiAgentService;
  late ZegoSubtitlesViewModel subtitlesModel;
  final ValueNotifier<String> roomIdNotifier = ValueNotifier('');
  final ValueNotifier<String> userIdNotifier = ValueNotifier('');
  final ValueNotifier<String> agentUserIdNotifier = ValueNotifier('');
  final ValueNotifier<bool> subtitlesExpandedNotifier = ValueNotifier(true);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isLoginedNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    aiAgentService = ZegoAIAgentService();
    subtitlesModel = ZegoSubtitlesViewModel();
    roomIdNotifier.value = aiAgentService.getRoomId();
    userIdNotifier.value = aiAgentService.getUserId();
    agentUserIdNotifier.value = aiAgentService.getAgentUserId();

    ZegoSubtitlesMessageDispatcher().registerEventHandler(this);

    aiAgentService.init();
  }

  @override
  void dispose() {
    roomIdNotifier.dispose();
    userIdNotifier.dispose();
    agentUserIdNotifier.dispose();
    subtitlesExpandedNotifier.dispose();
    isLoadingNotifier.dispose();
    isLoginedNotifier.dispose();
    ZegoSubtitlesMessageDispatcher().unregisterEventHandler(this);
    aiAgentService.uninit();

    super.dispose();
  }

  @override
  void onRecvAsrChatMsg(ZegoSubtitlesMessageProtocol message) {
    subtitlesModel.handleRecvAsrMessage(message);
  }

  @override
  void onRecvLLMChatMsg(ZegoSubtitlesMessageProtocol message) {
    subtitlesModel.handleRecvLLMMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(LocalStrings.audioPageTitle),
        backgroundColor: const Color(0xFFD9D9D9),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 2),
            roomId(),
            const SizedBox(height: 2),
            userInfos(),
            const SizedBox(height: 10),
            logoutButton(),
            const SizedBox(height: 10),
            tips(),
            const SizedBox(height: 10),
            subtitles(),
          ],
        ),
      ),
    );
  }

  Widget userInfos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: userIdNotifier,
          builder: (context, userId, child) => buildCircleUser(userId),
        ),
        ValueListenableBuilder<String>(
          valueListenable: agentUserIdNotifier,
          builder: (context, agentUserId, child) =>
              buildCircleUser(agentUserId),
        ),
      ],
    );
  }

  Widget roomId() {
    return ValueListenableBuilder<String>(
      valueListenable: roomIdNotifier,
      builder: (context, roomId, child) {
        return Center(
          child: Text(
            LocalStrings.roomIdLabel(roomId),
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        );
      },
    );
  }

  Widget logoutButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoginedNotifier,
      builder: (context, isLogined, child) {
        return Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: isLoadingNotifier,
            builder: (context, isLoading, child) {
              return ElevatedButton(
                onPressed: isLoading
                    ? null
                    : (isLogined ? stopAudioChat : startAudioChat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLogined
                      ? const Color.fromRGBO(230, 102, 102, 1)
                      : const Color.fromRGBO(102, 230, 102, 1),
                  minimumSize: const Size(240, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isLogined
                            ? LocalStrings.logoutRoomButton
                            : LocalStrings.loginRoomButton,
                        style: const TextStyle(fontSize: 18),
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget tips() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        LocalStrings.audioChatNotice,
        style: TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }

  Widget subtitles() {
    return ValueListenableBuilder<bool>(
      valueListenable: subtitlesExpandedNotifier,
      builder: (context, isExpanded, child) {
        return Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  subtitlesExpandedNotifier.value = !isExpanded;
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFCCCCCC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      isExpanded
                          ? LocalStrings.subtitlesExpanded
                          : LocalStrings.subtitlesCollapsed,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              if (isExpanded)
                Expanded(
                  child: ZegoSubtitlesView(model: subtitlesModel),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> startAudioChat() async {
    isLoadingNotifier.value = true;
    try {
      final success = await aiAgentService.startCall();
      isLoginedNotifier.value = success;
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(LocalStrings.audioChatStartFailed),
          ),
        );
      }
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> stopAudioChat() async {
    isLoadingNotifier.value = true;
    try {
      isLoginedNotifier.value = false;
      final success = await aiAgentService.stopCall();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(LocalStrings.audioChatStopFailed),
          ),
        );
      }
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Widget buildCircleUser(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
