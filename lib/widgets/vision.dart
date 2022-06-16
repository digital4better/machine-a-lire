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
import 'package:malo/widgets/narrator.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:path_provider/path_provider.dart';

class QuadPainter extends CustomPainter {
  QuadPainter({this.quad, required this.draw, required this.alpha});

  Quad? quad;
  bool draw;
  int alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (this.quad != null && this.draw) {
      late Path path;
      if (Platform.isAndroid) {
        path = Path()
          ..moveTo((1 - this.quad!.topRight.y) * size.width,
              this.quad!.topRight.x * size.height)
          ..lineTo((1 - this.quad!.topLeft.y) * size.width,
              this.quad!.topLeft.x * size.height)
          ..lineTo((1 - this.quad!.bottomLeft.y) * size.width,
              this.quad!.bottomLeft.x * size.height)
          ..lineTo((1 - this.quad!.bottomRight.y) * size.width,
              this.quad!.bottomRight.x * size.height)
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
          path,
          Paint()
            ..color = Color.fromARGB(alpha, 255, 255, 255)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10);
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

void _detectQuad(SendPort sendPort) async {
  ReceivePort spawnReceivePort = ReceivePort();
  sendPort.send(spawnReceivePort.sendPort);

  await for (dynamic msg in spawnReceivePort) {
    var data = msg[0];
    SendPort replyTo = msg[1];

    if (data is CameraImage) {
      try {
        replyTo.send(Quad.from(detectQuad(data)));
      } catch (_) {
        replyTo.send(Quad.empty);
      }
    }

    if (data is String && data == "close") {
      spawnReceivePort.close();
    }
  }
}

/// sends a message on a port, receives the response,
/// and returns the message
Future sendReceive(SendPort port, msg) {
  ReceivePort response = new ReceivePort();
  port.send([msg, response.sendPort]);
  return response.first;
}

class VisionState extends State<Vision>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final int minTickSpeed = 60;
  final int maxTickSpeed = 3;
  late String _imagesRootPath;
  late ReceivePort _receivePort;
  late SendPort _sendPort;
  late Ticker _ticker;
  late Quad detectedQuad;
  bool isTalking = false;
  bool isChecking = false;
  CameraController? _cameraController;
  CameraDescription? _camera;
  CameraImage? _lastCameraImage;
  bool _isDetectingQuad = false;
  Quad _currentQuad = Quad.empty;
  Quad _previousQuad = Quad.empty;
  Timer? _hapticTimer;

  // QUAD DETECTION FUNCTIONS //
  Future _startQuadDetection() async {
    _ticker.start();

    await _cameraController!.startImageStream((CameraImage image) async {
      if (!_isDetectingQuad) {
        // Delegate detecting quad heavy task to an isolate thread.
        _isDetectingQuad = true;
        _currentQuad = await sendReceive(_sendPort, image);

        // Once it's done, check if widget hasn't been close in the meanwhile.
        if (_cameraController == null ||
            !_cameraController!.value.isInitialized ||
            !_cameraController!.value.isStreamingImages) {
          return;
        }

        // If everything is fine, then update detected quad state.
        _isDetectingQuad = false;
        _lastCameraImage = image;
      }
    });
    _cameraController!.setFlashMode(FlashMode.torch);

    Speech().speak(
        "Scan de document en cours, présentez un document devant l’appareil.");
  }

  Future _stopQuadDetection({bool isKeepFlashOn = false}) async {
    //alpha = 0;
    _ticker.stop();

    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
      _isDetectingQuad = false;

      if (!isKeepFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }

      sendReceive(_sendPort, "close");
    }
  }

  _tickEmptyQuad() {
    _stopHapticFeedback();
    _resetQuads();
  }

