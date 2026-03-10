// lib/screens/deepseek/deepseek_chat_screen.dart

import 'package:flutter/material.dart';
import 'deepseek_models.dart';
import '../../services/deepseek_service.dart';

class DeepSeekChatScreen extends StatefulWidget {
  final String? userId;

  const DeepSeekChatScreen({super.key, this.userId});

  @override
  State<DeepSeekChatScreen> createState() => _DeepSeekChatScreenState();
}

class _DeepSeekChatScreenState extends State<DeepSeekChatScreen> {
  final DeepSeekService _service = DeepSeekService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isServiceAvailable = true;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Load chat history
      final history = await _service.getChatHistory();

      if (mounted) {
        setState(() {
          _messages = history;
        });
      }

      // Check service health
      final isAvailable = await _service.checkServiceHealth();
      if (mounted) {
        setState(() {
          _isServiceAvailable = isAvailable;
        });
      }

      // Get session
      final session = await _service.getCurrentSession();
      if (mounted) {
        setState(() {
          _sessionId = session.sessionId;
        });
      }

      // Add welcome message if no history
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      // If initialization fails, clear corrupted storage
      await _service.clearCorruptedStorage();
      if (mounted) {
        setState(() {
          _messages = [];
        });
        _addWelcomeMessage();
      }
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome',
      content:
          '👋 Hallo, saya mbah dukun.\n\n'
          'Saya dapat membantu Anda dengan:\n'
          '📋 Update Job\n'
          '🚜 Unit Assets\n'
          '📦 Delivery\n'
          '🔙 Penarikan\n'
          '⚡ Charger & Charging\n'
          '🔋 Battery Health\n'
          '⚠️ Error Codes\n\n'
          'Silakan tanyakan apa saja! 😊',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (!_service.isValidMessage(message)) {
      _showSnackBar('Pesan terlalu pendek. Minimal 3 karakter.', isError: true);
      return;
    }

    // Clear input
    _messageController.clear();
    _messageFocusNode.unfocus();

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _scrollToBottom();

    // Send to API
    final response = await _service.sendMessage(
      message: message,
      userId: widget.userId,
      sessionId: _sessionId,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      // Add AI response
      final aiMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        content: response.reply!,
        isUser: false,
        timestamp: DateTime.now(),
        inScope: response.inScope ?? true,
        contextUsed: response.contextUsed,
        dataSummary: response.dataSummary,
        tokensUsed: response.tokensUsed,
        responseTimeMs: response.responseTimeMs,
      );

      setState(() {
        _messages.add(aiMessage);
      });

      _scrollToBottom();
    } else {
      _showSnackBar(response.error ?? 'Gagal mengirim pesan', isError: true);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat?'),
        content: const Text(
          'Semua percakapan akan dihapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.clearHistory();
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
      _showSnackBar('Riwayat chat berhasil dihapus');
    }
  }

  void _useSuggestion(String suggestion) {
    _messageController.text = suggestion;
    _messageFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DRR AI Assistant', style: TextStyle(fontSize: 18)),
            Text(
              'Powered by DeepSeek',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (!_isServiceAvailable)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus Riwayat',
            onPressed: _messages.isEmpty ? null : _clearHistory,
          ),
        ],
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Service status banner
          if (!_isServiceAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: const Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Layanan AI mungkin tidak tersedia',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Quick suggestions (show if no messages)
          if (_messages.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contoh pertanyaan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QuickSuggestion.getDefaultSuggestions()
                        .map(
                          (suggestion) => ActionChip(
                            avatar: Text(suggestion.icon),
                            label: Text(
                              suggestion.text,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _useSuggestion(suggestion.text),
                            backgroundColor: Colors.blue.shade50,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada percakapan.\nMulai bertanya sekarang! 💬',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI sedang berpikir...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    mini: true,
                    backgroundColor: _isLoading
                        ? Colors.grey.shade400
                        : Colors.blue.shade700,
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final showMetadata =
        !isUser &&
        (message.contextUsed?.isNotEmpty == true ||
            message.dataSummary?.isNotEmpty == true);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      if (showMetadata) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        if (message.contextUsed?.isNotEmpty == true)
                          Text(
                            '📊 Data: ${message.contextUsed!.join(", ")}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (message.responseTimeMs != null)
                          Text(
                            '⚡ ${message.responseTimeMs}ms',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }
}
