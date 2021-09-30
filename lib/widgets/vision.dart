import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';
import 'package:malo/opencv.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/narrator.dart';

class QuadPainter extends CustomPainter {

  QuadPainter({
    this.quad
  });

  Quad? quad;

  @override
  void paint(Canvas canvas, Size size) {
    if (this.quad != null) {
      final path = Path()
        ..moveTo(this.quad!.x1 * size.width, this.quad!.y1 * size.height)
        ..lineTo(this.quad!.x2 * size.width, this.quad!.y2 * size.height)
        ..lineTo(this.quad!.x4 * size.width, this.quad!.y4 * size.height)
        ..lineTo(this.quad!.x3 * size.width, this.quad!.y3 * size.height)
        ..close();
      canvas.drawRect(Offset(0, 0) & size, Paint()..color = Color.fromARGB(200, 0, 0, 0));
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
      await _controller.lockCaptureOrientation();
      _controller.startImageStream((CameraImage image) async {
        if (_isDetecting) return;
        _isDetecting = true;
        try {
          final result = detectQuad(image);
          setState(() {
            quad = result;
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
