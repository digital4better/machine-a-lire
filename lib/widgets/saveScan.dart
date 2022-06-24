import 'dart:io';

import 'package:flutter/material.dart';
import 'package:malo/components/backButton.dart';
import 'package:malo/components/button.dart';
import 'package:malo/widgets/home.dart';
import 'package:path_provider/path_provider.dart';

class SaveScan extends StatefulWidget {
  const SaveScan({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  State<SaveScan> createState() => _SaveScanState();
}

class _SaveScanState extends State<SaveScan> {
  TextEditingController _textController = TextEditingController();

  void _saveScan(String scanName, String text) async {
    if (text.isEmpty) {
      // TODO warn user.
      return;
    }

    Directory('${(await getApplicationDocumentsDirectory()).path}/scans')
        .create()
        .then((Directory dir) =>
            File('${dir.path}/${scanName}.txt').writeAsString(text));
  }

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _textController.text =
        "Document du ${now.toIso8601String().substring(0, 19)}"; //${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Sauvegarder le document"),
        leading: MaloBackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          style: TextStyle(color: Colors.white),
                          controller: _textController,
                          autofocus: true,
                          decoration: InputDecoration(
                            label: Text(
                              "Nom du document",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 3.0,
                              ),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            hintText: "Saisir le nom du document",
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MaloButton(
                        text: "Sauvegarder",
                        onPress: () async {
                          _saveScan(_textController.text, widget.text);
                          await Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return Home();
                              },
                            ),
                          );
                        },
                      ),
                      const Padding(padding: EdgeInsets.only(bottom: 30)),
                      MaloButton(
                        text: "Annuler",
                        onPress: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const Padding(padding: EdgeInsets.only(bottom: 30)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
