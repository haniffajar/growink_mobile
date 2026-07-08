// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.16:8080/api';

  // HELPER UNTUK HEADER agar kodingan tidak duplikat
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json', // Server tahu kita minta JSON
    };
  }

  static Future<List<dynamic>> fetchGrowpedia({String? category}) async {
    String url = '$baseUrl/growpedia';
    if (category != null) url += '?category=$category';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? [];
    }
    throw Exception('Gagal memuat data Growpedia');
  }

  static Future<Map<String, dynamic>> scanQRCode(
    String qrCode,
    String? userId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'qr_code': qrCode,
        'user_id': userId ?? '', // Dikirim kosong jika belum login
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final errorBody = jsonDecode(response.body);
    throw Exception(errorBody['message'] ?? 'QR Code tidak dikenali');
  }

  static Future<bool> claimPlant(
    String qrCode,
    String verifCode,
    String userId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/claim-plant'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'qr_code': qrCode,
        'verif_code': verifCode,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  static Future<String?> updatePlantProfile(
    String plantId,
    String customName,
    String location,
    File? imageFile,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      var uri = Uri.parse('$baseUrl/user-plants/update-profile/$plantId');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Field text
      request.fields['custom_name'] = customName;
      request.fields['location'] = location;

      // Upload gambar jika ada
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        return jsonResponse['image_path'];
      }

      debugPrint(
        'Update Profile Error: ${response.statusCode} ${response.body}',
      );

      throw Exception(
        jsonDecode(response.body)['message'] ??
            'Gagal memperbarui profil tanaman.',
      );
    } catch (e) {
      debugPrint("updatePlantProfile Error : $e");
      throw Exception(e.toString());
    }
  }

  static Future<bool> recordActivity(
    String plantId,
    String activity, {
    required String notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'plant_id': plantId,
        'activity_type': activity,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint(
        "Gagal recordActivity: ${response.statusCode} - ${response.body}",
      );
    }
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<dynamic>> getPlantHistory(String plantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/activities/$plantId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> getMyPlants() async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-plants'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> fetchMyPlants(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-plants?user_id=$userId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? [];
    }
    throw Exception('Gagal memuat tanaman Anda');
  }

  // ==================== SERVICE INTERAKSI AI UPDATE ====================

  /// Mengirim chat terintegrasi (Teks, History Chat Multi-turn, dan Opsional Gambar Base64)
  static Future<String> interactWithAi({
    required String plantName,
    required String prompt,
    required List<Map<String, String>> history,
    String? imageBase64,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      // Pastikan history dikonversi menjadi list biasa yang bersih
      final cleanHistory = history
          .map((e) => {'role': e['role'], 'text': e['text']})
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl/ai/interact'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'plant_name': plantName,
          'prompt': prompt,
          'history': cleanHistory, // Mengirim data history terformat bersih
          'image_base64':
              imageBase64, // Mengirim null asli jika tidak ada gambar
          'mime_type': mimeType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? 'Tidak ada respons dari Pakar AI.';
      }

      // Membantu debugging: cetak isi body jika server mengembalikan error (500/404)
      debugPrint("Server Error AI Response: ${response.body}");
      return 'Error Server (${response.statusCode}): Gagal memproses data AI.';
    } catch (e) {
      debugPrint("Exception caught in interactWithAi: $e");
      return 'Gagal terhubung ke server AI: $e';
    }
  }

  /// Menyimpan data rekomendasi yang diekstrak dari tag AI ke Database Kebun
  static Future<bool> saveRecommendationToDb({
    required String plantId,
    required String jenis,
    required String detail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/plants/recommendation'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'plant_id': plantId,
          'type': jenis, // Dikirim langsung sebagai field 'type'
          'detail': detail, // Dikirim langsung sebagai field 'detail'
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Gagal mengirim rekomendasi ke endpoint DB: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getAiRecommendations(String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plants/recommendation/$plantId'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Error getAiRecommendations: $e");
      return [];
    }
  }
}
