import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/vision.dart';
import 'package:path_provider/path_provider.dart';

import 'home.dart';

class Narrator extends StatefulWidget {
  Narrator(this.path, {this.isTextExtracted = false});

  final String path;
  final bool isTextExtracted;

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
  late String imagePath;
  final _controller = ScrollController();
  List<Span> _text = [];
  int _index = -1;

  @override
  void initState() {
    _text = [Span("Analyse du text en cours...")];
    if(widget.isTextExtracted){
      _readTextFile();
    } else{
      _parseText();
    };
    super.initState();
  }

  @override
  void dispose() {
    Speech().stop();
    super.dispose();
  }

  Future<void> _getFullPath() async {
    String Path = '${(await getTemporaryDirectory()).path}/${widget.path}';
    setState((){
      imagePath = Path;
    });
  }

  void saveText(String text) async {
    Directory('${(await getApplicationDocumentsDirectory()).path}/scans').create()
      .then((Directory dir) => File('${dir.path}/${DateTime.now().millisecondsSinceEpoch.toString()}.txt').writeAsString(text));
  }

  Future<void> _readTextFile() async {
    String rawText = await File(widget.path).readAsString();
    List<Span> text = [Span(rawText)];
      setState(() {
      _text = text;
      _index = 0;
      _readSentences();
    });
  }

  Future<void> _parseText() async {
    await _getFullPath();
    final text = await FlutterTesseractOcr.extractText(
      imagePath,
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

    saveText(text);

    await Speech().speak(
        "La lecture va commencer. Appuyer sur l'écran pour passer un paragraphe. Appuyez deux fois pour arrêter la lecture.");

    setState(() {
      _index = 0;
      _readSentences();
    });
  }

  Future _readSentences() async {
    await Speech().stop();

    while (_index < _text.length) {
      await _readSentenceByIndex(_index);
      setState(() {
        _index += 1;
      });
    }

    await Speech().speak("Fin de la lecture. Retour au menu.");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Home();
        },
      ),
    );
  }

  Future _readSentenceByIndex(int index) async {
    _scrollToSentence(index);
    await Speech().speak(_text[index].text);
  }

  _scrollToSentence(int index) async {
    RenderBox? box =
        _text[index].key.currentContext?.findRenderObject() as RenderBox?;

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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        color: Colors.black,
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
                    fontSize: 20.0,
                    fontWeight: _index == i ? FontWeight.w800 : FontWeight.w400,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      onTap: () async {
        setState(() {
          _index += 1;
          _readSentences();
        });
      },
      onDoubleTap: () async {
        setState(() {
          _index = -1;
        });
        await Speech().stop();
        Speech().speak("Lecture arrêtée. Retour au menu.");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Home();
            },
          ),
        );
      },
    );
  }
}
