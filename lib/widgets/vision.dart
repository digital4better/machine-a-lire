import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/narrator.dart';
import 'package:native_opencv/native_opencv.dart';

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
  QuadPainter({this.quad});

  Quad? quad;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset(0, 0) & size, Paint()..color = Color.fromARGB(200, 0, 0, 0));

    if (this.quad == null) return;

    final path = Path()
      ..moveTo(
          this.quad!.topLeft.x * size.width, this.quad!.topLeft.y * size.height)
      ..lineTo(this.quad!.topRight.x * size.width,
          this.quad!.topRight.y * size.height)
      ..lineTo(this.quad!.bottomRight.x * size.width,
          this.quad!.bottomRight.y * size.height)
      ..lineTo(this.quad!.bottomLeft.x * size.width,
          this.quad!.bottomLeft.y * size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Color.fromARGB(255, 255, 255, 255));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Vision extends StatefulWidget {
  const Vision({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  VisionState createState() => VisionState();
}

enum VisionMode { CameraWithPreview, CameraWithoutPreview }

class VisionState extends State<Vision> {
  VisionMode _mode = VisionMode.CameraWithPreview;

  late CameraController _controller;
  late Future<void>? _initializeControllerFuture;

  Completer<Null>? detection;
  Queue<Quad?> detections = new Queue();
  Quad? quad;

  Future<CameraImage> _takePicture() async {
    await _disposeController();

    Completer<CameraImage> completer = new Completer();
    CameraController controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller.initialize().then((_) async {
      await controller.lockCaptureOrientation();
      await controller.startImageStream((CameraImage image) async {
        completer.complete(image);
        await controller.stopImageStream();
      });
      await controller.unlockCaptureOrientation();
      await controller.dispose();
    });

    _initController();

    return completer.future;
  }

  void _toggleVisionMode() {
    setState(() {
      _mode = _mode == VisionMode.CameraWithPreview
          ? VisionMode.CameraWithoutPreview
          : VisionMode.CameraWithPreview;
    });

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

  Future<void> _initController() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    setState(() {
      _initializeControllerFuture = _controller.initialize().then((_) async {
        await _controller.lockCaptureOrientation();
        _controller.startImageStream((CameraImage image) {
          if (detection != null && !detection!.isCompleted) return;
          detection = new Completer();
          Future.delayed(Duration(milliseconds: 10), () {
            try {
              final detectedQuad = detectQuad(image);

              detections.addFirst(Quad.from(detectedQuad));
              // Keeping some detections to reduce flickering
              if (detections.length > 5) {
                detections.removeLast();
              }

              quad = detections.firstWhere(
                  (e) => (e!.topLeft.x +
                          e.topRight.x +
                          e.bottomLeft.x +
                          e.bottomRight.x >
                      0),
                  orElse: () => null);
            } finally {
              detection!.complete(null);
              setState(() {});
            }
          });
        });
      });
    });
  }

  Future<void> _disposeController() async {
    setState(() {
      _initializeControllerFuture = null;
    });

    await _controller.unlockCaptureOrientation();
    await _controller.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initController();
    //Speech().speak("Mode lecture, mettez un document devant l’appareil photo ou faites glisser l’écran pour changer de mode");
  }

  @override
  void dispose() async {
    await _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          // If the Future is complete, display the preview.
          if (snapshot.connectionState == ConnectionState.done) {
            final size = MediaQuery.of(context).size;
            final deviceRatio = size.width / size.height;

            return Transform.scale(
                scale: 1 / (_controller.value.aspectRatio * deviceRatio),
                child: CustomPaint(
                    foregroundPainter: QuadPainter(quad: quad),
                    child: GestureDetector(
                        child: _mode == VisionMode.CameraWithPreview
                            ? CameraPreview(_controller)
                            : Container(color: Color(0xff000000)),
                        onTap: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Narrator(image: _takePicture())));
                        },
                        onPanEnd: (details) {
                          if (!(details.velocity.pixelsPerSecond.dx.abs() >
                                  details.velocity.pixelsPerSecond.dy.abs() &&
                              details.velocity.pixelsPerSecond.dx != 0)) {
                            return;
                          }
                          _toggleVisionMode();
                        })));
          }
          // Otherwise, display a loading indicator.
          else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
}
