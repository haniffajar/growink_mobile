import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/plant_model.dart';

class GrowpediaService {
  static const String baseUrl = '${ApiService.baseUrl}/growpedia';

  /// ==========================
  /// Ambil semua kategori
  /// ==========================
  static Future<List<String>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    }

    throw Exception("Gagal mengambil kategori");
  }

  /// ==========================
  /// Ambil tanaman berdasarkan kategori
  /// ==========================
  static Future<List<Plant>> getPlantsByCategory(String category) async {
    final response = await http.get(
      Uri.parse('$baseUrl/plants/$category'),
      headers: await ApiService.getHeaders(),
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
    final response = await http.get(
      Uri.parse('$baseUrl/detail/$id'),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      return json['data'];
    }

    throw Exception("Gagal mengambil detail tanaman");
  }
}
