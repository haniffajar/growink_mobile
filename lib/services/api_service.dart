// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.16:8080/api';

  // HELPER UNTUK HEADER agar kodingan tidak duplikat
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json', // Server tahu kita minta JSON
    };
  }

  static Future<Map<String, dynamic>> scanQRCode(
    String qrCode,
    String? userId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan'),
      headers: await getHeaders(),
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

  static Future<Map<String, dynamic>> claimPlant(
    String qrCode,
    String verifCode,
    String userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/claim-plant'),
        headers: await getHeaders(),
        body: jsonEncode({
          'qr_code': qrCode,
          'verif_code': verifCode,
          'user_id': userId,
        }),
      );

      // Decode response body
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': true,
          'message': responseData['message'] ?? 'Berhasil klaim tanaman.',
        };
      }
      // Tangkap error 403 jika limit tanaman tercapai (is_limit_reached dari backend)
      else if (response.statusCode == 403 &&
          responseData['is_limit_reached'] == true) {
        return {
          'status': false,
          'is_limit_reached': true,
          'message': responseData['message'] ?? 'Limit kebun penuh!',
        };
      }
      // Tangkap error lainnya (QR salah, dll)
      else {
        return {
          'status': false,
          'is_limit_reached': false,
          'message': responseData['message'] ?? 'Gagal klaim tanaman.',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'is_limit_reached': false,
        'message': 'Terjadi kesalahan jaringan.',
      };
    }
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
      headers: await getHeaders(),
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
      headers: await getHeaders(),
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
      headers: await getHeaders(),
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
      // OPTIMASI: Pastikan history benar-benar bersih.
      // Jangan pernah memasukkan gambar ke dalam history array.
      // Jika ada history yang mengandung gambar, cukup kirim teksnya saja.
      final cleanHistory = history.map((e) {
        String text = e['text'] ?? '';
        // Jika history mengandung tag gambar, bersihkan agar tidak dianggap sebagai payload gambar
        text = text.replaceAll(RegExp(r'📷 \[.*?\]'), '').trim();

        return {'role': e['role'], 'text': text};
      }).toList();

      // Pastikan URL sudah sesuai dengan group route di CodeIgniter Anda
      // Karena baseUrl sudah mengandung '/api', maka endpointnya adalah '/ai/interact'
      final response = await http.post(
        Uri.parse('$baseUrl/ai/interact'),
        headers: await getHeaders(),
        body: jsonEncode({
          'plant_name': plantName,
          'prompt': prompt,
          'history': cleanHistory, // Hanya data teks yang bersih
          'image_base64':
              imageBase64, // Gambar hanya dikirim di request ini (current request)
          'mime_type': mimeType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? 'Tidak ada respons dari Pakar AI.';
      }

      // Penanganan error yang lebih informatif untuk debugging
      if (response.statusCode == 500) {
        return 'Server AI sedang sibuk atau timeout. Coba lagi nanti.';
      }

      debugPrint("Server Error AI Response: ${response.body}");
      return 'Gagal memproses data AI (${response.statusCode}).';
    } catch (e) {
      debugPrint("Exception caught in interactWithAi: $e");
      return 'Gagal terhubung ke server AI: Pastikan koneksi internet stabil.';
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
        headers: await getHeaders(),
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
        headers: await getHeaders(),
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

  // ==================== SERVICE Notification ====================
  static Future<Map<String, dynamic>> getWateringSchedule(
    int userPlantId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-plants/watering-schedule/$userPlantId'),
        headers: await getHeaders(),
      );

      final responseData = jsonDecode(response.body);

      // Cek Status Code dan pastikan ada kunci 'data'
      if (response.statusCode == 200 && responseData['status'] == true) {
        if (responseData['data'] != null) {
          return {
            'status': true,
            'data': responseData['data'], // Data aman
          };
        } else {
          return {
            'status': false,
            'message': 'Data jadwal tidak ditemukan di server.',
          };
        }
      } else {
        return {
          'status': false,
          'message': responseData['message'] ?? 'Gagal mengambil jadwal siram.',
        };
      }
    } catch (e) {
      debugPrint("Error API: $e");
      return {'status': false, 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  // ==================== SERVICE UPGRADE PREMIUM ====================
  static Future<Map<String, dynamic>> upgradePremium(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/upgrade-premium'),
        headers: await getHeaders(),
        body: jsonEncode({'user_id': userId}),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'status': true, 'message': responseData['message']};
      } else {
        return {
          'status': false,
          'message': responseData['message'] ?? 'Gagal upgrade.',
        };
      }
    } catch (e) {
      return {'status': false, 'message': 'Terjadi kesalahan jaringan.'};
    }
  }
}
