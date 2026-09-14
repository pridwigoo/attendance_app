import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Gunakan 10.0.2.2 jika menggunakan Emulator Android, 
  // atau IP lokal komputer (misal 192.168.x.x) jika menggunakan HP fisik.
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health-check'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}