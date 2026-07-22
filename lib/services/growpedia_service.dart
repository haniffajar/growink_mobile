import 'dart:convert';
// import 'package:http/http.dart' as http; // Hapus atau comment ini karena sudah tidak dipakai
import 'api_service.dart';
import 'api_client.dart'; // Tambahkan import ApiClient
import '../models/plant_model.dart';

class GrowpediaService {
  static const String baseUrl = '${ApiService.baseUrl}/growpedia';

  /// ==========================
  /// Ambil semua kategori
  /// ==========================
  static Future<List<String>> getCategories() async {
    // Gunakan ApiClient.get agar header & refresh token otomatis tertangani
    final response = await ApiClient.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    }

    throw Exception("Gagal mengambil kategori");
  }

  /// ==========================
  /// Ambil tanaman berdasarkan kategori
  /// ==========================
  static Future<List<Plant>> getPlantsByCategory(String category) async {
    // Gunakan ApiClient.get
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/plants/$category'),
    );

    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return List<Plant>.from(list.map((e) => Plant.fromJson(e)));
    }

    throw Exception("Gagal mengambil tanaman");
  }

  /// ==========================
  /// Detail tanaman
  /// ==========================
  static Future<Map<String, dynamic>> getPlantDetail(int id) async {
    // Gunakan ApiClient.get
    final response = await ApiClient.get(Uri.parse('$baseUrl/detail/$id'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }

    throw Exception("Gagal mengambil detail tanaman");
  }
}
