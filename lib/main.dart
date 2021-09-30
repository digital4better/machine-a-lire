import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:malo/opencv.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterTts tts = FlutterTts();

  MyApp() {
    tts.getVoices.then((value) {
      stdout.writeln("Voices");
      stdout.writeln(value);
      //tts.setVoice({"name": "Daniel", "locale": "fr-FR"});
    });
    stdout.writeln("Set tts");
    tts.setLanguage('fr');
    tts.setSpeechRate(0.5);
    tts.speak("Bonjour !");
    //tts.speak("Mode lecture, mettez un document devant l’appareil photo ou faites glisser l’écran pour changer de mode");
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      home:  cameras.length > 0 ? Vision(camera: cameras.first) : Container()
  );
}

class PolyPainter extends CustomPainter {

  PolyPainter({
    this.quad,
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
  final CameraDescription camera;

  const Vision({
    Key? key,
    required this.camera
  }) : super(key: key);

  @override
  VisionState createState() => VisionState();
}

class VisionState extends State<Vision> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isDetecting = false;
  Quad? quad;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888
    );
    _initializeControllerFuture = _controller.initialize();
    _initializeControllerFuture.then((_) => {
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
      })
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        foregroundPainter: PolyPainter(quad : quad),
        child: GestureDetector(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return Container();
                }
              },
            ),
            onTap: () {

            }
        )
    );
  }
}
