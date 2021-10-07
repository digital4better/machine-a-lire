import 'dart:async';
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
  QuadPainter({this.quad, required this.transparent});

  Quad? quad;
  bool transparent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset(0, 0) & size,
        Paint()..color = Color.fromARGB(transparent ? 200 : 255, 0, 0, 0));
    if (this.quad != null) {
      final path = Path()
        ..moveTo(this.quad!.topLeft.x * size.width,
            this.quad!.topLeft.y * size.height)
        ..lineTo(this.quad!.topRight.x * size.width,
            this.quad!.topRight.y * size.height)
        ..lineTo(this.quad!.bottomRight.x * size.width,
            this.quad!.bottomRight.y * size.height)
        ..lineTo(this.quad!.bottomLeft.x * size.width,
            this.quad!.bottomLeft.y * size.height)
        ..close();
      canvas.drawPath(
          path, Paint()..color = Color.fromARGB(255, 255, 255, 255));
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

enum VisionMode { CameraWithPreview, CameraWithoutPreview }

class VisionState extends State<Vision> {
  late CameraDescription _camera;
  late CameraController _controller;
  late VisionMode _mode;

  bool _isReady = false;
  bool _isDetecting = false;

  List<Quad> detections = [];
  Quad? quad;

  @override
  void initState() {
    super.initState();
    _initCamera();
    mode = VisionMode.CameraWithPreview;
    //Speech().speak("Mode lecture, mettez un document devant l’appareil photo ou faites glisser l’écran pour changer de mode");
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.length > 0) {
      _camera = cameras.first;
      _controller = CameraController(
        _camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller.initialize();
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _controller.startImageStream((CameraImage image) {
        if (_isDetecting) return;
        _isDetecting = true;
        Future.delayed(Duration(milliseconds: 10), () {
          try {
            final detection = detectQuad(image);
            detections.insert(0, Quad.from(detection));
            // Keeping some detections to reduce flickering
            if (detections.length > 5) {
              detections.length = 5;
            }
            List<Quad> quads = detections
                .where((e) => (e.topLeft.x +
                e.topRight.x +
                e.bottomLeft.x +
                e.bottomRight.x >
                0))
                .toList();
            setState(() {
              quad = quads.length > 0 ? quads.first : null;
            });
          } finally {
            _isDetecting = false;
          }
        });
      });
      setState(() {
        _isReady = true;
      });
    }
  }

  Future<CameraImage> _takePicture() async {
    setState(() {
      _isReady = false;
    });
    await _controller.stopImageStream();
    await _controller.dispose();
    _controller = CameraController(
      _camera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );
    await _controller.initialize();
    await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    Completer<CameraImage> c = new Completer();
    bool captured = false;
    await _controller.startImageStream((CameraImage image) async {
      if (!captured) {
        captured = true;
        print("image captured");
        await _controller.stopImageStream();
        await _controller.dispose();
        // TODO warp image with opencv
        // https://tesseract-ocr.github.io/tessdoc/ImproveQuality.html#image-processing
        c.complete(image);
      }
    });
    return c.future;
  }

  set mode(VisionMode mode) {
    _mode = mode;
    Speech().stop();
    switch (_mode) {
      case VisionMode.CameraWithoutPreview:
        Speech().speak("Mode lecture");
        break;
      case VisionMode.CameraWithPreview:
        Speech().speak("Mode lecture avec prévisualisation");
        break;
      default:
        break;
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
        child: Transform.scale(
            scale: scale,
            child: CustomPaint(
                foregroundPainter: QuadPainter(
                    quad: quad,
                    transparent: _mode == VisionMode.CameraWithPreview),
                child: GestureDetector(
                  child: _isReady && _controller.value.isInitialized
                      ? CameraPreview(_controller)
                      : Container(color: Color(0xff000000)),
                  onTap: () async {
                    if (quad != null) {
                      CameraImage image = await _takePicture();
                      print("${image.width}x${image.height}");
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => Narrator()));
                      await _initCamera();
                    } else {
                      Speech().speak("Le document n'est plus devant l'appareil");
                    }
                  },
                  onPanEnd: (details) {
                    print(details);
                    if (details.velocity.pixelsPerSecond.dx.abs() >
                        details.velocity.pixelsPerSecond.dy.abs()) {
                      if (details.velocity.pixelsPerSecond.dx > 0) {
                        setState(() {
                          mode = _mode == VisionMode.CameraWithPreview
                              ? VisionMode.CameraWithoutPreview
                              : VisionMode.CameraWithPreview;
                        });
                      }
                      if (details.velocity.pixelsPerSecond.dx < 0) {
                        setState(() {
                          mode = _mode == VisionMode.CameraWithPreview
                              ? VisionMode.CameraWithoutPreview
                              : VisionMode.CameraWithPreview;
                        });
                      }
                    }
                  },
                ))));
  }
}
