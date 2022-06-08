import 'dart:io';

import 'package:flutter/material.dart';
import 'package:malo/components/button.dart';
import 'package:malo/widgets/narrator.dart';
import 'package:path_provider/path_provider.dart';

import 'home.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<FileSystemEntity> filesList = [];

  @override
  void initState() {
    super.initState();
    _getFilesList();
  }

  void _getFilesList() async {
    Directory('${(await getApplicationDocumentsDirectory()).path}/scans')
        .create()
        .then((Directory dir) {
      setState(() {
        filesList = dir.listSync();
      });
    });
  }

  void startReading(int index) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Narrator(
            filesList[index].path,
            isTextExtracted: true,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Historique des scans",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Button(
          buttonText: "Retourner au menu",
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
        Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.black,
            child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  String filePath = filesList[index].path;
                  return Button(
                    buttonText: filePath.substring(
                        filePath.indexOf('scans/') + 6, filePath.length - 4),
                    buttonOnPressed: () {
                      startReading(index);
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 5,
                  );
                },
                itemCount: filesList.length)),
      ],
    );
  }
}
