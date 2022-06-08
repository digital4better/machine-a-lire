import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/analyse.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:path_provider/path_provider.dart';

import 'home.dart';

class QuadPainter extends CustomPainter {
  QuadPainter({this.quad, required this.draw, required this.alpha});

  Quad? quad;
  bool draw;
  int alpha;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset(0, 0) & size, Paint()..color = Color.fromARGB(alpha, 0, 0, 0));
    if (this.quad != null && this.draw) {
      late Path path;
      if (Platform.isAndroid) {
        path = Path()
          ..moveTo(this.quad!.topLeft.y * size.width,
              this.quad!.topLeft.x * size.height)
          ..lineTo(this.quad!.topRight.y * size.width,
              this.quad!.topRight.x * size.height)
          ..lineTo(this.quad!.bottomRight.y * size.width,
              this.quad!.bottomRight.x * size.height)
          ..lineTo(this.quad!.bottomLeft.y * size.width,
              this.quad!.bottomLeft.x * size.height)
          ..close();
      } else {
        path = Path()
          ..moveTo(this.quad!.topLeft.x * size.width,
              this.quad!.topLeft.y * size.height)
          ..lineTo(this.quad!.topRight.x * size.width,
              this.quad!.topRight.y * size.height)
          ..lineTo(this.quad!.bottomRight.x * size.width,
              this.quad!.bottomRight.y * size.height)
          ..lineTo(this.quad!.bottomLeft.x * size.width,
              this.quad!.bottomLeft.y * size.height)
          ..close();
      }

      canvas.drawPath(
          path, Paint()..color = Color.fromARGB(alpha, 255, 255, 255));
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

void _detectQuad(data) {
  SendPort? sendPort;
  final receivePort = ReceivePort();
  receivePort.listen((data) async {
    if (data is CameraImage) {
      try {
        sendPort?.send(Quad.from(detectQuad(data)));
      } catch (_) {
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

class VisionState extends State<Vision>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late CameraDescription _camera;
  late CameraController _controller;
  late Ticker _ticker;
  late Size _size;
  late double _deviceRatio;
  bool _isScanning = false;
  bool _isDetecting = false;

  late String _imagesRootPath;

  final _receivePort = ReceivePort();
  SendPort? _isolatePort;

  Quad target = Quad.empty;
  CameraImage? _lastCameraImage;

  Quad current = Quad.empty;
  int alpha = 0;
  int time = 0;

  Future _initImagesPath() async {
    _imagesRootPath = (await getTemporaryDirectory()).path;
  }

  /// Makes sure that camera stream and torch is off if app is not running.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_controller.value.isInitialized) {
      if (state == AppLifecycleState.resumed && _isScanning) {
        await _startImageStream();
      } else {
        await _stopImageStream();
        await _controller.setFlashMode(FlashMode.off);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _initialisation();

    WidgetsBinding.instance?.addObserver(this);
  }

  Future<void> _initialisation() async {
    await _initCamera();
    await _initDetection();
    await _initAnimation();
  }

  Future<void> _initAnimation() async {
    int tock = 0;
    _ticker = createTicker((Duration elapsed) {
      final int delta = elapsed.inMilliseconds - time;
      final int alphaSpeed = (255 * delta / 300).round();
      final int minTockSpeed = 60;
      final int maxTockSpeed = 3;

      if (target.isEmpty) {
        setState(() {
          alpha = max(alpha - alphaSpeed, 0);
          if (alpha == 0) {
            current = Quad.empty;
          }
        });
      } else {
        setState(() {
          alpha = min(alpha + alphaSpeed, 255);
          if (current.isEmpty) {
            current = target;
          } else {
            current.topLeft += (target.topLeft * 0.1 - current.topLeft * 0.1);
            current.topRight +=
                (target.topRight * 0.1 - current.topRight * 0.1);
            current.bottomRight +=
                (target.bottomRight * 0.1 - current.bottomRight * 0.1);
            current.bottomLeft +=
                (target.bottomLeft * 0.1 - current.bottomLeft * 0.1);
          }
        });
        if (_isScanning) {
          // TODO add vocal instructions
          // TODO add movement detection for better capture
          if (alpha == 255) {
            num widthPercent = min(current.topRight.x - current.topLeft.x,
                current.bottomRight.x - current.bottomLeft.x);
            if (widthPercent > 0.75) {
              takePictureForAnalyse();
            } else if (tock >
                (maxTockSpeed - minTockSpeed) *
                        ((0.6 - min(0.6, widthPercent)) / 0.6) +
                    maxTockSpeed) {
              tock = 0;
              HapticFeedback.lightImpact();
            }
          }
        }
      }
      time = elapsed.inMilliseconds;
      tock++;
    });
    await _ticker.start();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    if (cameras.length > 0) {
      _camera = cameras.firstWhere(
        (element) => element.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        _camera,
        ResolutionPreset.ultraHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller.initialize();
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _startImageStream();

      setState(() {
        _isScanning = true;
      });
    }
  }

  Future _startImageStream() async {
    await _controller.startImageStream((CameraImage image) async {
      if (_isDetecting || _isolatePort == null) return;
      _isDetecting = true;
      _isolatePort?.send(image);
      _lastCameraImage = image;
    });
    await _controller.setFlashMode(FlashMode.torch);
    Speech().speak(
        "Scan de document prêt, présentez un document devant l’appareil.");
  }

  Future _stopImageStream() async {
    alpha = 0;

    await _controller.stopImageStream();
    _isDetecting = false;
  }

  Future<void> _initDetection() async {
    await Isolate.spawn<SendPort>(
      _detectQuad,
      _receivePort.sendPort,
      onError: _receivePort.sendPort,
      onExit: _receivePort.sendPort,
    );

    _receivePort.listen((data) {
      if (data is SendPort) {
        _isolatePort = data;
        _isolatePort = data;
      } else if (data is Quad) {
        setState(() {
          _isDetecting = false;
          target = data;
        });
      }
    });
  }

  Future<void> takePictureForAnalyse() async {
    if (_lastCameraImage != null &&
        _isScanning &&
        _controller.value.isInitialized) {
      setState(() {
        _isScanning = false;
      });

      await HapticFeedback.heavyImpact();
      await Speech().speak("Capture en cours, ne bougez plus votre appareil.");

      // Stop preview stream and take a picture from camera.
      await _stopImageStream();
      XFile picture = await _controller.takePicture();
      await _controller.setFlashMode(FlashMode.off);

      await _initImagesPath();

      // Save raw picture file somewhere on the phone.
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String rawFileName = "${timestamp}-rawPicture.png";
      await picture.saveTo('$_imagesRootPath/$rawFileName');

      // Save copy of raw file somewhere on the phone. That copy will be used for warp stuff.
      String warpedFileName = "${timestamp}-warpedPicture.png";
      String warpedPath = _imagesRootPath + "/$warpedFileName";
      await picture.saveTo(warpedPath);

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Analyse(warpedFileName);
          },
        ),
      );
    }
  }

  void goToMainMenu() async {
    Speech().speak("Retour au menu principal");
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Home();
        },
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    _deviceRatio = _size.width / _size.height;
    final ratio =
        _isScanning ? _controller.value.aspectRatio * _deviceRatio : 1.0;

    final scale = 1 / ratio;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: CustomPaint(
          foregroundPainter: QuadPainter(
            quad: current,
            draw: _isScanning,
            alpha: 100,
          ),
          child: GestureDetector(
            onLongPress: takePictureForAnalyse,
            onDoubleTap: goToMainMenu,
            child: _isScanning && _controller.value.isInitialized
                ? CameraPreview(_controller)
                : Container(),
          ),
        ),
      ),
    );
  }
}
