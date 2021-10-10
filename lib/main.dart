import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:malo/services/speech.dart';

import 'widgets/vision.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Use full screen with restoration
// ref: https://api.flutter.dev/flutter/services/SystemUiMode-class.html
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

// Force portraitUp device orientation
// ref: https://stackoverflow.com/a/50884081
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

// Programmatically auto-enable accessibility
// ref: https://flutter.dev/docs/development/accessibility-and-localization/accessibility
  RendererBinding.instance?.setSemanticsEnabled(true);

  Speech().speak("Bonjour !");

  // Select back facing camera if available of the first one otherwise.
  final cameras = await availableCameras();
  if (cameras.length == 0) return;
  final camera = cameras.firstWhere(
      (element) => element.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first);

  runApp(MaterialApp(home: Vision(camera: camera)));
}
