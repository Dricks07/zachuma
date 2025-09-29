import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../constants.dart';

// ---------------- OpenRouter Service ----------------
class OpenRouterService {
  final String apiKey =
      "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";

  Future<String> sendMessage(String prompt) async {
    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    // Financial-focused system prompt
    const financialSystemPrompt = """
You are ZaChuma AI, a financial assistant specialized in personal finance, investing, budgeting, savings, and money management. 
Your role is to ONLY answer questions related to financial topics. 

Financial topics include:
- Personal budgeting and expense tracking
- Saving strategies and emergency funds
- Investment options (stocks, bonds, mutual funds, crypto)
- Retirement planning (401k, IRA, pension plans)
- Debt management and credit scores
- Tax planning and optimization
- Insurance (life, health, property)
- Real estate and mortgage advice
- Financial goal setting
- Economic concepts and terminology

If a question is not financial-related, politely decline to answer and remind the user that you're a financial assistant.
Be concise, practical, and provide actionable advice when appropriate.
Use markdown formatting for better readability (headings, lists, bold text).
""";

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "meta-llama/llama-3.1-8b-instruct",
          "messages": [
            {"role": "system", "content": financialSystemPrompt},
            {"role": "user", "content": prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"] ??
            "⚠️ No response from AI.";
      } else {
        return "⚠️ Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "❌ Exception: $e";
    }
  }
}

// ---------------- Firestore Service ----------------
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a conversation to Firestore
  Future<void> saveConversation(String conversationId, List<Map<String, dynamic>> messages) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set({
        'messages': messages,
        'lastUpdated': FieldValue.serverTimestamp(),
        'title': messages.isNotEmpty ? _generateTitle(messages.first['text']) : 'New Chat',
      });
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  // Get all conversations from Firestore
  Stream<QuerySnapshot> getConversations() {
    return _firestore
        .collection('conversations')
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  // Get a specific conversation by ID
  Future<DocumentSnapshot> getConversation(String conversationId) async {
    return await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
  }

  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .delete();
  }

  // Generate a title from the first message
  String _generateTitle(String firstMessage) {
    if (firstMessage.length <= 30) return firstMessage;
    return '${firstMessage.substring(0, 30)}...';
  }
}

// ---------------- Markdown Message Widget ----------------
class MarkdownMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const MarkdownMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Text(
        text,
        style: AppTextStyles.regular.copyWith(
          fontSize: 16,
          color: Colors.white,
        ),
      );
    }

    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: AppTextStyles.regular.copyWith(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        strong: AppTextStyles.regular.copyWith(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        em: AppTextStyles.regular.copyWith(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontStyle: FontStyle.italic,
        ),
        h1: AppTextStyles.heading.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h2: AppTextStyles.heading.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h3: AppTextStyles.heading.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        listBullet: AppTextStyles.regular.copyWith(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        blockquote: AppTextStyles.regular.copyWith(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontStyle: FontStyle.italic,
          backgroundColor: AppColors.primary.withOpacity(0.1),
        ),
        code: TextStyle(
          backgroundColor: AppColors.background,
          color: AppColors.primary,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 4,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- ChatbotScreen ----------------
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final OpenRouterService _openRouterService = OpenRouterService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String? _currentConversationId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _createNewConversation();
    _addWelcomeMessage();
  }

  void _createNewConversation() {
    setState(() {
      _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        "text": """# Welcome to ZaChuma AI! 💰

I'm your financial assistant here to help you with:

- **Budgeting & Saving** 💸
- **Investing & Wealth Building** 📈  
- **Debt Management** 🏦
- **Retirement Planning** 🏖️
- **Tax Optimization** 📊
- **Financial Goal Setting** 🎯

Ask me anything about personal finance!""",
        "isUser": false,
        "timestamp": DateTime.now(),
      });
    });
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userMessage = _controller.text.trim();
    setState(() {
      _messages.add({
        "text": userMessage,
        "isUser": true,
        "timestamp": DateTime.now(),
      });
      _controller.clear();
      _isLoading = true;
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Save conversation after user message
    await _firestoreService.saveConversation(_currentConversationId!, _messages);

    // Send to OpenRouter AI
    String aiResponse = await _openRouterService.sendMessage(userMessage);

    setState(() {
      _messages.add({
        "text": aiResponse,
        "isUser": false,
        "timestamp": DateTime.now(),
      });
      _isLoading = false;
    });

    // Auto-scroll to bottom after AI response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Save conversation after AI response
    await _firestoreService.saveConversation(_currentConversationId!, _messages);
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _createNewConversation();
      _addWelcomeMessage();
    });
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => _buildHistoryDialog(),
    );
  }

  void _loadConversation(String conversationId) async {
    try {
      final doc = await _firestoreService.getConversation(conversationId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _messages.clear();
          _messages.addAll(List<Map<String, dynamic>>.from(data['messages'] ?? []));
          _currentConversationId = conversationId;
        });
        Navigator.of(context).pop(); // Close history dialog
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading conversation: $e')),
      );
    }
  }

  Widget _buildHistoryDialog() {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Conversation History',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getConversations(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No conversations yet'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = data['lastUpdated'] as Timestamp?;
                      final date = timestamp?.toDate();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                          title: Text(
                            data['title'] ?? 'Financial Discussion',
                            style: AppTextStyles.regular.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            date != null
                                ? '${date.day}/${date.month}/${date.year} - ${(data['messages'] as List?)?.length ?? 0} messages'
                                : '${(data['messages'] as List?)?.length ?? 0} messages',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _deleteConversation(doc.id),
                          ),
                          onTap: () => _loadConversation(doc.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteConversation(String conversationId) async {
    try {
      await _firestoreService.deleteConversation(conversationId);
      if (_currentConversationId == conversationId) {
        _newChat();
      }
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting conversation: $e')),
      );
    }
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildPlaceholder(context)
                : ListView.builder(
              controller: _scrollController,
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
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
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
                    child: MarkdownMessage(
                      text: msg["text"],
                      isUser: msg["isUser"],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "ZaChuma AI is thinking...",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              "Welcome to ZaChuma AI!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Your personal financial assistant\nAsk me about budgeting, investing, or saving!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
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
                  hintText: "Ask about finance, investing, budgeting...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _controller.text.trim().isEmpty
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.primary,
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