import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

class Speech {
  speak(String text) async {
    final AnnounceSemanticsEvent event = AnnounceSemanticsEvent(
      text,
      TextDirection.ltr,
    );

    await SystemChannels.accessibility.send(event.toMap());
  }
}
