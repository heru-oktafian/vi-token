import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final baseUrl = await _storage.getBaseUrl();
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        final user = UserModel.fromJson(data['data']['user']);

        await _storage.saveToken(token);
        await _storage.saveUser(user);

        return {'success': true, 'user': user, 'token': token};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login gagal, periksa kredensial Anda.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server ($baseUrl): ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> authorizeQR(String sessionId, {String? deviceId}) async {
    final baseUrl = await _storage.getBaseUrl();
    final token = await _storage.getToken();

    if (token == null) {
      return {'success': false, 'message': 'Sesi login mobile Anda telah habis.'};
    }

    final url = Uri.parse('$baseUrl/auth/qr/authorize');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'device_id': deviceId ?? 'vi-token-mobile-app',
          'action_type': 'WEB_LOGIN',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Otorisasi berhasil!',
          'branches': data['data']['branches'] ?? []
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengotorisasi sesi QR.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menghubungi server: ${e.toString()}'
      };
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
