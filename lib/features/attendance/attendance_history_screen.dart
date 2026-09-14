import 'package:flutter/material.dart';

import 'attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() async {
    final list = await _attendanceService.getHistory();
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PRESENT':
        return Colors.green;
      case 'LATE':
        return Colors.orange;
      case 'LEFT_EARLY':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(child: Text('Belum ada riwayat absensi.'))
          : RefreshIndicator(
              onRefresh: () async => _fetchHistory(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final statusColor = _getStatusColor(item['status'] ?? '');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        item['date'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'In: ${item['check_in'] ?? '-'}  |  Out: ${item['check_out'] ?? '-'}',
                          ),
                          if (item['location'] != null)
                            Text(
                              'Lokasi: ${item['location']['name']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          item['status'] ?? 'UNKNOWN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: statusColor,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
