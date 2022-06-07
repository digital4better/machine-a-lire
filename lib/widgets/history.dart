import 'dart:io';
import 'package:flutter/material.dart';
import 'package:malo/widgets/narrator.dart';
import 'package:path_provider/path_provider.dart';

import 'analyse.dart';


class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {

  late String _imagesStoragePath;
  List<FileSystemEntity> filesList = [];

  @override
  void initState() {
    super.initState();
    _getFilesList();
  }

  void _getFilesList() async {
    String imagesStoragePath = (await getApplicationDocumentsDirectory()).path;
    setState(() {
      filesList = Directory('$imagesStoragePath/scans').listSync();
    });
  }

  void startReading (int index) async {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Narrator(filesList[index].path, isTextExtracted: true,);
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: Colors.black,
        child: ListView.separated(
          itemBuilder: (BuildContext context, int index) {
            return TextButton(
                onPressed: () {startReading(index);},
                child: Text(
                    filesList[index].path,
                    style: TextStyle(color: Colors.white),
                )
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return SizedBox(height: 5,);
          },
          itemCount: filesList.length)
    );
  }
}