  _tickDetectedQuad() {
    _startHapticFeedback();

    setState(() {
      if (_previousQuad.isEmpty) {
        _previousQuad = _currentQuad;
      } else {
        _previousQuad.topLeft +=
            (_currentQuad.topLeft * 0.1 - _previousQuad.topLeft * 0.1);
        _previousQuad.topRight +=
            (_currentQuad.topRight * 0.1 - _previousQuad.topRight * 0.1);
        _previousQuad.bottomRight +=
            (_currentQuad.bottomRight * 0.1 - _previousQuad.bottomRight * 0.1);
        _previousQuad.bottomLeft +=
            (_currentQuad.bottomLeft * 0.1 - _previousQuad.bottomLeft * 0.1);
      }
    });

    // TODO add vocal instructions
    // TODO add movement detection for better capture
    num widthPercent;
    if (Platform.isAndroid) {
      widthPercent = min(_previousQuad.bottomRight.y - _previousQuad.topRight.y,
          _previousQuad.bottomLeft.y - _previousQuad.topLeft.y);
    } else {
      widthPercent = min(_previousQuad.topRight.x - _previousQuad.topLeft.x,
          _previousQuad.bottomRight.x - _previousQuad.bottomLeft.x);
    }

    //print("widthPercent" + widthPercent.toString());
    if (widthPercent > 0.75 && !isChecking) {
      isChecking = true;
      detectedQuad = Quad(
          _previousQuad.topLeft, _previousQuad.topRight,
          _previousQuad.bottomRight, _previousQuad.bottomLeft
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        checkIfQuadIsStable(0);
      });
    }

