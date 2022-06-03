import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malo/services/speech.dart';

import 'widgets/vision.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
    Speech().speak("Bienvenue !");
  }

  @override
  Widget build(BuildContext context) => MaterialApp(home: Vision());
}
