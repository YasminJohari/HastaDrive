import 'package:flutter/material.dart';

class HastaHomePage extends StatelessWidget {
  const HastaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasta Home Page'),
      ),
      body: const Center(
        child: Text('Welcome Admin!'),
      ),
    );
  }
}
