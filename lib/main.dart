import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malo/services/speech.dart';

import 'widgets/vision.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  // Force portraitUp device orientation
  // ref: https://stackoverflow.com/a/50884081
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Programmatically auto-enable accessibility
  // ref: https://flutter.dev/docs/development/accessibility-and-localization/accessibility
  // RendererBinding.instance?.setSemanticsEnabled(true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
    Speech().speak("Bienvenue !");
  }

  @override
  Widget build(BuildContext context) => MaterialApp(home: Vision());
}
