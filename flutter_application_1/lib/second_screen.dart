import 'package:flutter/material.dart';
import 'third_screen.dart';
import 'second_screen.dart'; // if you have it
import 'fourth_screen.dart'; // if you have it

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildMenuButton(
              context,
              "Settings",
              Icons.settings,
              const ThirdScreen(),
            ),
            const SizedBox(height: 20),
            buildMenuButton(
              context,
              "Previous Conversations",
              Icons.history,
              const FourthScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    Widget screen,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }
}
