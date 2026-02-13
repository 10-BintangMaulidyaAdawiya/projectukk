import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  final String nama;

  const DashboardScreen({
    super.key,
    required this.role,
    required this.nama,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Text(
          'Halo $nama\nRole: $role',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
