import 'package:flutter/material.dart';

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
}
