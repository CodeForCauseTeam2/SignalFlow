// Fallback stubs used when 'package:flutter/material.dart' is not available
// Replace this file with the normal import when running in a Flutter project:
// import 'package:flutter/material.dart';

// Minimal stub types so this file can be analyzed/compiled outside a Flutter SDK.
// These are intentionally tiny and should NOT be used in a real Flutter build.
class Widget {
  const Widget();
}

class Key {
  const Key();
}

class BuildContext {}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({this.key});
  final Key? key;
  Widget build(BuildContext context) => throw UnimplementedError();
}

class Scaffold extends Widget {
  final AppBar? appBar;
  final Widget? body;
  const Scaffold({this.appBar, this.body});
}

class AppBar extends Widget {
  final Widget? title;
  const AppBar({this.title});
}

class Center extends Widget {
  final Widget? child;
  const Center({this.child});
}

class Text extends Widget {
  final String data;
  const Text(this.data);
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign to Speech')),
      body: const Center(child: Text('Translating sign language to text...')),
    );
  }
}
