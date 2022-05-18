import 'package:flutter_tts/flutter_tts.dart';

class Speech {
  static final Speech _instance = Speech._internal();
  late FlutterTts _tts;

  factory Speech() {
    return _instance;
  }

  Speech._internal() {
    _tts = FlutterTts();
    _tts.awaitSpeakCompletion(true);
    _tts.setLanguage('fr');
    _tts.setVoice({"locale": "fr-FR", "name": "Thomas"});
    _tts.setSpeechRate(0.5);
    _tts.awaitSpeakCompletion(true);
  }

  Future speak(String text) async {
    await _tts.stop();
    return _tts.speak(text);
  }
  Future<dynamic> pause() async => _tts.pause();
  Future<dynamic> stop() async => _tts.stop();
}
