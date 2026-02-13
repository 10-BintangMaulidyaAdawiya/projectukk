import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class AdminPetugasPage extends StatefulWidget {
  const AdminPetugasPage({super.key});

  @override
  State<AdminPetugasPage> createState() => _AdminPetugasPageState();
}

class _AdminPetugasPageState extends State<AdminPetugasPage> {
  final _svc = SupabaseService();

  Future<List<Map<String, dynamic>>> _load() => _svc.adminListPetugas();

  String _pickPhone(Map<String, dynamic> row) {
    final keys = ['telepon', 'nomor_telepon', 'no_telp', 'no_hp', 'phone'];
    for (final k in keys) {
      final v = row[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '-';
  }

  Future<void> _showSendMessageSheet({
    required String petugasUserId,
    required String nama,
  }) async {
    final ctrl = TextEditingController();
    var isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kirim Pesan ke $nama',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            final text = ctrl.text.trim();
                            if (text.isEmpty) return;
                            setLocal(() => isSending = true);
                            try {
                              await _svc.adminKirimPesanKePetugas(
                                petugasUserId: petugasUserId,
                                isiPesan: text,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pesan terkirim')),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal kirim pesan: $e')),
                              );
                              if (ctx.mounted) setLocal(() => isSending = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2C3E75),
                      foregroundColor: Colors.white,
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Kirim'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        foregroundColor: Colors.white,
        title: const Text('Data Petugas'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('Belum ada data petugas.'));
          }

          final onlineCount = rows.where((r) {
            final status = (r['status'] ?? 'offline').toString().toLowerCase();
            return status == 'online';
          }).length;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total petugas: ${rows.length} | Online: $onlineCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff2C3E75),
                      ),
                    ),
                  );
                }

                final r = rows[i - 1];
                final userId = (r['user_id'] ?? '').toString();
                final nama = (r['nama'] ?? 'Petugas').toString();
                final email = (r['email'] ?? 'bintang@gmail.com').toString();
                final phone = _pickPhone(r);
                final status = (r['status'] ?? 'offline').toString();
                final isOnline = status.toLowerCase() == 'online';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(isOnline ? 'Online' : 'Offline'),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              backgroundColor: isOnline
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.12),
                              labelStyle: TextStyle(
                                color: isOnline ? Colors.green[800] : Colors.red[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Email: $email'),
                        const Text('Password: 123456'),
                        Text('No. Telepon: $phone'),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: userId.isEmpty
                                ? null
                                : () => _showSendMessageSheet(
                                      petugasUserId: userId,
                                      nama: nama,
                                    ),
                            icon: const Icon(Icons.message_outlined),
                            label: const Text('Kirim Pesan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2C3E75),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
