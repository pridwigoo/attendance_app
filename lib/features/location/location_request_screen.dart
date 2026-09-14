import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/location_helper.dart';

class LocationRequestScreen extends StatefulWidget {
  const LocationRequestScreen({super.key});

  @override
  State<LocationRequestScreen> createState() => _LocationRequestScreenState();
}

class _LocationRequestScreenState extends State<LocationRequestScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  Position? _currentPosition;
  bool _isLoadingGps = false;
  bool _isSubmitting = false;

  void _getGpsLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      final pos = await LocationHelper.getCurrentLocation();
      setState(() {
        _currentPosition = pos;
        _isLoadingGps = false;
      });
    } catch (e) {
      setState(() => _isLoadingGps = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submitLocation() async {
    if (_currentPosition == null || _nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi form dan ambil koordinat GPS!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiClient().post('/locations/request', {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      }, withAuth: true);

      final data = jsonDecode(response.body);

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengajuan lokasi berhasil dikirim!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal mengajukan lokasi'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Lokasi Absensi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama Lokasi (misal: Kantor Pusat)')),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Alamat Lengkap')),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(_currentPosition == null
                        ? 'Koordinat GPS Belum Diambil'
                        : 'Lat: ${_currentPosition!.latitude}\nLong: ${_currentPosition!.longitude}'),
                    const SizedBox(height: 10),
                    _isLoadingGps
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _getGpsLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Ambil Koordinat Saat Ini'),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitLocation,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: const Text('Kirim Pengajuan Lokasi'),
                  ),
          ],
        ),
      ),
    );
  }
}