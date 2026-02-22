import 'package:flutter/material.dart';

class FourthScreen extends StatelessWidget {
  const FourthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fourth Screen")),
      body: const Center(
        child: Text(
          "This page is currently empty.",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
