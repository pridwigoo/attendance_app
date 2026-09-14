import 'dart:convert';

import '../../core/network/api_client.dart';

class AttendanceService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>?> getSchedule() async {
    final response = await _apiClient.get(
      '/attendance/schedule',
      withAuth: true,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }
    return null;
  }

  Future<Map<String, dynamic>> checkIn({
    required int locationId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.post('/attendance/check-in', {
      'location_id': locationId,
      'latitude': latitude,
      'longitude': longitude,
    }, withAuth: true);

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.post('/attendance/check-out', {
      'latitude': latitude,
      'longitude': longitude,
    }, withAuth: true);

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getHistory() async {
    final response = await _apiClient.get(
      '/attendance/history',
      withAuth: true,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['data'] ?? [];
    }
    return [];
  }
}
