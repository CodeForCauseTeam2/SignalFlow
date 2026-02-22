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

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text to Sign')),
      body: const Center(child: Text('Starting typing to translate text to sign language...')),
    );
  }
}
