import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/user.dart';

import '../constants/constants.dart';

class AuthService {
  final String baseUrl = AppConstants.baseUrl;

  Future<Map<String, dynamic>> login(String nrpp, String password) async {
    // Create a new client for each request
    final client = http.Client();

    try {
      log('🚀 LOGIN STARTED');
      final uri = Uri.parse('$baseUrl/login.php');

      // Prepare request
      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      request.headers['User-Agent'] = 'DRR-App/1.0';
      request.body = json.encode({'nrpp': nrpp, 'password': password});

      log('📤 Sending to: $uri');
      log('🔑 NRPP: $nrpp');

      // Send request with timeout
      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(seconds: 15));

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      log('📥 Received response:');
      log('   Status: ${response.statusCode}');
      log('   Content-Type: ${response.headers['content-type']}');
      log('   Content-Length: ${response.headers['content-length']}');
      log('   Body Length: ${response.body.length}');

      // Check for empty response
      if (response.body.isEmpty) {
        log('❌ EMPTY RESPONSE BODY');
        return {'success': false, 'message': 'Server returned empty response'};
      }

      // Check if response looks like JSON
      final trimmedBody = response.body.trim();
      if (trimmedBody.isEmpty) {
        log('❌ EMPTY RESPONSE AFTER TRIMMING');
        return {'success': false, 'message': 'Empty response after trimming'};
      }

      // Validate JSON structure
      if (!trimmedBody.startsWith('{') && !trimmedBody.startsWith('[')) {
        log('❌ RESPONSE IS NOT JSON: "$trimmedBody"');
        return {
          'success': false,
          'message': 'Server returned non-JSON response',
        };
      }

      log('📄 Response body: $trimmedBody');

      // Parse JSON
      try {
        final data = json.decode(trimmedBody);
        log('✅ JSON parsed successfully');

        if (response.statusCode == 200 && data['success'] == true) {
          log('🎉 LOGIN SUCCESS');
          final user = User.fromJson(data['user']);
          return {'success': true, 'user': user, 'message': data['message']};
        } else {
          log('❌ Login failed on server');
          return {
            'success': false,
            'message': data['message'] ?? 'Login failed',
          };
        }
      } on FormatException catch (e) {
        log('❌ JSON FORMAT EXCEPTION: $e');
        log('📄 Problematic response: "$trimmedBody"');
        return {'success': false, 'message': 'Invalid server response format'};
      }
    } catch (e) {
      log('💥 ERROR: $e');
      log('📋 Error type: ${e.runtimeType}');

      if (e.toString().contains('Timeout')) {
        return {'success': false, 'message': 'Connection timeout'};
      } else if (e.toString().contains('Socket') ||
          e.toString().contains('Network')) {
        return {'success': false, 'message': 'Network connection failed'};
      } else {
        return {'success': false, 'message': 'Connection error: $e'};
      }
    } finally {
      client.close();
      log('🔚 LOGIN PROCESS COMPLETED');
    }
  }

  // Save user data to shared preferences (you'll need shared_preferences package)
  Future<void> saveUserData(User user) async {
    // Implementation for saving user data locally
  }

  // Get saved user data
  Future<User?> getSavedUser() async {
    // Implementation for retrieving saved user data
    return null;
  }

  // Logout
  Future<void> logout() async {
    // Implementation for logout
  }
}
