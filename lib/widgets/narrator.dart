import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:malo/components/backButton.dart';
import 'package:malo/components/button.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/saveScan.dart';

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
  final _controller = ScrollController();
  late String textToSave;
  List<Span> _text = [];
  int _index = -1;

  void _saveDocument() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SaveScan(text: textToSave);
        },
      ),
    );
  }

  @override
  void initState() {
    _parseText();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _parseText() async {
    final text = widget.isTextExtracted
        ? await File(widget.path).readAsString()
        : await FlutterTesseractOcr.extractText(
            widget.path,
            language: 'fra',
            args: {
              "psm": "1",
              "preserve_interword_spaces": "1",
            },
          );

    if (!widget.isTextExtracted) {
      Speech().speak("Texte prêt à la lecture.");
    }

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

    // TODO : try a rotation of 180° with same image in case doc was upside down.

    setState(() {
      textToSave = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Lecture du document"),
        leading: MaloBackButton(),
      ),
      body: _text.isNotEmpty
          ? SingleChildScrollView(
              controller: _controller,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 100),
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
                            fontWeight:
                                _index == i ? FontWeight.w800 : FontWeight.w400,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.hourglass_top,
                    size: 60,
                    color: Colors.white,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      "Document en cours de traitement.\nMerci de patienter.",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: !widget.isTextExtracted && _text.isNotEmpty
          ? MaloButton(onPress: _saveDocument, text: "Sauvegarder le document")
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
