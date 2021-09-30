import 'package:flutter_tts/flutter_tts.dart';

class Speech {
  static final Speech _instance = Speech._internal();
  late FlutterTts _tts;

  factory Speech() {
    return _instance;
  }

  Speech._internal() {
    _tts = FlutterTts();
    _tts.setLanguage('fr');
    _tts.setSpeechRate(0.4);
  }

  void speak(String text) async =>_tts.speak(text);
  void pause() async =>_tts.pause();
  void stop() async =>_tts.stop();
}
