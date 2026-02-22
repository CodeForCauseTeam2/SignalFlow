import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign to Speech')),

      body: Align(
        alignment: Alignment.bottomCenter, 
        child: Text('Translating sign language to text'),
      ),
    );
  }
}
