import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  Widget build(BuildContext context) => Directionality(
      textDirection: TextDirection.ltr,
      child: CustomPaint(
      foregroundPainter: PolyPainter(),
      child:   GestureDetector(
          child: cameras.length > 0 ? CameraScreen(camera: cameras.first) : Container(),
          onTap: () {
            tts.stop();
            tts.speak("Début de la lecture");
          }
      )
  ));
}

class PolyPainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(255, 255, 255, 0);
    final path = Path()
      ..moveTo(100, 250)
      ..lineTo(50, 600)
      ..lineTo(400, 620)
      ..lineTo(340, 240)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({
    Key? key,
    required this.camera
  }) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    _initializeControllerFuture.then((_) => {
      _controller.startImageStream((CameraImage image) {
        if (_isDetecting) return;
        _isDetecting = true;
        try {
          stdout.writeln("Detecting image ${image.format.group} - ${image.planes.length}");
          // await doOpenCVDectionHere(image)
        } catch (e) {
          // await handleExepction(e)
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
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return CameraPreview(_controller);
        } else {
          return Container();
        }
      },
    );
  }
}
