import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'pengembalian_screen.dart';
import 'peminjaman_catalog_screen.dart';

class MainMenuPeminjam extends StatefulWidget {
  const MainMenuPeminjam({super.key});

  @override
  State<MainMenuPeminjam> createState() => _MainMenuPeminjamState();
}

class _MainMenuPeminjamState extends State<MainMenuPeminjam> {
  int _index = 0;

  final List<Widget> _pages = const [
    PeminjamanCatalogScreen(), // ✅ Beranda = Catalog
    PengembalianScreen(),      // ✅ Pengembalian
    PeminjamAkunPage(),        // ✅ Akun (profile + logout)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xff2C3E75),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: "Pengembalian",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
        ],
      ),
    );
  }
}

// ===== Akun Peminjam (Profile + Logout) =====
class PeminjamAkunPage extends StatefulWidget {
  const PeminjamAkunPage({super.key});

  @override
  State<PeminjamAkunPage> createState() => _PeminjamAkunPageState();
}

class _PeminjamAkunPageState extends State<PeminjamAkunPage> {
  final _svc = SupabaseService();
  bool _loading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final p = await _svc.getUserProfile(user.id);
      if (!mounted) return;
      setState(() => _profile = p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal load profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _svc.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (_profile?['nama'] ?? 'Peminjam').toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(user?.email ?? '-'),
                      const SizedBox(height: 6),
                      Text(
                        'Role: ${(_profile?['role'] ?? '-').toString()}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Status: ${(_profile?['status'] ?? '-').toString()}',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2C3E75),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
