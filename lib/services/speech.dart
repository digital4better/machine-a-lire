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
    _tts.awaitSpeakCompletion(true);
  }

  Future speak(String text) async {
    await _tts.stop();
    return _tts.speak(text);
  }

  void pause() async => _tts.pause();
  void stop() async => _tts.stop();
}
