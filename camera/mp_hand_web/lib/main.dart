import 'package:flutter/material.dart';
import 'hand_demo.dart';
void main() {
  runApp(const MainApp());
}

class _HandDemoState extends State<HandDemo> {
  Timer? _timer;
  String _status = 'Idle';
  String _gesture = "—";
  List<Offset> _points = const [];

  Future<void> _start() async {
    setState(() => _status = 'Initializing…');
    await mpHandInit().toDart;
    await mpHandStart().toDart;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final jsStr = mpHandDetectOnce();
      if (jsStr == null) return;

      final decoded = jsonDecode(jsStr.toDart) as Map<String, dynamic>;
      final landmarks =
          (decoded['landmarks'] as List).first as List; // first hand only
      final gesture = (decoded['gesture'] as String?) ?? "UNKNOWN";

      final pts = <Offset>[];
      for (final lm in landmarks) {
        final x = (lm['x'] as num).toDouble(); // normalized 0..1
        final y = (lm['y'] as num).toDouble();
        pts.add(Offset(x, y));
      }

      setState(() {
        _points = pts;
        _gesture = gesture;
        _status = 'Hand detected (${pts.length} points)';
      });
    });

    setState(() => _status = 'Running');
  }

  void _stop() {
    _timer?.cancel();
    mpHandStop();
    setState(() {
      _points = const [];
      _status = 'Stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: const FirstScreen(),
    );
  }
}

/// =====================
/// FIRST SCREEN (WELCOME)
/// =====================
class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  //use of new tools

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MediaPipe Hand Tracking (Web)')),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(_status)),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Gesture: $_gesture",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                return CustomPaint(
                  size: Size(c.maxWidth, c.maxHeight),
                  painter: _HandPainter(_points),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _start,
                child: const Text('Start webcam'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _stop, child: const Text('Stop')),
            ],
          ),
        ),
      ),
    );
  }
}

/// =====================
/// SECOND SCREEN (OPTIONS)
/// =====================
class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Mode"),
        backgroundColor: const Color(0xFF6A5AE0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customButton(context, "Sign to Text", const HandDemo()),
            const SizedBox(height: 20),
            customButton(context, "Text to Sign", const FourthScreen()),
          ],
        ),
      ),
    );
  }

  Widget customButton(BuildContext context, String text, Widget screen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8E7CFF),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// =====================
/// THIRD SCREEN
/// =====================
class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Sign to Text Screen", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

/// =====================
/// FOURTH SCREEN
/// =====================
class FourthScreen extends StatelessWidget {
  const FourthScreen({super.key});

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      oldDelegate.points != points;
}
