import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malo/widgets/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {}

  @override
  Widget build(BuildContext context) => MaterialApp(home: Home());
}
