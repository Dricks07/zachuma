import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({"text": _controller.text.trim(), "isUser": true});
      _controller.clear();
    });

    // TODO: Integrate AI response here
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          "text":
          "Great question! Start by setting a budget and saving at least 10% of your income.",
          "isUser": false,
        });
      });
    });
  }

  void _newChat() {
    setState(() {
      _messages.clear();
    });
  }

  void _showHistory() {
    // TODO: Implement actual history logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History tapped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 2,
        centerTitle: true,
        title: Text(
          "ZaChuma Assistant",
          style: AppTextStyles.heading.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 24, color: AppColors.textPrimary),
            tooltip: "History",
            onPressed: _showHistory,
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, size: 24, color: AppColors.primary),
            tooltip: "New Chat",
            onPressed: _newChat,
          ),
          const SizedBox(width: 8), // small spacing at the end
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildPlaceholder(context)
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg["isUser"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: msg["isUser"]
                          ? AppColors.primary.withOpacity(0.9)
                          : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: msg["isUser"]
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: msg["isUser"]
                            ? Radius.zero
                            : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 5,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      msg["text"],
                      style: AppTextStyles.regular.copyWith(
                        fontSize: 16,
                        color: msg["isUser"]
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return const Center(
      child: Text(
        "What can I help with?",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: AppTextStyles.regular.copyWith(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Ask ZaChuma AI...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.send,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
