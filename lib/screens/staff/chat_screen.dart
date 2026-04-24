import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String myId;
  final String myName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.myId,
    required this.myName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ChatService service = ChatService();

  // ================= SCROLL TO BOTTOM =================
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= SEND MESSAGE =================
  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    await service.sendMessage(
      roomId: widget.roomId,
      senderId: widget.myId,
      senderName: widget.myName,
      text: controller.text.trim(),
    );

    controller.clear();
    scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ================= APPBAR =================
      appBar: AppBar(
        title: const Text("Chat"),
        centerTitle: true,
        elevation: 0,
      ),

      body: Column(
        children: [
          // ================= MESSAGE LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: service.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // auto scroll khi có data
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  scrollToBottom();
                });

                return ListView.builder(
                  controller: scrollController,

                  // ❌ QUAN TRỌNG: KHÔNG reverse
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,

                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final isMe = data["senderId"] == widget.myId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isMe ? 14 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                data["senderName"] ?? "",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                            const SizedBox(height: 2),

                            Text(
                              data["message"] ?? "",
                              style: TextStyle(
                                fontSize: 14,
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ================= INPUT =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Nhập tin nhắn...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: sendMessage,
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.send, color: Colors.white, size: 18),
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
