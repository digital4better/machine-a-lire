import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';
import 'package:malo/opencv.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/narrator.dart';

class Quad {
  Point topLeft;
  Point topRight;
  Point bottomLeft;
  Point bottomRight;
  Quad(this.topLeft, this.topRight, this.bottomRight, this.bottomLeft);

  static Quad from(Detection d) {
    Point p1 = Point(d.x1, d.y1);
    Point p2 = Point(d.x2, d.y2);
    Point p3 = Point(d.x3, d.y3);
    Point p4 = Point(d.x4, d.y4);
    return Quad(p1, p2, p3, p4);
  }
}

class QuadPainter extends CustomPainter {

  QuadPainter({
    this.quad
  });

  Quad? quad;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset(0, 0) & size, Paint()..color = Color.fromARGB(200, 0, 0, 0));
    if (this.quad != null) {
      final path = Path()
        ..moveTo(this.quad!.topLeft.x * size.width, this.quad!.topLeft.y * size.height)
        ..lineTo(this.quad!.topRight.x * size.width, this.quad!.topRight.y * size.height)
        ..lineTo(this.quad!.bottomRight.x * size.width, this.quad!.bottomRight.y * size.height)
        ..lineTo(this.quad!.bottomLeft.x * size.width, this.quad!.bottomLeft.y * size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = Color.fromARGB(255, 255, 255, 255));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Vision extends StatefulWidget {

  @override
  VisionState createState() => VisionState();
}

class VisionState extends State<Vision> {
  late CameraDescription _camera;
  late CameraController _controller;

  bool _isReady = false;
  bool _isDetecting = false;

  List<Quad> detections = [];
  Quad? quad;

  @override
  void initState() {
    super.initState();
    _initCamera();
    Speech().speak("Mode lecture");
    //Speech().speak("Mode lecture, mettez un document devant l’appareil photo ou faites glisser l’écran pour changer de mode");
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.length > 0) {
      _camera = cameras.first;
      _controller = CameraController(
          _camera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller.initialize();
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _controller.startImageStream((CameraImage image) async {
        if (_isDetecting) return;
        _isDetecting = true;
        try {
          final detection = detectQuad(image);
          detections.insert(0, Quad.from(detection));
          // Keeping some detections to reduce flickering
          if (detections.length > 5) {
            detections.length = 5;
          }
          List<Quad> quads = detections.where((e) => (e.topLeft.x + e.topRight.x + e.bottomLeft.x + e.bottomRight.x > 0)).toList();
          setState(() {
            quad = quads.length > 0 ? quads.first : null;
          });
        } finally {
          _isDetecting = false;
        }
      });
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final ratio = _isReady ? _controller.value.aspectRatio * deviceRatio : 1.0;
    final scale = 1 / ratio;
    return Center(
        child:Transform.scale(
            scale: scale,
            child: CustomPaint(
              foregroundPainter: QuadPainter(quad: quad),
              child: GestureDetector(
                child: _isReady && _controller.value.isInitialized ? CameraPreview(_controller) : Container(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Narrator())
                  );
                }
              )
            )
        )
    );
  }
}
