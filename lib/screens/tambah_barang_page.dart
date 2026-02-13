import 'package:flutter/material.dart';

class TambahBarangPage extends StatefulWidget {
  const TambahBarangPage({super.key});

  @override
  State<TambahBarangPage> createState() => _TambahBarangPageState();
}

class _TambahBarangPageState extends State<TambahBarangPage> {
  final merkC = TextEditingController();
  final spekC = TextEditingController();

  final List<String> kategoriList = const [
    "Laptop Pelajar",
    "Laptop Kreator",
    "Laptop Gaming", //tfgchgjny
  ];

  String? selectedKategori;

  @override
  void dispose() {
    merkC.dispose();
    spekC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              // ===== Top bar (Back + icon kecil kanan) =====
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff2C3E75)),
                  ),
                  const Spacer(),
                  const Icon(Icons.search, color: Color(0xff2C3E75), size: 18),
                ],
              ),

              const SizedBox(height: 18),

              // ===== Box upload gambar =====
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xff2C3E75),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(blurRadius: 12, offset: Offset(0, 6), color: Color(0x22000000)),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Icon(Icons.image, color: Colors.white, size: 44),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(Icons.add_box, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ===== Input Merk =====
              _inputField(
                controller: merkC,
                hint: "Merk",
              ),
              const SizedBox(height: 12),

              // ===== Input Spesifikasi =====
              _inputField(
                controller: spekC,
                hint: "Spesifikasi",
              ),
              const SizedBox(height: 12),

              // ===== Dropdown Kategori =====
              _dropdownKategori(),

              const Spacer(),

              // ===== Button Batal + Simpan =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _btnSecondary(
                    text: "Batal",
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 14),
                  _btnPrimary(
                    text: "Simpan",
                    onTap: () {
                      // UI dulu: hanya tampilkan snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Simpan (UI dulu - belum ke database)")),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x22000000)),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _dropdownKategori() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x22000000)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedKategori,
          hint: const Text("Kategori", style: TextStyle(color: Colors.grey)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: kategoriList.map((k) {
            return DropdownMenuItem<String>(
              value: k,
              child: Text(k),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => selectedKategori = val);
          },
        ),
      ),
    );
  }

  Widget _btnPrimary({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xff2C3E75),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x22000000)),
          ],
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _btnSecondary({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x22000000)),
          ],
        ),
        child: Text(text, style: const TextStyle(color: Color(0xff2C3E75), fontWeight: FontWeight.bold)),
      ),
    );
  }
}
