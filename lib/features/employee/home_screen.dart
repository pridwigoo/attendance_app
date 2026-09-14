import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text('Selamat Datang, ${user?['name'] ?? 'Employee'}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Email: ${user?['email'] ?? '-'}'),
            Text('ID: ${user?['employee_id'] ?? '-'}'),
            const SizedBox(height: 16),
            Chip(
              label: Text('Status: ${user?['status'] ?? 'ACTIVE'}'),
              backgroundColor: Colors.green.shade100,
            ),
          ],
        ),
      ),
    );
  }
}