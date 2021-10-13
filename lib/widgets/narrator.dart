import 'package:flutter/widgets.dart';
import 'package:malo/services/speech.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class Narrator extends StatefulWidget {
  Narrator(this.path);

  final String path;

  @override
  NarratorState createState() => NarratorState();
}

class NarratorState extends State<Narrator> {
  List<String> _text = [];

  @override
  void initState() {
    super.initState();
    _parseText();
    Speech().stop();
    Speech()
        .speak("La lecture va commencer, appuyez sur l’écran pour l’arrêter");
  }

  Future<void> _parseText() async {
    String text = await FlutterTesseractOcr.extractText(widget.path,
        language: 'fra',
        args: {
          "psm": "6",
          "preserve_interword_spaces": "1",
        });
    // TODO post process text for cleanup or use multiple pass with different psm values
    print(text);
    Speech().speak(text);
    setState(() {
      _text = [text];
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      child: Container(
        color: Color.fromARGB(255, 0, 0, 0),
        child: ListView(
          //child: Image.file(File(widget.path))
          padding: EdgeInsets.fromLTRB(10, 30, 10, 30),
          children: _text
              .map((t) => Text(
                    t,
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(255, 255, 255, 255),
                      decoration: TextDecoration.none,
                    ),
                  ))
              .toList(),
        ),
      ),
      onTap: () {
        Speech().stop();
        Speech().speak("Lecture arrêtée");
        Navigator.pop(context);
      });
}