    if (widthPercent < 0.75 && isTalking == false) {
      isTalking = true;
      Speech().speak("Rapprochez l'appareil de la feuille").then((e) {
        isTalking = false;
      });
    }
  }

  void checkIfQuadIsStable(int timesCheck) {
    print(timesCheck);
    if ((_previousQuad.topLeft.x - detectedQuad.topLeft.x).abs() < 0.05 &&
        (_previousQuad.topLeft.y - detectedQuad.topLeft.y).abs() < 0.05 &&
        (_previousQuad.topRight.x - detectedQuad.topRight.x).abs() < 0.05 &&
        (_previousQuad.topRight.y - detectedQuad.topRight.y).abs() < 0.05 &&
        (_previousQuad.bottomLeft.y - detectedQuad.bottomLeft.y).abs() < 0.05 &&
        (_previousQuad.bottomLeft.x - detectedQuad.bottomLeft.x).abs() < 0.05 &&
        (_previousQuad.bottomRight.x - detectedQuad.bottomRight.x).abs() <
            0.05 &&
        (_previousQuad.bottomRight.y - detectedQuad.bottomRight.y).abs() <
            0.05) {
      timesCheck == 5
          ? takePictureForAnalyse()
          : Future.delayed(const Duration(milliseconds: 500), () {
              checkIfQuadIsStable(timesCheck + 1);
            });
    } else {
      isChecking = false;
    }
  }

  // HAPTICS FEEDBACK FUNCTIONS //
  Duration? _timeBetweenTwoVibrations() {
    double widthPercent = min(_currentQuad.topRight.x - _currentQuad.topLeft.x,
            _currentQuad.bottomRight.x - _currentQuad.bottomLeft.x)
        .toDouble();

    if (widthPercent <= 0) {
      return null;
    }

    return Duration(
        milliseconds: widthPercent < 0.25
            ? 500
            : widthPercent < 0.5
                ? 300
                : widthPercent < 0.6
                    ? 200
                    : 100);
  }

  /// When user is close to frame correctly the document, haptics feedbacks starts.
  /// The more it vibrates, the better the frame is.
  Future _startHapticFeedback() async {
    if (_hapticTimer == null || !_hapticTimer!.isActive) {
      Duration? duration = _timeBetweenTwoVibrations();
      if (duration.runtimeType == Duration) {
        await HapticFeedback.selectionClick();
        _hapticTimer = Timer(duration!, () {});
      }
    }
  }

  /// Stops haptics feedbacks.
  void _stopHapticFeedback() {
    if (_hapticTimer != null && _hapticTimer!.isActive) {
      _hapticTimer!.cancel();
    }
  }

  void _resetQuads() {
    setState(() {
      _currentQuad = Quad.empty;
      _previousQuad = Quad.empty;
      //alpha = 0;
    });
  }

  // DO ANALYSE FUNCTIONS //
  Future takePictureForAnalyseForIos() async {
    // Stop preview stream and take a picture from camera.
    await _stopQuadDetection();

    BGRImage picture = cameraImageToBGRBytes(_lastCameraImage!);

    // Save warped file somewhere on the phone.
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String warpedFileName = "${timestamp}-warpedPicture.png";
    String warpedPath = _imagesRootPath + "/$warpedFileName";
    warpImage(picture, _previousQuad, warpedPath);

    _resetQuads();

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Narrator(warpedFileName);
        },
      ),
    );
  }

  Future takePictureForAnalyseForAndroid() async {
    Speech().speak("Ne bougez plus votre appareil.");

    // Stop preview stream and take a picture from camera.
    await _stopQuadDetection(isKeepFlashOn: true);
    XFile picture = await _cameraController!.takePicture();
    await _cameraController!.setFlashMode(FlashMode.off);

    // Save raw picture file somewhere on the phone.
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String rawFileName = "${timestamp}-rawPicture.png";
    await picture.saveTo('$_imagesRootPath/$rawFileName');

    // Save copy of raw file somewhere on the phone. That copy will be used for warp stuff.
    String warpedFileName = "${timestamp}-warpedPicture.png";
    String warpedPath = _imagesRootPath + "/$warpedFileName";
    await picture.saveTo(warpedPath);

    _resetQuads();

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Analyse(warpedPath);
        },
      ),
    );
  }

  Future takePictureForAnalyse() async {
    if (_lastCameraImage != null &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      _stopHapticFeedback(); // TODO check if useful

      if (Platform.isAndroid) {
        takePictureForAnalyseForAndroid();
      } else {
        takePictureForAnalyseForIos();
      }
    }
  }

  // LIFECYCLE WIDGET FUNCTIONS //
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _init();
  }

  Future _init() async {
    await _initIsolatePort();
    await _initCamera();
    await _initTicker();

    await _startQuadDetection();
    setState(() {});
  }

  Future _initImagesPath() async {
    _imagesRootPath = (await getTemporaryDirectory()).path;
  }

  Future _initCamera() async {
    await _initImagesPath();

    try {
      List<CameraDescription> cameras = await availableCameras();

      if (cameras.length > 0) {
        _camera = cameras.firstWhere(
          (element) => element.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          _camera!,
          ResolutionPreset.ultraHigh,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.yuv420
              : ImageFormatGroup.bgra8888,
        );
        await _cameraController!.initialize();
        await _cameraController
            ?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      }
    } catch (e) {
      print(e);
    }
  }

  /// Detecting quad is an heavy task, that's why it will be delegate in an isolate port.
  /// In order to avoid UI freeze.
  Future _initIsolatePort() async {
    _receivePort = ReceivePort();

    await Isolate.spawn<SendPort>(
      _detectQuad,
      _receivePort.sendPort,
    );

    _sendPort = await _receivePort.first;
  }

  Future _initTicker() async {
    _ticker = createTicker((Duration elapsed) {
      if (_currentQuad.isEmpty) {
        _tickEmptyQuad();
      } else {
        _tickDetectedQuad();
      }
    });
  }

  @override
  void dispose() async {
    try {
      if (_cameraController != null) {
        _cameraController!.dispose();
      }

      _ticker.dispose();

      if (_hapticTimer != null && _hapticTimer!.isActive) {
        _hapticTimer!.cancel();
      }
    } catch (e) {
      print(e);
    } finally {
      WidgetsBinding.instance.removeObserver(this);
      super.dispose();
    }
  }

  /// Makes sure that camera stream and torch is off if app is not running.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      if (state == AppLifecycleState.resumed &&
          !_cameraController!.value.isStreamingImages) {
        await _startQuadDetection();
      } else {
        await _stopQuadDetection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double deviceRatio = size.width / size.height;
    double ratio =
        _cameraController != null && _cameraController!.value.isInitialized
            ? _cameraController!.value.aspectRatio * deviceRatio
            : 1.0;

    final scale = 1 / ratio;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Scan de document"),
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: Transform.scale(
            scale: scale,
            child: CustomPaint(
              foregroundPainter: QuadPainter(
                quad: _previousQuad,
                draw: !_currentQuad.isEmpty,
                alpha: 255,
              ),
              child: _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : Container(),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: takePictureForAnalyse,
          backgroundColor: Colors.white,
          child: Semantics(
            hint: "Prendre une photo manuellement",
            child: Icon(
              Icons.camera_alt,
              color: Colors.black,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
