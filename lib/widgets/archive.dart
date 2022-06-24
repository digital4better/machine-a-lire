import 'dart:io';

import 'package:flutter/material.dart';
import 'package:malo/components/archiveItem.dart';
import 'package:malo/components/backButton.dart';
import 'package:path_provider/path_provider.dart';

class Archive extends StatefulWidget {
  const Archive({Key? key}) : super(key: key);

  @override
  State<Archive> createState() => _ArchiveState();
}

class _ArchiveState extends State<Archive> {
  List<FileSystemEntity> filesList = [];

  @override
  void initState() {
    super.initState();
    _getFilesList();
  }

  Future _getFilesList() async {
    Directory('${(await getApplicationDocumentsDirectory()).path}/scans')
        .create()
        .then((Directory dir) {
      setState(() {
        filesList = dir.listSync();
      });
    });
  }

  void _onUpdate() async {
    await _getFilesList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Documents sauvegardés"),
        leading: MaloBackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (!filesList.isEmpty) ...[
            Expanded(
              child: Scrollbar(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 50.0,
                  ),
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return ArchiveItem(
                      filePath: filesList[index].path,
                      onUpdate: _onUpdate,
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(height: 20);
                  },
                  itemCount: filesList.length,
                ),
              ),
            ),
          ] else ...[
            Expanded(child: Container()),
            Text(
              "Aucun document sauvegardé.",
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            Expanded(child: Container()),
          ]
        ],
      ),
    );
  }
}
