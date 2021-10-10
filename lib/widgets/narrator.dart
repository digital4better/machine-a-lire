import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:malo/services/speech.dart';

class Narrator extends StatefulWidget {
  const Narrator({
    Key? key,
    this.image,
  }) : super(key: key);

  final Future<CameraImage>? image;

  @override
  NarratorState createState() => NarratorState();
}

class NarratorState extends State<Narrator> {
  void _startNarration() async {
    await Speech()
        .speak("La lecture va commencer, appuyez sur l’écran pour l’arrêter");
    await Speech().speak(
        "Alice, assise auprès de sa sœur sur le gazon, commençait à s’ennuyer de rester là à ne rien faire ; une ou deux fois elle avait jeté les yeux sur le livre que lisait sa sœur ; mais quoi ! pas d’images, pas de dialogues ! « La belle avance, » pensait Alice, « qu’un livre sans images, sans causeries ! »");
  }

  @override
  void dispose() {
    Speech().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      child: FutureBuilder<void>(
          future: widget.image,
          builder: (context, snapshot) {
            // If the Future is complete, display the preview.
            if (snapshot.connectionState == ConnectionState.done) {
              _startNarration();
              return Container(color: Color.fromARGB(255, 0, 255, 0));
            }
            // Otherwise, display a loading indicator.
            else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
      onTap: () {
        Speech().speak("Lecture arrêtée");
        Navigator.pop(context);
      });
}
