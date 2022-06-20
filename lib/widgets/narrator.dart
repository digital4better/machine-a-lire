import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
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
    Speech().stop();
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
        automaticallyImplyLeading: true,
      ),
      body: _text.isNotEmpty
          ? SingleChildScrollView(
              controller: _controller,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 60,
                ),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Analyse du texte. Patientez.",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Icon(
                    Icons.hourglass_top,
                    size: 60,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
      floatingActionButton: !widget.isTextExtracted && _text.isNotEmpty
          ? FloatingActionButton(
              onPressed: _saveDocument,
              backgroundColor: Colors.white,
              child: Semantics(
                hint: "Sauvegarder le document",
                child: Icon(
                  Icons.save,
                  color: Colors.black,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}
