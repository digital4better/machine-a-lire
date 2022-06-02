import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:malo/services/speech.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'package:language_tool/language_tool.dart' show LanguageTool;


class Narrator extends StatefulWidget {
  Narrator(this.path);

  final String path;

  @override
  NarratorState createState() => NarratorState();
}

class Span {
  String text;
  final GlobalKey key = GlobalKey();

  Span(this.text);
}

const double PADDING = 30;

class NarratorState extends State<Narrator> {
  final textDetector = GoogleMlKit.vision.textDetector();
  final _controller = ScrollController();
  List<Span> _text = [];
  int _index = -1;

  @override
  void initState() {
    super.initState();
    _parseText();
  }

  Future<List<Span>> correctText(List<Span> correctedText) async {

    var tool = LanguageTool(language: 'fr');

    for (var sentence in correctedText) {
      print(sentence.text);
      sentence.text.replaceAll('é', 'e');
      int diff = 0;
      var result = await tool.check(sentence.text);
      for (var mistake in result) {
        print('diff : $diff');
        String wordToCorrect = sentence.text.substring(mistake.offset! + diff, mistake.offset! + diff + mistake.length!);
        print("word to correct is : ($wordToCorrect)");
        if(mistake.replacements!.isNotEmpty){
          print("correct word is : (${mistake.replacements!.first!})");
          sentence.text = sentence.text.replaceAll(wordToCorrect, mistake.replacements!.first!);
          diff += mistake.replacements!.first!.length - wordToCorrect.length;
        } else {
          sentence.text = sentence.text.replaceAll(wordToCorrect, '');
          diff -= wordToCorrect.length;
        }
      }
      print(sentence.text);
    }

    return correctedText;
}

  Future<void> _parseText() async {
    await Speech().stop();
    final recognized = await textDetector.processImage(
        InputImage.fromFilePath(widget.path)
    );
    // TODO use block positions to rebuild text from column, etc...
    final text = recognized.blocks.where((b) => b.recognizedLanguages.length > 0).map((e) => e.text).join("\n");
    setState(() {
      _text = text
          .replaceAllMapped(RegExp(r"\s*([,;.:?!])(?:\s*[,;.:?!])*\s*"),
              (Match m) => "${m[1]} ")
          .replaceAll(RegExp(r"[|©#&$£€=*%+_`/{}()\[\]]+"), "")
          .replaceAll(RegExp(r"\s+"), " ")
          .split(RegExp(r"(?<=[.:?!]\s)"))
          .map((t) => Span(t))
          .toList();
    });

    List<Span> correctedText = await correctText(_text);

    setState(() {
      _text = correctedText;
    });

    await Speech().speak("La lecture va commencer, appuyez pour l’arrêter.").then((_) {
      setState(() {
        _index = 0;
      });
    });
    while (_index < _text.length) {
      RenderBox? box =
          _text[_index].key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        int delta = box.localToGlobal(Offset.zero).dy.toInt();
        _controller.animateTo(
          min(_controller.offset + delta - PADDING,
              _controller.position.maxScrollExtent),
          duration: Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
      await Speech().speak(_text[_index].text);
      setState(() {
        _index += 1;
      });
    }
    await Speech().speak("Fin de la lecture.");
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      child: Container(
        color: Color.fromARGB(255, 0, 0, 0),
        child: SingleChildScrollView(
          controller: _controller,
          padding: EdgeInsets.fromLTRB(10, PADDING, 10, 0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                  _text.length,
                  (i) => Padding(
                      key: _text[i].key,
                      padding: EdgeInsets.only(bottom: PADDING),
                      child: Text(
                        _text[i].text,
                        style: TextStyle(
                          fontSize: 32.0,
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(
                              _index == i ? 255 : 127, 255, 255, 255),
                          decoration: TextDecoration.none,
                        ),
                      )))),
        ),
      ),
      onTap: () {
        setState(() {
          _index = -1;
        });
        Speech().stop();
        Speech().speak("Lecture arrêtée");
        Navigator.pop(context);
      });
}
