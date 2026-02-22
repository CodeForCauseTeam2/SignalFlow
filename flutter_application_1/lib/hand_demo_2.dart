import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'ai_service.dart';

@JS('mpHandInit')
external JSPromise<JSBoolean> mpHandInit();

@JS('mpHandStart')
external JSPromise<JSBoolean> mpHandStart();

@JS('mpHandStop')
external JSBoolean mpHandStop();

@JS('mpHandDetectOnce')
external JSString? mpHandDetectOnce();

void main() {
  runApp(const MaterialApp(home: HandDemo2()));
}

class HandDemo2 extends StatefulWidget {
  const HandDemo2({super.key});
  @override
  State<HandDemo2> createState() => _HandDemo2State();
}

class _HandDemo2State extends State<HandDemo2> {
  Timer? _timer;
  String _status = 'Idle';
  String _gesture = "—";
  List<Offset> _points = const [];

  // Live sentence building (while running)
  final List<String> _currentSentence = [];

  // Frozen/saved sentence (when Stop is pressed)
  List<String> _savedSentence = [];
  String _savedText = "";

  // AI output
  String _aiResult = "";
  bool _sending = false;

  // Prevent spamming: only add when gesture changes + cooldown
  String _lastAdded = "";
  DateTime _lastAddTime = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _addCooldown = const Duration(milliseconds: 700);

  Future<void> _start() async {
    setState(() => _status = 'Initializing…');
    await mpHandInit().toDart;
    await mpHandStart().toDart;

    setState(() {
      _status = 'Running';
      _aiResult = "";
      _currentSentence.clear();
      _lastAdded = "";
      _lastAddTime = DateTime.fromMillisecondsSinceEpoch(0);
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final jsStr = mpHandDetectOnce();
      if (jsStr == null) return;

      final decoded = jsonDecode(jsStr.toDart) as Map<String, dynamic>;
      final landmarks = (decoded['landmarks'] as List).isNotEmpty
          ? (decoded['landmarks'] as List).first as List
          : const <dynamic>[];
      final gesture = (decoded['gesture'] as String?) ?? "UNKNOWN";

      final pts = <Offset>[];
      for (final lm in landmarks) {
        final x = (lm['x'] as num).toDouble(); // normalized 0-1
        final y = (lm['y'] as num).toDouble();
        pts.add(Offset(x, y));
      }

      // Auto-add gesture to live sentence (change + cooldown)
      final now = DateTime.now();
      final canAdd = gesture != "UNKNOWN" &&
          gesture != "—" &&
          gesture.trim().isNotEmpty &&
          gesture != _lastAdded &&
          now.difference(_lastAddTime) > _addCooldown;

      if (canAdd) {
        _lastAdded = gesture;
        _lastAddTime = now;
        _currentSentence.add(gesture);
      }

      setState(() {
        _points = pts;
        _gesture = gesture;
        _status = pts.isEmpty
            ? 'Running (no hand)'
            : 'Hand detected (${pts.length} points)';
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    mpHandStop();

    setState(() {
      _points = const [];
      _status = 'Stopped';

      // Freeze/save the statement when stopping
      _savedSentence = List<String>.from(_currentSentence);
      _savedText = _savedSentence.join(" ");
    });
  }

  void _clearSaved() {
    setState(() {
      _savedSentence = [];
      _savedText = "";
      _aiResult = "";
    });
  }

  Future<void> _sendSavedToAI() async {
    if (_savedSentence.isEmpty) {
      setState(() => _aiResult = "No saved statement. Press Stop first.");
      return;
    }

    setState(() => _sending = true);
    try {
      final result = await AIService.sendToAI(_savedSentence);
      setState(() => _aiResult = result);
    } catch (e) {
      setState(() => _aiResult = "Error sending to AI: $e");
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign To Text')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_status),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current: $_gesture",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Live: ${_currentSentence.join(" ")}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  "Saved: $_savedText",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_aiResult.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    "AI: $_aiResult",
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _start,
                  child: const Text('Start webcam'),
                ),
                ElevatedButton(
                  onPressed: _stop,
                  child: const Text('Stop (Save)'),
                ),
                ElevatedButton(
                  onPressed: _sending ? null : _sendSavedToAI,
                  child: Text(_sending ? "Sending..." : "Send Saved to AI"),
                ),
                OutlinedButton(
                  onPressed: _clearSaved,
                  child: const Text('Clear Saved'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
      canvas.drawCircle(
        Offset(pt.dx * size.width, pt.dy * size.height),
        4,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      oldDelegate.points != points;
}