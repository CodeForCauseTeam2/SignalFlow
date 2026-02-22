import 'dart:convert';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ASLDetectorScreen(),
    );
  }
}

class ASLDetectorScreen extends StatefulWidget {
  const ASLDetectorScreen({super.key});
  @override
  State<ASLDetectorScreen> createState() => _ASLDetectorScreenState();
}

class _ASLDetectorScreenState extends State<ASLDetectorScreen> {
  CameraController? _camController;
  Interpreter? _interpreter;

  List<String> _labels = [];
  String _detected = '—';
  double _confidence = 0.0;
  String _status = '⏳ Loading...';

  bool _isReady = false;
  bool _isProcessing = false;

  // ✅ Throttle inference so UI doesn’t freeze
  int _lastInferMs = 0;
  static const int _inferEveryMs = 150; // ~6–7 FPS

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      setState(() => _status = '⏳ Loading model...');
      await _loadModel();
      debugPrint('✅ _loadModel finished');

      setState(() => _status = '⏳ Initializing camera...');
      await _initCamera();

      setState(() {
        _isReady = true;
        _status = '✅ Model ready';
      });
    } catch (e) {
      setState(() => _status = '❌ Init failed: $e');
    }
  }

  Future<void> _loadModel() async {
    // IMPORTANT:
    // pubspec.yaml must include:
    // flutter:
    //   assets:
    //     - assets/asl_model.tflite
    //     - assets/labels.json
    //
    // And this expects the ASSET KEY (no "assets/"):
    _interpreter = await Interpreter.fromAsset('asl_model.tflite');

    final raw = await rootBundle.loadString('assets/labels.json');
    _labels = List<String>.from(jsonDecode(raw));
    debugPrint('✅ Labels: ${_labels.length}');

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    final inShape = List<int>.from(inputTensor.shape);
    final outShape = List<int>.from(outputTensor.shape);

    debugPrint('MODEL INPUT : shape=$inShape type=${inputTensor.type}');
    debugPrint('MODEL OUTPUT: shape=$outShape type=${outputTensor.type}');

    // Expected from your Colab training:
    // input [1,64,64,3] float32, output [1,29] float32
    if (inShape.length != 4 || inShape[1] != 64 || inShape[2] != 64 || inShape[3] != 3) {
      debugPrint('⚠️ Unexpected input shape. Expected [1,64,64,3], got $inShape');
    }
    if (outShape.length != 2 || outShape[1] != _labels.length) {
      debugPrint('⚠️ Output shape vs labels mismatch. out=$outShape labels=${_labels.length}');
    }
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras available');

    // ✅ Use LOW resolution to reduce CPU work
    // ✅ Try BGRA first (best conversion), fallback to YUV
    CameraController controller;
    try {
      controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      debugPrint('✅ Camera: BGRA8888');
    } catch (_) {
      controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      debugPrint('✅ Camera: YUV420');
    }

    _camController = controller;
    await _camController!.startImageStream(_processFrame);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (!_isReady || _isProcessing || _interpreter == null) return;
    _isProcessing = true;

    // ✅ Throttle inference
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastInferMs < _inferEveryMs) {
      _isProcessing = false;
      return;
    }
    _lastInferMs = now;

    try {
      final input = _buildFloatInput64(image);

      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      _interpreter!.run(input, output);

      final probs = output[0];

      int bestIdx = 0;
      double best = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > best) {
          best = probs[i];
          bestIdx = i;
        }
      }

      setState(() {
        _confidence = best.clamp(0.0, 1.0);

        // ✅ Show label always (debug). Add threshold later if needed.
        _detected = _labels[bestIdx];
      });
    } catch (e) {
      debugPrint('❌ Frame error: $e');
      setState(() => _status = '⚠️ Runtime error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Build [1,64,64,3] float input from camera (center-cropped)
  List<List<List<List<double>>>> _buildFloatInput64(CameraImage image) {
    final crop = _centerCropRect(image.width, image.height, fraction: 0.65);

    final input = List.generate(
      1,
      (_) => List.generate(
        64,
        (_) => List.generate(64, (_) => List.filled(3, 0.0)),
      ),
    );

    if (image.format.group == ImageFormatGroup.bgra8888) {
      _fillFromBGRA(image, input[0], crop);
    } else {
      _fillFromYUV420(image, input[0], crop);
    }
    return input;
  }

  _CropRect _centerCropRect(int srcW, int srcH, {double fraction = 0.65}) {
    final side = (min(srcW, srcH) * fraction).round();
    final left = ((srcW - side) / 2).round();
    final top = ((srcH - side) / 2).round();
    return _CropRect(left: left, top: top, width: side, height: side);
  }

  void _fillFromBGRA(CameraImage image, List<List<List<double>>> out64, _CropRect crop) {
    final bytes = image.planes[0].bytes;
    final rowStride = image.planes[0].bytesPerRow;
    final pixelStride = image.planes[0].bytesPerPixel ?? 4;

    for (int y = 0; y < 64; y++) {
      final srcY = crop.top + ((y / 63.0) * (crop.height - 1)).round();
      for (int x = 0; x < 64; x++) {
        final srcX = crop.left + ((x / 63.0) * (crop.width - 1)).round();

        final idx = srcY * rowStride + srcX * pixelStride;
        final b = bytes[idx + 0];
        final g = bytes[idx + 1];
        final r = bytes[idx + 2];

        out64[y][x][0] = r / 255.0;
        out64[y][x][1] = g / 255.0;
        out64[y][x][2] = b / 255.0;
      }
    }
  }

  void _fillFromYUV420(CameraImage image, List<List<List<double>>> out64, _CropRect crop) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;

    final uRowStride = uPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 2;

    final vRowStride = vPlane.bytesPerRow;
    final vPixelStride = vPlane.bytesPerPixel ?? 2;

    for (int y = 0; y < 64; y++) {
      final srcY = crop.top + ((y / 63.0) * (crop.height - 1)).round();
      for (int x = 0; x < 64; x++) {
        final srcX = crop.left + ((x / 63.0) * (crop.width - 1)).round();

        final yIndex = srcY * yRowStride + srcX * yPixelStride;

        final uvX = srcX ~/ 2;
        final uvY = srcY ~/ 2;

        final uIndex = uvY * uRowStride + uvX * uPixelStride;
        final vIndex = uvY * vRowStride + uvX * vPixelStride;

        final Y = yBytes[yIndex].toDouble();
        final U = uBytes[uIndex].toDouble() - 128.0;
        final V = vBytes[vIndex].toDouble() - 128.0;

        double r = Y + 1.402 * V;
        double g = Y - 0.344136 * U - 0.714136 * V;
        double b = Y + 1.772 * U;

        r = r.clamp(0.0, 255.0);
        g = g.clamp(0.0, 255.0);
        b = b.clamp(0.0, 255.0);

        out64[y][x][0] = r / 255.0;
        out64[y][x][1] = g / 255.0;
        out64[y][x][2] = b / 255.0;
      }
    }
  }

  @override
  void dispose() {
    _camController?.stopImageStream();
    _camController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('ASL Detector', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _camController?.value.isInitialized == true
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_camController!),
                      Center(
                        child: Container(
                          width: 200,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.purpleAccent, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('Place hand here',
                                style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.purple)),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Text('Detected Sign', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  _detected,
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: LinearProgressIndicator(
                    value: _confidence,
                    color: Colors.purpleAccent,
                    backgroundColor: Colors.grey,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(_confidence * 100).toStringAsFixed(0)}% confidence',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropRect {
  final int left, top, width, height;
  _CropRect({required this.left, required this.top, required this.width, required this.height});
}