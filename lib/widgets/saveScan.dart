import 'dart:io';

import 'package:flutter/material.dart';
import 'package:malo/components/button.dart';
import 'package:path_provider/path_provider.dart';

import 'home.dart';

class SaveScan extends StatefulWidget {

  const SaveScan({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  State<SaveScan> createState() => _SaveScanState();
}

void _saveScan(String scanName, String text) async {
  Directory('${(await getApplicationDocumentsDirectory()).path}/scans')
      .create()
      .then((Directory dir) => File('${dir.path}/${scanName}.txt')
      .writeAsString(text));
}

class _SaveScanState extends State<SaveScan> {

  TextEditingController _textController =  TextEditingController();

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _textController.text = "Scan du ${now.toIso8601String().substring(0, 19)}";//${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  "Nom du document scanné :",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
              ),
            ),
            SizedBox(height: 15,),
            TextField(
              style: TextStyle(color: Colors.white),
              controller: _textController,
              decoration: InputDecoration(
                focusedBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white, width: 3.0),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                hintText: "Entrez le nom du document scanné",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 1,
                  child: Button(
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
                ),
                Flexible(
                  flex: 1,
                  child: Button(
                    buttonText: "Valider",
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
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
