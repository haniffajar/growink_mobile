import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl = 'http://192.168.1.16:8080/api/v1'; // Ganti IP

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }

  Future<Map<String, dynamic>> login(String loginId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        body: {'login_id': loginId, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('jwt_token', data['token']);
        await prefs.setString(
          'uid',
          data['user']['id'].toString(),
        ); // Simpan User ID

        // ==========================================
        // TAMBAHKAN 2 BARIS INI UNTUK STATUS PREMIUM
        // ==========================================
        // Membaca integer dari backend (1 = Premium, 0 = Gratis)
        bool isPremium = data['user']['is_premium'] == 1;
        // Menyimpan status tersebut ke penyimpanan lokal HP
        await prefs.setBool('is_premium', isPremium);
        // ==========================================

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
        Uri.parse('$_baseUrl/register'),
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
        // Mengambil pesan error dari API
        // Jika error berisi beberapa field, kita ambil yang pertama saja
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('uid');
    await prefs.remove('is_premium'); // Hapus juga memori premium
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
