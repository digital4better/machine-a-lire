import 'dart:io';

import 'package:flutter/material.dart';
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
        "Scan du ${now.toIso8601String().substring(0, 19)}"; //${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Sauvegarder le document"),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 15,
              ),
              TextField(
                style: TextStyle(color: Colors.white),
                controller: _textController,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Wrap(
                  direction: Axis.horizontal,
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    Button(
                      buttonText: "Enregistrer",
                      buttonOnPressed: () async {
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
                    Button(
                      buttonText: "Annuler",
                      buttonOnPressed: () async {
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
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
