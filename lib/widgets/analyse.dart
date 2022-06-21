import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:malo/components/backButton.dart';
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

void _detectQuadAndWarp(SendPort sendPort) async {
  ReceivePort spawnReceivePort = ReceivePort();
  sendPort.send(spawnReceivePort.sendPort);

  await for (dynamic msg in spawnReceivePort) {
    var data = msg[0];

    if (data is XFile) {
      var width = msg[1];
      var height = msg[2];
      SendPort replyTo = msg[3];

      try {
        Detection detectionFromPicture =
            detectQuadFromShot(data, width, height);
        Quad quad = Quad.from(detectionFromPicture);

        if (!quad.isEmpty) {
          warpShot(data, quad, data.path, width, height);
        }

        replyTo.send(quad);
      } catch (_) {
        replyTo.send(Quad.empty);
      }
    }

    if (data is String && data == "close") {
      spawnReceivePort.close();
    }
  }
}

/// sends a message on a port, receives the response,
/// and returns the message
Future sendReceiveAnalyse(SendPort port, msg, width, height) {
  ReceivePort response = new ReceivePort();
  port.send([msg, width, height, response.sendPort]);
  return response.first;
}

class AnalyseState extends State<Analyse> {
  late ReceivePort _receivePort;
  late SendPort _sendPort;

  Future _analysePicture() async {
    XFile picture = XFile(widget.imagePath);
    // Detect quad from taken picture.
    var decodedImage = await decodeImageFromList(await picture.readAsBytes());
    Quad quadFromPicture = await sendReceiveAnalyse(
        _sendPort, picture, decodedImage.width, decodedImage.height);

    sendReceive(_sendPort, "close");

    if (quadFromPicture.isEmpty) {
      // No quad found, then try again.
      Speech().speak("La détection a échouée. Réesayer.", context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Vision();
          },
        ),
      );
    } else {
      // Go to narrator screen
      Navigator.pushReplacement(
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

  Future _init() async {
    // Then start analyse.
    await _initIsolatePort();
    _analysePicture();
  }

  /// Detecting quad is an heavy task, that's why it will be delegate in an isolate port.
  /// In order to avoid UI freeze.
  Future _initIsolatePort() async {
    _receivePort = ReceivePort();

    await Isolate.spawn<SendPort>(
      _detectQuadAndWarp,
      _receivePort.sendPort,
    );

    _sendPort = await _receivePort.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Semantics(
          child: Text("Analyse du document"),
          label:
              "Analyse du document. Document capturé. En cours de traitement. Patientez.",
        ),
        leading: MaloBackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
    );
  }
}
