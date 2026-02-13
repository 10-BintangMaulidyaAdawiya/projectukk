import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'login_screen.dart';

// ✅ Menu sesuai role
import 'main_menu_admin.dart';
import 'main_menu_petugas.dart';
import 'main_menu_peminjam.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _svc = SupabaseService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeByRole());
  }

  Future<void> _routeByRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      // ✅ kalau belum login -> ke login
      if (user == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      // ✅ ambil profile (role & status) dari table users_profile
      final profile = await _svc.getUserProfile(user.id);

      final role = (profile?['role'] ?? '').toString().toLowerCase();
      final status = (profile?['status'] ?? '').toString().toLowerCase();

      if (!mounted) return;

      // ✅ blokir kalau akun tidak aktif
      if (status != 'aktif') {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun tidak aktif. Hubungi admin.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      // ✅ route by role
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuAdmin()),
        );
      } else if (role == 'petugas') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuPetugas()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuPeminjam()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal cek role: $e')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : const Text('Redirecting...'),
      ),
    );
  }
}
