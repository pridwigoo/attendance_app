import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/location_helper.dart';

class AttendanceActionScreen extends StatefulWidget {
  final bool isCheckIn;
  final List<dynamic> approvedLocations;

  const AttendanceActionScreen({
    super.key,
    required this.isCheckIn,
    required this.approvedLocations,
  });

  @override
  State<AttendanceActionScreen> createState() => _AttendanceActionScreenState();
}

class _AttendanceActionScreenState extends State<AttendanceActionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _capturedFace;
  Position? _currentPosition;

  int? _selectedLocationId;
  bool _isCameraInitialized = false;
  bool _isLoadingGps = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.approvedLocations.isNotEmpty) {
      _selectedLocationId = widget.approvedLocations.first['id'];
    }
    _initGpsAndCamera();
  }

  void _initGpsAndCamera() async {
    _getGpsLocation();
    if (widget.isCheckIn) {
      _initCamera();
    }
  }

  void _initCamera() async {
    try {
      _cameras = await availableCameras();
      final frontCamera = _cameras?.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      if (frontCamera != null) {
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (_) {}
  }

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

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _submitIntegratedCheckIn() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat GPS belum didapatkan!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.isCheckIn) {
      if (_selectedLocationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih lokasi absensi terlebih dahulu!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Ambil foto wajah jika belum diambil
      if (_capturedFace == null) {
        if (_cameraController != null &&
            _cameraController!.value.isInitialized) {
          _capturedFace = await _cameraController!.takePicture();
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamera belum siap.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await StorageService().getToken();

      if (widget.isCheckIn) {
        final uri = Uri.parse('${ApiClient.baseUrl}/attendance/check-in');
        final request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..headers['Accept'] = 'application/json'
          ..fields['location_id'] = _selectedLocationId.toString()
          ..fields['latitude'] = _currentPosition!.latitude.toString()
          ..fields['longitude'] = _currentPosition!.longitude.toString()
          ..files.add(
            await http.MultipartFile.fromPath(
              'face_image',
              _capturedFace!.path,
            ),
          );

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        final data = jsonDecode(response.body);

        setState(() => _isSubmitting = false);
        _handleResultResponse(response.statusCode == 200, data['message']);
      } else {
        final response = await ApiClient().post('/attendance/check-out', {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        }, withAuth: true);

        final data = jsonDecode(response.body);
        setState(() => _isSubmitting = false);
        _handleResultResponse(response.statusCode == 200, data['message']);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _handleResultResponse(bool isSuccess, String? message) {
    if (mounted) {
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Absensi Berhasil'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Absensi Gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCheckIn
              ? 'Check-in (GPS + Face Verification)'
              : 'Check-out Absensi',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.isCheckIn) ...[
              DropdownButtonFormField<int>(
                value: _selectedLocationId,
                items: widget.approvedLocations.map<DropdownMenuItem<int>>((
                  loc,
                ) {
                  return DropdownMenuItem<int>(
                    value: loc['id'],
                    child: Text('${loc['name']} (${loc['radius_meters']}m)'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedLocationId = val),
                decoration: const InputDecoration(
                  labelText: 'Lokasi Kantor Approved',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _capturedFace != null
                      ? Image.file(File(_capturedFace!.path), fit: BoxFit.cover)
                      : _isCameraInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              const SizedBox(height: 8),
              if (_capturedFace != null)
                TextButton.icon(
                  onPressed: () => setState(() => _capturedFace = null),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ambil Ulang Foto Wajah'),
                ),
              const SizedBox(height: 12),
            ],

            // GPS Info
            Card(
              child: ListTile(
                leading: const Icon(Icons.gps_fixed, color: Colors.blue),
                title: Text(
                  _currentPosition == null
                      ? 'Mencari Lokasi GPS...'
                      : 'Lat: ${_currentPosition!.latitude}, Long: ${_currentPosition!.longitude}',
                ),
                trailing: _isLoadingGps
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _getGpsLocation,
                      ),
              ),
            ),
            const SizedBox(height: 24),

            _isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitIntegratedCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isCheckIn
                          ? Colors.green
                          : Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      widget.isCheckIn
                          ? 'PROSES CHECK-IN & VERIFIKASI WAJAH'
                          : 'KONFIRMASI CHECK-OUT',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
