import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/utils/location_helper.dart';
import 'attendance_service.dart';

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
  final AttendanceService _attendanceService = AttendanceService();
  int? _selectedLocationId;
  Position? _currentPosition;
  bool _isLoadingGps = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.approvedLocations.isNotEmpty) {
      _selectedLocationId = widget.approvedLocations.first['id'];
    }
    _getGpsLocation();
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

  void _submitAttendance() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat GPS belum didapatkan!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.isCheckIn && _selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi kantor/absensi terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> response;
      if (widget.isCheckIn) {
        response = await _attendanceService.checkIn(
          locationId: _selectedLocationId!,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      } else {
        response = await _attendanceService.checkOut(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      }

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Absensi Berhasil'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Absensi Gagal'),
              backgroundColor: Colors.red,
            ),
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
    final title = widget.isCheckIn ? 'Check-in Absensi' : 'Check-out Absensi';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isCheckIn) ...[
              const Text(
                'Pilih Lokasi Absensi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
            ],

            // Detail GPS Status
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.location_on, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      _currentPosition == null
                          ? 'Mencari Koordinat GPS...'
                          : 'Lat: ${_currentPosition!.latitude}\nLong: ${_currentPosition!.longitude}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    _isLoadingGps
                        ? const CircularProgressIndicator()
                        : OutlinedButton.icon(
                            onPressed: _getGpsLocation,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh GPS'),
                          ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isCheckIn
                          ? Colors.green
                          : Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      widget.isCheckIn
                          ? 'KONFIRMASI CHECK-IN'
                          : 'KONFIRMASI CHECK-OUT',
                      style: const TextStyle(
                        fontSize: 16,
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
