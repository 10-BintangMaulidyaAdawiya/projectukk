import 'package:flutter/material.dart';

class PetugasDashboardUI extends StatelessWidget {
  const PetugasDashboardUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      body: Center(
        child: Text(
          "Dashboard Petugas",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff2C3E75),
          ),
        ),
      ),
    );
  }
}// TODO Implement this library.
