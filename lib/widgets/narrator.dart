import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:malo/services/speech.dart';

class Narrator extends StatefulWidget {
  Narrator(this.path);

  final String path;

  @override
  NarratorState createState() => NarratorState();
}

class Span {
  final String text;
  final GlobalKey key = GlobalKey();

  Span(this.text);
}

const double PADDING = 30;

class NarratorState extends State<Narrator> {
  final _controller = ScrollController();
  List<Span> _text = [];
  int _index = -1;

  @override
  void initState() {
    super.initState();
    _parseText();
  }

  @override
  void dispose() {
    Speech().stop();
    super.dispose();
  }

  Future<void> _parseText() async {
    await Speech().stop();

    final text = await FlutterTesseractOcr.extractText(
      widget.path,
      language: 'fra',
      args: {
        "psm": "6",
        "preserve_interword_spaces": "1",
      },
    );

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

    await Speech()
        .speak("La lecture va commencer, appuyez pour l’arrêter.")
        .then((_) {
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
          min(
            _controller.offset + delta - PADDING,
            _controller.position.maxScrollExtent,
          ),
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
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        color: Color.fromARGB(255, 0, 0, 0),
        child: SingleChildScrollView(
            controller: _controller,
            padding: EdgeInsets.fromLTRB(10, PADDING, 10, 0),
            child: Stack(
              children: [
                Image.file(File(widget.path)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    _text.length,
                    (i) => Padding(
                      key: _text[i].key,
                      padding: EdgeInsets.only(bottom: PADDING),
                      child: Text(
                        _text[i].text,
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(
                              _index == i ? 255 : 127, 255, 255, 255),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )),
      ),
      onTap: () {
        setState(() {
          _index = -1;
        });
        Speech().stop();
        Speech().speak("Lecture arrêtée");
        Navigator.pop(context);
      },
    );
  }
}
