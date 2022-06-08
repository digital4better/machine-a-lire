import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:malo/services/speech.dart';
import 'package:malo/widgets/narrator.dart';
import 'package:malo/widgets/vision.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:path_provider/path_provider.dart';

class Analyse extends StatefulWidget {
  Analyse(this.imagePath);

  final String imagePath;

  @override
  AnalyseState createState() => AnalyseState();
}

class AnalyseState extends State<Analyse> {
  Future<String> _getFullPath() async {
    return '${(await getTemporaryDirectory()).path}/${widget.imagePath}';
  }

  Future _init() async {
    await Speech()
        .speak("Document capturé. En cours de traitement. Patientez.");

    // Then start analyse.
    _analysePicture();
  }

  Future _analysePicture() async {
    String fullPath = await _getFullPath();

    XFile picture = XFile(fullPath);

    // Detect quad from taken picture.
    Detection detectionFromPicture = await detectQuadFromShot(picture);
    Quad quadFromPicture = Quad.from(detectionFromPicture);

    setState(() {});

    if (quadFromPicture.isEmpty) {
      // No quad found, then try again.
      await Speech().speak(
          "Oups, la détection du document à échouée. Veuillez réesayer de capture votre document.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Vision();
          },
        ),
      );
    } else {
      await Speech().speak(
          "Détection du document réussie. Patientez encore un peu, le texte est en cours d'analyse.");

      // Quad found, warped it for better text detection.
      await warpShot(picture, quadFromPicture, fullPath);

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
    return Center(
      child: GestureDetector(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                Center(child: CircularProgressIndicator(color: Colors.blue)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
