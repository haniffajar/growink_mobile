// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl =
      'https://mitrablud.com:8443/growink-backend/api';

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

  static Future<Map<String, dynamic>> getPlantDetail(String qrCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/scan/$qrCode'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("Error getPlantDetail: $e");
      return {};
    }
  }

  static Future<bool> claimPlant(
    String qrCode,
    String customName,
    String location,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/claim-plant'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'qr_code': qrCode,
        'custom_name': customName,
        'location': location,
        'planted_at': DateTime.now().toIso8601String().split('T')[0],
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
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
