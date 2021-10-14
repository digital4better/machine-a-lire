import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:malo/opencv.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/narrator.dart';
import 'package:path_provider/path_provider.dart';

class Quad {
  Point topLeft;
  Point topRight;
  Point bottomLeft;
  Point bottomRight;

  Quad(this.topLeft, this.topRight, this.bottomRight, this.bottomLeft);

  static Quad empty = Quad(Point(0, 0), Point(0, 0), Point(0, 0), Point(0, 0));

  static Quad from(Detection? d) {
    if (d == null) {
      return Quad.empty;
    }
    List<Point> points = [Point(d.x1, d.y1), Point(d.x2, d.y2), Point(d.x3, d.y3), Point(d.x4, d.y4)];
    points.sort((a, b) => a.x.compareTo(b.x));
    List<Point> lefts = points.sublist(0, 2);
    List<Point> rights = points.sublist(2, 4);
    lefts.sort((a, b) => a.y.compareTo(b.y));
    rights.sort((a, b) => a.y.compareTo(b.y));
    return Quad(lefts[0], rights[0], rights[1], lefts[1]);
  }

  bool get isEmpty => topLeft.x + topLeft.y + topRight.x + topRight.y + bottomLeft.x + bottomLeft.y + bottomRight.x + bottomRight.y == 0;
}

class QuadPainter extends CustomPainter {
  QuadPainter({this.quad, required this.transparent, required this.draw});

  Quad? quad;
  bool transparent;
  bool draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset(0, 0) & size,
        Paint()..color = Color.fromARGB(transparent ? 200 : 255, 0, 0, 0));
    if (this.quad != null && this.draw) {
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

void _detectQuad(data) {
  SendPort? sendPort;
  final receivePort = ReceivePort();
  receivePort.listen((data) async {
    if (data is BGRImage) {
      try {
        sendPort?.send(Quad.from(detectQuad(data)));
      }
      catch(_) {
        sendPort?.send(Quad.empty);
      }
    }
  });
  if (data is SendPort) {
    sendPort = data;
    sendPort.send(receivePort.sendPort);
    return;
  }
}

class VisionState extends State<Vision> with WidgetsBindingObserver {
  late CameraDescription _camera;
  late CameraController _controller;
  late VisionMode _mode;

  bool _isReady = false;
  bool _isDetecting = false;

  final _receivePort = ReceivePort();
  SendPort? _isolatePort;

  Queue<Quad> detections = Queue();
  Quad? quad;
  CameraImage? last;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initDetection();
    mode = VisionMode.CameraWithPreview;
    WidgetsBinding.instance?.addObserver(this);
    //Speech().speak("Mode lecture, mettez un document devant l’appareil photo ou faites glisser l’écran pour changer de mode");
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.length > 0) {
      _camera = cameras.first;
      _controller = CameraController(
        _camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller.initialize();
      await _controller.setFlashMode(FlashMode.torch);
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _controller.startImageStream((CameraImage image) async {
        if (_isDetecting || _isolatePort == null) return;
        _isDetecting = true;
        _isolatePort?.send(cameraImageToBGRBytes(image, maxWidth: 320));
        last = image;
      });
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _controller.value.isInitialized) {
      await _controller.setFlashMode(FlashMode.torch);
    }
  }

  Future<void> _initDetection() async {
    await Isolate.spawn<SendPort>(_detectQuad, _receivePort.sendPort, onError: _receivePort.sendPort, onExit: _receivePort.sendPort);
    _receivePort.listen((data) {
      if (data is SendPort) {
        _isolatePort = data;
      }
      else if (data is Quad) {
        detections.addFirst(data);
        // Keeping some detections to reduce flickering
        if (detections.length > 5) {
          detections.removeLast();
        }
        List<Quad> quads = detections.where((e) => !e.isEmpty).toList();
        setState(() {
          _isDetecting = false;
          quad = quads.length > 0 ? quads.first : null;
        });
      }
    });
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
    WidgetsBinding.instance?.removeObserver(this);
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
                    transparent: _mode == VisionMode.CameraWithPreview,
                    draw: _isReady),
                child: GestureDetector(
                  child: _isReady && _controller.value.isInitialized
                      ? CameraPreview(_controller)
                      : Container(color: Color(0xff000000)),
                  onTap: () async {
                    if (last != null && quad != null) {
                      setState(() {
                        _isReady = false;
                      });
                      await _controller.stopImageStream();
                      await _controller.dispose();
                      final String path = (await getTemporaryDirectory()).path + "/capture${DateTime.now().millisecondsSinceEpoch}.png";
                      warpImage(cameraImageToBGRBytes(last!), quad!, path);
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Narrator(path)));
                      await _initCamera();
                    } else {
                      Speech()
                          .speak("Le document n'est plus devant l'appareil");
                    }
                  },
                  onPanEnd: (details) {
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
