import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient {
  // Secara otomatis mengambil header dan menyisipkan Access Token
  static Future<Map<String, String>> getHeaders() async {
    final token = await AuthService.getAccessToken() ?? '';
    return {
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Wrapper untuk HTTP GET
  static Future<http.Response> get(Uri url) async {
    var response = await http.get(url, headers: await getHeaders());

    // Jika token kedaluwarsa
    if (response.statusCode == 401) {
      bool isRefreshed = await AuthService.refreshToken();
      if (isRefreshed) {
        // Ulangi request dengan token baru
        response = await http.get(url, headers: await getHeaders());
      }
    }
    return response;
  }

  // Wrapper untuk HTTP POST
  static Future<http.Response> post(
    Uri url, {
    Object? body,
    Map<String, String>? customHeaders,
  }) async {
    var headers = customHeaders ?? await getHeaders();
    var response = await http.post(url, headers: headers, body: body);

    // Jika token kedaluwarsa
    if (response.statusCode == 401) {
      bool isRefreshed = await AuthService.refreshToken();
      if (isRefreshed) {
        // Update header dengan token baru dan ulangi request
        headers = customHeaders ?? await getHeaders();
        response = await http.post(url, headers: headers, body: body);
      }
    }
    return response;
  }
}
