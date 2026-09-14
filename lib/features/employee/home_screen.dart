import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../location/location_request_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<dynamic> _myLocations = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _fetchMyLocations();
  }

  Future<void> _fetchMyLocations() async {
    if (!mounted) return;
    
    setState(() => _isLoadingLocations = true);

    try {
      final response = await ApiClient().get('/locations', withAuth: true);
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _myLocations = data['data'] ?? [];
          _isLoadingLocations = false;
        });
      } else {
        setState(() => _isLoadingLocations = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green.shade100;
      case 'PENDING':
        return Colors.amber.shade100;
      case 'REJECTED':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Employee'),
        actions: [
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
        onRefresh: _fetchMyLocations,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Card Profil Singkat
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user?['name'] ?? 'Employee'}!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('ID: ${user?['employee_id'] ?? '-'} | Email: ${user?['email'] ?? '-'}'),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text('Status Akun: ${user?['status'] ?? 'ACTIVE'}'),
                      backgroundColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Ajukan Lokasi
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationRequestScreen()),
                );
                // Proteksi mounted setelah berpindah halaman
                if (mounted) {
                  _fetchMyLocations();
                }
              },
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Ajukan Lokasi Absensi Baru'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
            ),
            const SizedBox(height: 24),

            // Daftar Lokasi Saya
            const Text(
              'Daftar Lokasi Terdaftar:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_isLoadingLocations)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_myLocations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Belum ada lokasi yang diajukan.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._myLocations.map((loc) {
                final status = (loc['status'] ?? 'PENDING').toString();
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(loc['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${loc['address'] ?? '-'}\nRadius: ${loc['radius_meters'] ?? 0}m'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(status, style: const TextStyle(fontSize: 10)),
                      backgroundColor: _getStatusColor(status),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}