import 'package:flutter/material.dart';
import 'ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();

  bool isLoading = false;

  final List<Map<String, String>> messages = [
    {
      'sender': 'bot',
      'text': 'مرحبًا بك في المساعد الصحي 💚\nكيف يمكنني مساعدتك اليوم؟',
    },
  ];

  Future<void> sendMessage() async {
    final message = messageController.text.trim();

    if (message.isEmpty || isLoading) return;

    setState(() {
      messages.add({
        'sender': 'user',
        'text': message,
      });

      isLoading = true;
    });

    messageController.clear();
    scrollToBottom();

    try {
      final reply = await AIService.sendMessage(message);

      if (!mounted) return;

      setState(() {
        messages.add({
          'sender': 'bot',
          'text': reply,
        });
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add({
          'sender': 'bot',
          'text': 'حدث خطأ أثناء الاتصال بالمساعد الصحي.',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        scrollToBottom();
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),

      appBar: AppBar(
        title: const Text('المساعد الصحي الذكي'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isLoading ? 1 : 0),

              itemBuilder: (context, index) {
                if (isLoading && index == messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                        ),
                        SizedBox(width: 12),
                        Text('المساعد يكتب الآن...'),
                      ],
                    ),
                  );
                }

                final message = messages[index];
                final isUser = message['sender'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF4CAF50)
                          : Colors.white,

                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Text(
                      message['text'] ?? '',
                      textDirection: TextDirection.rtl,

                      style: TextStyle(
                        fontSize: 16,
                        color: isUser
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,

            child: Row(
              children: [
                IconButton(
                  onPressed: isLoading ? null : sendMessage,
                  icon: const Icon(
                    Icons.send,
                    color: Color(0xFF4CAF50),
                  ),
                ),

                Expanded(
                  child: TextField(
                    controller: messageController,
                    textDirection: TextDirection.rtl,
                    enabled: !isLoading,

                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك هنا...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}