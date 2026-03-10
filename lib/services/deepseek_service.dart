// lib/services/deepseek_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../screens/deepseek/deepseek_models.dart';

class DeepSeekService {
  static const String baseUrl = 'https://drr.exprosa.com/api/deepseek';
  static const Duration timeout = Duration(seconds: 60);

  // Singleton pattern
  static final DeepSeekService _instance = DeepSeekService._internal();
  factory DeepSeekService() => _instance;
  DeepSeekService._internal();

  // Current session
  ChatSession? _currentSession;

  // Get or create current session
  Future<ChatSession> getCurrentSession() async {
    if (_currentSession == null) {
      // Try to load from storage
      _currentSession = await _loadSessionFromStorage();

      // If still null, create new session
      _currentSession ??= ChatSession.newSession();
    }
    return _currentSession!;
  }

  // Start new session
  Future<ChatSession> startNewSession() async {
    _currentSession = ChatSession.newSession();
    await _saveSessionToStorage(_currentSession!);
    return _currentSession!;
  }

  // Send message to AI
  Future<ChatResponse> sendMessage({
    required String message,
    String? userId,
    String? sessionId,
  }) async {
    try {
      final session = await getCurrentSession();
      final effectiveSessionId = sessionId ?? session.sessionId;

      // Add delay to prevent rate limiting
      await Future.delayed(const Duration(seconds: 2));

      // Prepare request
      final url = Uri.parse('$baseUrl/chat.php');
      final body = jsonEncode({
        'message': message.trim(),
        'user_id': userId,
        'session_id': effectiveSessionId,
      });

      debugPrint('DeepSeek Request: $body');

      // Send request with error handling
      late http.Response response;
      try {
        response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: body,
            )
            .timeout(timeout);
      } catch (e) {
        debugPrint('HTTP Request Error: $e');
        rethrow;
      }

      debugPrint('DeepSeek Response Status: ${response.statusCode}');
      debugPrint(
        'DeepSeek Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );

      // Handle response
      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          final chatResponse = ChatResponse.fromJson(jsonResponse);

          if (chatResponse.success && chatResponse.reply != null) {
            // Add messages to session
            final userMessage = ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: message,
              isUser: true,
              timestamp: DateTime.now(),
            );

            final aiMessage = ChatMessage(
              id: '${DateTime.now().millisecondsSinceEpoch}_ai',
              content: chatResponse.reply!,
              isUser: false,
              timestamp: DateTime.now(),
              inScope: chatResponse.inScope ?? true,
              contextUsed: chatResponse.contextUsed,
              dataSummary: chatResponse.dataSummary,
              tokensUsed: chatResponse.tokensUsed,
              responseTimeMs: chatResponse.responseTimeMs,
            );

            // Update session
            _currentSession = session.copyWith(
              messages: [...session.messages, userMessage, aiMessage],
              updatedAt: DateTime.now(),
            );

            // Save to storage
            try {
              await _saveSessionToStorage(_currentSession!);
            } catch (e) {
              debugPrint('Error saving session: $e');
              // Don't fail the request if storage fails
            }
          }

          return chatResponse;
        } catch (e) {
          debugPrint('JSON Parse Error: $e');
          return ChatResponse(
            success: false,
            error: 'Gagal mem-parse respons dari server',
          );
        }
      } else if (response.statusCode == 429) {
        return ChatResponse(
          success: false,
          error: 'Terlalu banyak permintaan. Tunggu beberapa saat lagi.',
        );
      } else if (response.statusCode == 503) {
        return ChatResponse(
          success: false,
          error: 'Layanan AI sedang tidak tersedia. Silakan coba lagi nanti.',
        );
      } else {
        return ChatResponse(
          success: false,
          error: 'Server Error (${response.statusCode})',
        );
      }
    } on SocketException catch (e) {
      debugPrint('Socket Error: $e');
      return ChatResponse(
        success: false,
        error: 'Tidak ada koneksi internet. Periksa koneksi Anda.',
      );
    } on TimeoutException catch (e) {
      debugPrint('Timeout Error: $e');
      return ChatResponse(
        success: false,
        error: 'Permintaan timeout. Silakan coba lagi.',
      );
    } on FormatException catch (e) {
      debugPrint('Format Error: $e');
      return ChatResponse(success: false, error: 'Format respons tidak valid.');
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      return ChatResponse(
        success: false,
        error: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  // Get chat history
  Future<List<ChatMessage>> getChatHistory() async {
    final session = await getCurrentSession();
    return session.messages;
  }

  // Clear chat history
  Future<void> clearHistory() async {
    _currentSession = ChatSession.newSession();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deepseek_session');
      debugPrint('Chat history cleared');
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  // Clear storage if corrupted
  Future<void> clearCorruptedStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deepseek_session');
      _currentSession = ChatSession.newSession();
      debugPrint('Cleared corrupted storage');
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  // Storage helpers with size limit
  Future<void> _saveSessionToStorage(ChatSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limit messages to last 50 only (prevent memory issues)
      final limitedMessages = session.messages.length > 50
          ? session.messages.sublist(session.messages.length - 50)
          : session.messages;

      // Strip large data from messages before saving
      final compactMessages = limitedMessages.map((m) {
        return {
          'id': m.id,
          'content': m.content.length > 500
              ? '${m.content.substring(0, 500)}...'
              : m.content,
          'isUser': m.isUser,
          'timestamp': m.timestamp.toIso8601String(),
          'in_scope': m.inScope,
        };
      }).toList();

      final sessionJson = jsonEncode({
        'session_id': session.sessionId,
        'created_at': session.createdAt.toIso8601String(),
        'updated_at': session.updatedAt?.toIso8601String(),
        'messages': compactMessages,
      });

      // Check size before saving (max 1MB for safety)
      if (sessionJson.length < 1000000) {
        await prefs.setString('deepseek_session', sessionJson);
        debugPrint('Session saved: ${sessionJson.length} bytes');
      } else {
        debugPrint('Session too large, clearing old messages');
        await prefs.remove('deepseek_session');
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
      // If error, clear storage to prevent future crashes
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('deepseek_session');
      } catch (_) {}
    }
  }

  Future<ChatSession?> _loadSessionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('deepseek_session');

      if (sessionJson == null) {
        debugPrint('No saved session found');
        return null;
      }

      final data = jsonDecode(sessionJson);
      final messages =
          (data['messages'] as List?)
              ?.map((m) {
                try {
                  return ChatMessage.fromJson(m);
                } catch (e) {
                  debugPrint('Error parsing message: $e');
                  return null;
                }
              })
              .whereType<ChatMessage>()
              .toList() ??
          [];

      debugPrint('Loaded session with ${messages.length} messages');

      return ChatSession(
        sessionId: data['session_id'],
        messages: messages,
        createdAt: DateTime.parse(data['created_at']),
        updatedAt: data['updated_at'] != null
            ? DateTime.parse(data['updated_at'])
            : null,
      );
    } catch (e) {
      debugPrint('Error loading session: $e');
      return null;
    }
  }

  // Validate message before sending
  bool isValidMessage(String message) {
    final trimmed = message.trim();
    return trimmed.isNotEmpty && trimmed.length >= 3;
  }

  // Format data summary for display
  String formatDataSummary(Map<String, dynamic>? summary) {
    if (summary == null || summary.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('📊 Data yang digunakan:');

    summary.forEach((key, value) {
      final displayKey = key
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (word) =>
                word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
          )
          .join(' ');
      buffer.writeln('  • $displayKey: $value');
    });

    return buffer.toString();
  }

  // Check if service is available
  Future<bool> checkServiceHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health.php');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      final isHealthy = response.statusCode == 200;
      debugPrint('DeepSeek Service Health: ${isHealthy ? 'UP' : 'DOWN'}');
      return isHealthy;
    } catch (e) {
      debugPrint('Health check error: $e');
      return false;
    }
  }
}
