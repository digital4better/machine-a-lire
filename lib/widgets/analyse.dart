import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/narrator.dart';
import 'package:malo/widgets/vision.dart';
import 'package:native_opencv/native_opencv.dart';

class Analyse extends StatefulWidget {
  Analyse(this.imagePath);

  final String imagePath;

  @override
  AnalyseState createState() => AnalyseState();
}

class AnalyseState extends State<Analyse> {
  Future _init() async {
    // Then start analyse.
    _analysePicture();
  }

  Future _analysePicture() async {
    XFile picture = XFile(widget.imagePath);

    // Detect quad from taken picture.
    Detection detectionFromPicture = await detectQuadFromShot(picture);
    Quad quadFromPicture = Quad.from(detectionFromPicture);

    setState(() {});

    if (quadFromPicture.isEmpty) {
      // No quad found, then try again.
      await Speech().speak("La détection a échouée. Réesayer.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Vision();
          },
        ),
      );
    } else {
      // Quad found, warped it for better text detection.
      await warpShot(picture, quadFromPicture, widget.imagePath);

      // Go to narrator screen
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Narrator(widget.imagePath);
          },
        ),
      );
    }
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Semantics(
            child: Text("Analyse du document"),
            label:
                "Analyse du document. Document capturé. En cours de traitement. Patientez.",
          ),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "Document capturé. En cours de traitement. Patientez.",
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
      ),
    );
  }
}
