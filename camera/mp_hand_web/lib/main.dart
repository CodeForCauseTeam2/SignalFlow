import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';

@JS('mpHandInit')
external JSPromise<JSBoolean> mpHandInit();

@JS('mpHandStart')
external JSPromise<JSBoolean> mpHandStart();

@JS('mpHandStop')
external JSBoolean mpHandStop();

@JS('mpHandDetectOnce')
external JSString? mpHandDetectOnce();

void main() {
  runApp(const MaterialApp(home: HandDemo()));
}

class HandDemo extends StatefulWidget {
  const HandDemo({super.key});
  @override
  State<HandDemo> createState() => _HandDemoState();
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  final List<Offset> points; // normalized 0..1
  _HandPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final pt in points) {
      canvas.drawCircle(Offset(pt.dx * size.width, pt.dy * size.height), 4, p);
    }
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      oldDelegate.points != points;
}
