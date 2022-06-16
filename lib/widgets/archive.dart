import 'dart:io';

import 'package:flutter/material.dart';
import 'package:malo/components/archiveItem.dart';
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Archives"),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Focus(
                  autofocus: true,
                  child: ListView.separated(
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
            ],
          ),
        ),
      ),
    );
  }
}
