import 'dart:developer'; // Tambahkan ini
import 'package:dio/dio.dart';
import '../models/user.dart';

import '../constants/constants.dart';

class AuthServiceDio {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'DRR-App/1.0',
      },
    ),
  );

  Future<Map<String, dynamic>> login(String nrpp, String password) async {
    try {
      log('🚀 DIO LOGIN STARTED');

      final response = await _dio.post(
        '/login.php',
        data: {'nrpp': nrpp, 'password': password},
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) => status! < 500,
        ),
      );

      log('📥 DIO Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = User.fromJson(response.data['user']);
        return {
          'success': true,
          'user': user,
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Login failed',
        };
      }
    } on DioException catch (e) {
      log('❌ DIO ERROR: ${e.message}');
      log('📋 DIO Error type: ${e.type}');
      log('📄 DIO Response: ${e.response?.data}');

      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('💥 DIO UNEXPECTED ERROR: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
