import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl =
      'https://growink.app/backend/api/v1'; // Sesuaikan IP Anda

  // Inisialisasi Secure Storage
  static const _secureStorage = FlutterSecureStorage();

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }

  // Mengambil Access Token dari storage yang aman
  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  // Fungsi otomatis untuk refresh token ke backend
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        body: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Simpan JWT baru
        await _secureStorage.write(key: 'jwt_token', value: data['token']);

        // TAMBAHKAN INI: Simpan Refresh Token baru dari backend (Token Rotation)
        if (data['refresh_token'] != null) {
          await _secureStorage.write(
            key: 'refresh_token',
            value: data['refresh_token'],
          );
        }

        return true;
      } else {
        // Jika refresh token ditolak, paksa logout
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String loginId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'login_id': loginId, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // Simpan token ke Secure Storage
        await _secureStorage.write(key: 'jwt_token', value: data['token']);
        await _secureStorage.write(
          key: 'refresh_token',
          value: data['refresh_token'],
        );

        // Simpan Data User ke SharedPreferences
        await prefs.setString('uid', data['user']['id'].toString());

        // Status Premium
        bool isPremium = data['user']['is_premium'] == 1;
        await prefs.setBool('is_premium', isPremium);

        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': 'Login gagal, periksa kredensial Anda.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        },
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': responseData['message']};
      } else if (response.statusCode == 400) {
        final messages = responseData['messages'];
        String errorMessage = messages is Map
            ? messages.values.first
            : messages.toString();

        return {'success': false, 'message': errorMessage};
      } else {
        return {'success': false, 'message': 'Terjadi kesalahan server.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  static Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        // Hapus token di sisi backend
        await http.post(
          Uri.parse('$baseUrl/logout'),
          body: {'refresh_token': refreshToken},
        );
      }
    } catch (e) {
      // Abaikan error jaringan, lanjutkan penghapusan memori lokal
    } finally {
      // Bersihkan Secure Storage
      await _secureStorage.delete(key: 'jwt_token');
      await _secureStorage.delete(key: 'refresh_token');

      // Bersihkan SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('uid');
      await prefs.remove('is_premium');
    }
  }

  static Future<void> setPremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', isPremium);
  }

  static Future<bool> getPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_premium') ?? false;
  }
}
