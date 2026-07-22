import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  // Ganti baseUrl menggunakan URL hosting Anda
  static const String baseUrl = 'https://growink.app/backend/api/v1';

  Future<String?> createInvoice(String userId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/payment/invoice',
        ), // Akan menjadi: .../api/v1/payment/invoice
        body: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['invoice_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
