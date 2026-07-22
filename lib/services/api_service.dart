// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl =
      'https://growink.app/backend/api/v1'; // Sesuaikan IP Anda

  static Future<Map<String, dynamic>> scanQRCode(
    String qrCode,
    String? userId,
  ) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/scan'),
      body: jsonEncode({'qr_code': qrCode, 'user_id': userId ?? ''}),
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
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/claim-plant'),
        body: jsonEncode({
          'qr_code': qrCode,
          'verif_code': verifCode,
          'user_id': userId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': true,
          'message': responseData['message'] ?? 'Berhasil klaim tanaman.',
          'is_premium_bonus': responseData['is_premium_bonus'] ?? false,
        };
      } else if (response.statusCode == 403 &&
          responseData['is_limit_reached'] == true) {
        return {
          'status': false,
          'is_limit_reached': true,
          'message': responseData['message'] ?? 'Limit kebun penuh!',
        };
      } else {
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
      String token = await AuthService.getAccessToken() ?? '';

      // Helper function untuk MultipartRequest agar mudah diulang
      Future<http.StreamedResponse> sendRequest(String currentToken) async {
        var uri = Uri.parse('$baseUrl/user-plants/update-profile/$plantId');
        var request = http.MultipartRequest('POST', uri);

        request.headers.addAll({
          'Authorization': 'Bearer $currentToken',
          'Accept': 'application/json',
        });

        request.fields['custom_name'] = customName;
        request.fields['location'] = location;

        if (imageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          );
        }
        return await request.send();
      }

      var streamedResponse = await sendRequest(token);

      // Jika token mati (401), auto-refresh dan jalankan ulang multipart-nya
      if (streamedResponse.statusCode == 401) {
        bool isRefreshed = await AuthService.refreshToken();
        if (isRefreshed) {
          token = await AuthService.getAccessToken() ?? '';
          streamedResponse = await sendRequest(token);
        }
      }

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['image_path'];
      }

      throw Exception(
        jsonDecode(response.body)['message'] ??
            'Gagal memperbarui profil tanaman.',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<bool> recordActivity(
    String plantId,
    String activity, {
    required String notes,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/activities'),
      body: jsonEncode({
        'plant_id': plantId,
        'activity_type': activity,
        'notes': notes,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<dynamic>> getPlantHistory(String plantId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/activities/$plantId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> fetchMyPlants(String userId) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/user-plants?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? [];
    }
    throw Exception('Gagal memuat tanaman Anda');
  }

  static Future<String> interactWithAi({
    required String plantName,
    required String prompt,
    required List<Map<String, String>> history,
    String? imageBase64,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final cleanHistory = history.map((e) {
        String text = e['text'] ?? '';
        text = text.replaceAll(RegExp(r'📷 \[.*?\]'), '').trim();
        return {'role': e['role'], 'text': text};
      }).toList();

      final response = await ApiClient.post(
        Uri.parse('$baseUrl/ai/interact'),
        body: jsonEncode({
          'plant_name': plantName,
          'prompt': prompt,
          'history': cleanHistory,
          'image_base64': imageBase64,
          'mime_type': mimeType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? 'Tidak ada respons dari Pakar AI.';
      }

      if (response.statusCode == 500) {
        return 'Server sedang sibuk. Silakan coba beberapa saat lagi.';
      }

      return 'Gagal memproses data AI (${response.statusCode}).';
    } catch (e) {
      return 'Gagal terhubung ke server AI.';
    }
  }

  static Future<bool> saveRecommendationToDb({
    required String plantId,
    required String jenis,
    required String detail,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/plants/recommendation'),
        body: jsonEncode({
          'plant_id': plantId,
          'type': jenis,
          'detail': detail,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getAiRecommendations(String plantId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/plants/recommendation/$plantId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getWateringSchedule(
    int userPlantId,
  ) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/user-plants/watering-schedule/$userPlantId'),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['status'] == true) {
        return {'status': true, 'data': responseData['data']};
      } else {
        return {
          'status': false,
          'message': responseData['message'] ?? 'Gagal mengambil jadwal.',
        };
      }
    } catch (e) {
      return {'status': false, 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  static Future<Map<String, dynamic>> upgradePremium(String userId) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/upgrade-premium'),
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

  static Future<String?> createInvoice(String userId) async {
    try {
      // Create Invoice tidak menggunakan header JSON/Token standar,
      // jadi tetap menggunakan package HTTP langsung
      final response = await http.post(
        Uri.parse('$baseUrl/payment/invoice'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'user_id': userId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['invoice_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> checkUserPremium(String userId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/profile?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']['is_premium'] == 1 ||
            data['data']['is_premium'] == true) {
          return {
            'isPremium': true,
            'message': 'Pembayaran berhasil dikonfirmasi!',
          };
        } else {
          return {'isPremium': false, 'message': 'Status belum Premium.'};
        }
      }
      return {
        'isPremium': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {'isPremium': false, 'message': 'Gagal terhubung ke server.'};
    }
  }
}
