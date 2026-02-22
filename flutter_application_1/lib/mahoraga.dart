import 'package:flutter/material.dart';
import 'third_screen.dart';

//main parent of the app
void main() {
  runApp(const Schwer());
}

// root parent (MAIN APP)
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 33, 103, 243),
          brightness: Brightness.dark,
        ),
        //determines colors tones
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
        ),
      ),
      // triggers the first screen to be the welcome screen
      home: const FirstScreen(),
    );
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signal Flow')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              // this button is the one that will take us to the second screen!
              onPressed: () {
                Navigator.push(
                  //Second screen navigation:
                  context,
                  MaterialPageRoute(builder: (context) => const SecondScreen()),
                );
              },
              child: const Text('Settings'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  //Third screen navigation:
                  context,
                  MaterialPageRoute(builder: (context) => const ThirdScreen()),
                );
              },
              child: const Text('Previous Conversations'),
            ),
          ],
        ),
      ),
    );
  }
}

// Functionaly of second and third screen is not yet implemented, but we can navigate to them and see the text on the screen.
class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Modify features and settings here...')),
    );
  }
}

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previous Conversations')),
      body: const Center(
        child: Text('Starting typing to translate text to sign language...'),
      ),
    );
  }
}
