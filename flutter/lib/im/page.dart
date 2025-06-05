import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ai_agent_quickstart_flutter/local_strings.dart';
import 'package:ai_agent_quickstart_flutter/server/im_service.dart';
import 'package:ai_agent_quickstart_flutter/server/ai_agent_service.dart';
import 'package:ai_agent_quickstart_flutter/audio/page.dart';

import 'message.dart';
import 'message_bubble.dart';

class ZegoIMPage extends StatefulWidget {
  const ZegoIMPage({super.key});

  @override
  State<ZegoIMPage> createState() => _ZegoIMPageState();
}

class _ZegoIMPageState extends State<ZegoIMPage> {
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode inputFocusNode = FocusNode();
  final ValueNotifier<List<ZegoIMMessage>> messagesNotifier = ValueNotifier([]);
  final ValueNotifier<String> agentNameNotifier = ValueNotifier('');
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(true);
  late ZegoIMService chatService;
  late ZegoAIAgentService aiAgentService;
  StreamSubscription<dynamic>? messageStreamSubscription;

  @override
  void initState() {
    super.initState();

    chatService = ZegoIMService();
    aiAgentService = ZegoAIAgentService();
    agentNameNotifier.value = aiAgentService.getAgentName();

    /// 初始化并登录ZIM
    _initializeZIM();
  }

  @override
  void dispose() {
    inputFocusNode.dispose();
    chatService.deinitialize();

    textController.dispose();
    scrollController.dispose();
    messagesNotifier.dispose();
    agentNameNotifier.dispose();
    isLoadingNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        flexibleSpace: SafeArea(
          child: Center(
            child: ValueListenableBuilder<String>(
              valueListenable: agentNameNotifier,
              builder: (context, agentName, child) {
                return Text(
                  agentName,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Permission.microphone.request().then((status) async {
                /// 先析构当前页面
                messageStreamSubscription?.cancel();
                chatService.deinitialize();

                /// 跳转到AudioPage并等待返回
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ZegoAudioPage()),
                );

                /// 返回后重新初始化
                if (mounted) {
                  _initializeZIM();
                }
              });
            },
            child: const Text(
              LocalStrings.voiceButton,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: isLoadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [Expanded(child: messageList()), bottomBar()],
            ),
          );
        },
      ),
    );
  }

  Future<void> _initializeZIM() async {
    try {
      final initResult = await chatService.initialize();

      if (!initResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('初始化失败')),
          );
        }
        return;
      }

      messagesNotifier.value = [];
      messageStreamSubscription =
          chatService.messageStream.listen(onMessageUpdated);

      final loginResult = await chatService.login();
      if (!loginResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录失败')),
          );
        }
      }

      isLoadingNotifier.value = false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败：$e')),
        );
      }
    }
  }

  void onMessageUpdated(ZegoIMMessage message) {
    final currentMessages = messagesNotifier.value;
    final updatedMessages = [...currentMessages, message];
    updatedMessages.sort((a, b) => a.orderKey.compareTo(b.orderKey));
    messagesNotifier.value = updatedMessages;

    // 使用microtask确保在消息渲染完成后再滚动
    Future.microtask(() {
      if (mounted) {
        scrollToBottom();
      }
    });
  }

  void scrollToBottom() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (scrollController.hasClients) {
        try {
          // 使用jumpTo而不是animateTo，避免动画可能带来的问题
          scrollController.jumpTo(0); // 因为列表反转了，所以滚动到0就是底部
        } catch (e) {
          debugPrint('Scroll error: $e');
        }
      }
    });
  }

  void handleSubmitted(String text) {
    if (text.trim().isEmpty) {
      return;
    }

    textController.clear();
    chatService.sendMessage(text).then((success) {
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('消息发送失败')),
        );
      }
      inputFocusNode.requestFocus();
    });
  }

  Widget messageList() {
    return ValueListenableBuilder<List<ZegoIMMessage>>(
      valueListenable: messagesNotifier,
      builder: (context, messages, child) {
        return ListView.builder(
          reverse: true, // 反转列表，新消息从底部开始显示
          controller: scrollController,
          padding: const EdgeInsets.all(8.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            // 因为列表反转了，所以需要反转索引
            final message = messages[messages.length - 1 - index];
            return ZegoIMMessageBubble(message: message);
          },
        );
      },
    );
  }

  Widget bottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: inputFocusNode,
                decoration: const InputDecoration(
                  hintText: LocalStrings.chatInputHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onSubmitted: handleSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                handleSubmitted(textController.text);
              },
              child: const Text(LocalStrings.sendButton),
            ),
          ],
        ),
      ),
    );
  }
}
