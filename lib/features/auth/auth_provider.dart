import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart' show StorageService;

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<Map<String, dynamic>?>>((
      ref,
    ) {
      return AuthNotifier();
    });

class AuthNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final token = data['data']['token'];
        final user = data['data']['user'];
        await _storage.saveToken(token);
        state = AsyncValue.data(user);
        return true;
      } else {
        state = AsyncValue.error(
          data['message'] ?? 'Login Gagal',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == 'success') {
        state = const AsyncValue.data(null);
        return true;
      } else {
        final errorMsg =
            data['message'] ??
            (data['errors'] != null
                ? data['errors'].toString()
                : 'Registrasi Gagal');
        state = AsyncValue.error(errorMsg, StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout', {}, withAuth: true);
    } catch (_) {}
    await _storage.deleteToken();
    state = const AsyncValue.data(null);
  }
}
