import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Container(
        
        padding: const EdgeInsets.all(16),
        color: const Color.fromARGB(255, 116, 193, 255),
        child: const Text('Sign to Speech')
        ),
        ),
      
      body: const Center(child: Text('Translating sign language to text...')),
    );
  }
}
