import 'package:flutter/material.dart';

void main() {
  runApp(const Schwer());
}

class Schwer extends StatelessWidget {
  const Schwer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color.fromARGB(255, 116, 193, 255),
            ),  
            child: const Text('Signal Flow',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
