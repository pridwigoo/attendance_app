import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/storage_service.dart';

class ApiClient {
  //emulator
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; 
    //android device
  static const String baseUrl = 'http://192.168.1.3:8000/api/v1'; 
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) async {
    final headers = await _headers(withAuth: withAuth);
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(String endpoint, {bool withAuth = true}) async {
    final headers = await _headers(withAuth: withAuth);
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
}
