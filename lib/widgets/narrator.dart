import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:malo/services/speech.dart';

class Narrator extends StatefulWidget {
  Narrator(this.path);

  final String path;

  @override
  NarratorState createState() => NarratorState();
}

class NarratorState extends State<Narrator> {

  @override
  void initState() {
    super.initState();
    Speech().stop();
    Speech().speak("La lecture va commencer, appuyez sur l’écran pour l’arrêter");
    Speech().speak("Alice, assise auprès de sa sœur sur le gazon, commençait à s’ennuyer de rester là à ne rien faire ; une ou deux fois elle avait jeté les yeux sur le livre que lisait sa sœur ; mais quoi ! pas d’images, pas de dialogues ! « La belle avance, » pensait Alice, « qu’un livre sans images, sans causeries ! »");
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      child: Container(color: Color.fromARGB(255, 0, 255, 0), child: Image.file(File(widget.path))),
      onTap: () {
        Speech().stop();
        Speech().speak("Lecture arrêtée");
        Navigator.pop(context);
      });
}
