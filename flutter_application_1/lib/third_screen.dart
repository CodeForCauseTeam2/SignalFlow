import 'package:flutter/material.dart';

class ThirdScreen extends StatefulWidget {
  const ThirdScreen({super.key});

  @override
  State<ThirdScreen> createState() => _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SwitchListTile(
        title: const Text("Dark Mode"),
        value: darkMode,
        onChanged: (value) {
          setState(() {
            darkMode = value;
          });
        },
      ),
    );
  }
}
