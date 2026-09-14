import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../face/face_register_screen.dart';
import '../location/location_request_screen.dart';
import '../attendance/attendance_action_screen.dart';
import '../attendance/attendance_history_screen.dart';
import '../attendance/attendance_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<dynamic> _myLocations = [];
  Map<String, dynamic>? _schedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final locRes = await ApiClient().get('/locations', withAuth: true);
      final schedData = await _attendanceService.getSchedule();

      List<dynamic> approved = [];
      if (locRes.statusCode == 200) {
        final locData = jsonDecode(locRes.body);
        approved = (locData['data'] as List)
            .where((l) => l['status'] == 'APPROVED')
            .toList();
      }

      setState(() {
        _myLocations = approved;
        _schedule = schedData;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AttendanceHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadDashboardData(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Info
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user?['name'] ?? 'Employee'}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('ID: ${user?['employee_id'] ?? '-'}'),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text('Status: ${user?['status'] ?? 'ACTIVE'}'),
                      backgroundColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jam Kerja Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jadwal Kerja Hari Ini:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _schedule != null
                              ? '${_schedule!['start_time']} - ${_schedule!['end_time']}'
                              : '08:00 - 17:00',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.access_time_filled,
                      size: 36,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Check-in & Check-out Action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _myLocations.isEmpty
                        ? null
                        : () async {
                            final refresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttendanceActionScreen(
                                  isCheckIn: true,
                                  approvedLocations: _myLocations,
                                ),
                              ),
                            );
                            if (refresh == true) _loadDashboardData();
                          },
                    icon: const Icon(Icons.login),
                    label: const Text('CHECK-IN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceActionScreen(
                            isCheckIn: false,
                            approvedLocations: _myLocations,
                          ),
                        ),
                      );
                      if (refresh == true) _loadDashboardData();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('CHECK-OUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            if (_myLocations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  '* Ajukan & minta persetujuan lokasi kantor ke Admin untuk membuka tombol Check-in.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationRequestScreen(),
                  ),
                );
                _loadDashboardData();
              },
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Kelola / Ajukan Lokasi Absensi'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FaceRegisterScreen()),
                );
              },
              icon: const Icon(Icons.face),
              label: const Text('Registrasi / Update Wajah'),
            ),
          ],
        ),
      ),
    );
  }
}
