// lib/screens/deepseek/deepseek_models.dart

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool inScope;
  final List<String>? contextUsed;
  final Map<String, dynamic>? dataSummary;
  final int? tokensUsed;
  final int? responseTimeMs;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.inScope = true,
    this.contextUsed,
    this.dataSummary,
    this.tokensUsed,
    this.responseTimeMs,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      inScope: json['in_scope'] ?? true,
      contextUsed: json['context_used'] != null
          ? List<String>.from(json['context_used'])
          : null,
      dataSummary: json['data_summary'],
      tokensUsed: json['tokens_used'],
      responseTimeMs: json['response_time_ms'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'in_scope': inScope,
      'context_used': contextUsed,
      'data_summary': dataSummary,
      'tokens_used': tokensUsed,
      'response_time_ms': responseTimeMs,
    };
  }
}

class ChatSession {
  final String sessionId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatSession({
    required this.sessionId,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatSession.newSession() {
    final now = DateTime.now();
    return ChatSession(
      sessionId: 'chat_${now.millisecondsSinceEpoch}',
      messages: [],
      createdAt: now,
    );
  }

  ChatSession copyWith({
    String? sessionId,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChatResponse {
  final bool success;
  final String? reply;
  final String? sessionId;
  final bool? inScope;
  final List<String>? contextUsed;
  final Map<String, dynamic>? dataSummary;
  final int? tokensUsed;
  final int? responseTimeMs;
  final String? error;

  ChatResponse({
    required this.success,
    this.reply,
    this.sessionId,
    this.inScope,
    this.contextUsed,
    this.dataSummary,
    this.tokensUsed,
    this.responseTimeMs,
    this.error,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    try {
      if (json['success'] == true && json['data'] != null) {
        final data = json['data'];

        // Safely parse context_used (could be List or null)
        List<String>? contextUsed;
        if (data['context_used'] != null && data['context_used'] is List) {
          try {
            contextUsed = List<String>.from(
              (data['context_used'] as List).map((e) => e.toString()),
            );
          } catch (e) {
            contextUsed = null;
          }
        }

        // Safely parse data_summary - handle all possible types
        Map<String, dynamic>? dataSummary;
        if (data['data_summary'] != null) {
          try {
            if (data['data_summary'] is Map) {
              // Already a map
              dataSummary = Map<String, dynamic>.from(data['data_summary']);
            } else if (data['data_summary'] is List) {
              // Convert empty list to null, non-empty list to empty map
              final list = data['data_summary'] as List;
              dataSummary = list.isEmpty ? null : <String, dynamic>{};
            } else {
              // Other types - ignore
              dataSummary = null;
            }
          } catch (e) {
            dataSummary = null;
          }
        }

        return ChatResponse(
          success: true,
          reply: data['reply']?.toString() ?? '',
          sessionId: data['session_id']?.toString(),
          inScope: data['in_scope'] ?? true,
          contextUsed: contextUsed,
          dataSummary: dataSummary,
          tokensUsed: int.tryParse(data['tokens_used']?.toString() ?? '0') ?? 0,
          responseTimeMs:
              int.tryParse(data['response_time_ms']?.toString() ?? '0') ?? 0,
        );
      } else {
        return ChatResponse(
          success: false,
          error: json['message']?.toString() ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      return ChatResponse(
        success: false,
        error: 'Error parsing response: ${e.toString()}',
      );
    }
  }
}

// Quick suggestions for user
class QuickSuggestion {
  final String text;
  final String icon;
  final String category;

  const QuickSuggestion({
    required this.text,
    required this.icon,
    required this.category,
  });

  static List<QuickSuggestion> getDefaultSuggestions() {
    return [
      const QuickSuggestion(
        text: 'Status update job hari ini',
        icon: '📋',
        category: 'jobs',
      ),
      const QuickSuggestion(
        text: 'Berapa unit yang sedang charging?',
        icon: '⚡',
        category: 'charger',
      ),
      const QuickSuggestion(
        text: 'Unit mana yang battery-nya perlu perhatian?',
        icon: '🔋',
        category: 'battery',
      ),
      const QuickSuggestion(
        text: 'Delivery yang pending apa saja?',
        icon: '📦',
        category: 'delivery',
      ),
      const QuickSuggestion(
        text: 'Info error code',
        icon: '⚠️',
        category: 'error',
      ),
    ];
  }
}
