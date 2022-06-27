import 'dart:html';

import 'package:flutter/material.dart';
import 'package:native_opencv/native_opencv.dart';

String lastSnackBarMessage = "";

class Speech {
  speak(String text, context) {
    if (text != lastSnackBarMessage) {
      ScaffoldMessenger.of(context).clearSnackBars();

      lastSnackBarMessage = text;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ));
    }
  }

  stop(context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  bool checkBorder( Point point1, Point point2) {
    if(
    point1.y < 0.05 && point2.y < 0.05 ||
        point1.y > 0.95 && point2.y > 0.95 ||
        point1.x < 0.05 && point2.x < 0.05 ||
        point1.x > 0.95 && point2.x > 0.95
    ){
      return true;
    } else {
      return false;
    }
  }

  List<bool> _detectSidesOnBorder(Quad quad) {
    bool right = checkBorder(quad.topRight, quad.topLeft);
    bool left = checkBorder(quad.bottomRight, quad.bottomLeft);
    bool bottom = checkBorder(quad.topRight, quad.bottomRight);
    bool top = checkBorder(quad.topLeft, quad.bottomLeft);

    List<bool> sidesOnBorder = [top, right, bottom, left];
    return sidesOnBorder;
  }

  String getSpeech(Quad quad, num widthPercent) {

    num widthDetectionThreshold = 0.75;

    if(quad.isEmpty){
      return "Aucun document détecté";
    }

    if(quad.isOnBorder){
      List<bool> sidesOffScreen = _detectSidesOnBorder(quad);
      int numberOfSidesOffscreen = 0;
      for(bool element in sidesOffScreen) {
        if(element)numberOfSidesOffscreen++;
      }

      if(numberOfSidesOffscreen > 1){
        return "Reculez";
      }
      List<String> directions = ["le haut", "la droite", "le bas", "la gauche"];
      for(int i = 0; i < 4; i++){
        if (sidesOffScreen[i]) {
          return "Décalez vers ${directions[i]}";
        };
      }
    }
    if (widthPercent > widthDetectionThreshold) {
        return "Ne bougez plus, document détecté";
    }
    return "Rapprochez l'appareil";
  }
}
