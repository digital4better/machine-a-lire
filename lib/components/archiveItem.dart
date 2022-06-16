import 'dart:io';

import 'package:flutter/material.dart';
import 'package:malo/components/button.dart';
import 'package:malo/widgets/narrator.dart';

class ArchiveItem extends StatefulWidget {
  const ArchiveItem({
    Key? key,
    required this.filePath,
    required this.onUpdate,
  }) : super(key: key);

  final String filePath;
  final VoidCallback onUpdate;

  @override
  State<ArchiveItem> createState() => _ArchiveItemState();
}

class _ArchiveItemState extends State<ArchiveItem> {
  late String _fileName;
  TextEditingController _textController = TextEditingController();

  void _startReading() async {
    Navigator.of(context).pop();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Narrator(
            widget.filePath,
            isTextExtracted: true,
          );
        },
      ),
    );
  }

  void _deleteScan() async {
    await File(widget.filePath).delete();
    Navigator.of(context).pop();
    widget.onUpdate();
  }

  void _renameScan(String newName) async {
    // Update saved file name.
    int lastSeparator = widget.filePath.lastIndexOf(Platform.pathSeparator);
    String newPath =
        widget.filePath.substring(0, lastSeparator + 1) + newName + ".txt";
    await File(widget.filePath).rename(newPath);

    // Update widget properties.
    _fileName = newName;
    setState(() {});

    Navigator.of(context).pop();

    widget.onUpdate();
  }

  @override
  initState() {
    _fileName = widget.filePath.substring(
        widget.filePath.indexOf('scans/') + 6, widget.filePath.length - 4);

    super.initState();
  }

  Widget _buildItem() {
    return Button(
      buttonText: _fileName,
      buttonOnPressed: () {
        showDialog(
          context: context,
          useSafeArea: true,
          barrierColor: Colors.white.withAlpha(210),
          builder: (context) {
            return SimpleDialog(
              backgroundColor: Colors.black,
              elevation: 1,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              title: Column(
                children: [
                  Text("Que voulez vous faire ?", textAlign: TextAlign.center),
                ],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              children: _buildOptionsList(),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildOptionsList() {
    return [
      Button(
        buttonText: "Lire",
        buttonOnPressed: () {
          _startReading();
        },
      ),
      Padding(padding: EdgeInsets.only(top: 20)),
      Button(
        buttonText: "Supprimer",
        buttonOnPressed: () {
          _deleteScan();
        },
      ),
      Padding(padding: EdgeInsets.only(top: 20)),
      Button(
        buttonText: "Renommer",
        buttonOnPressed: () {
          _textController.text = _fileName;
          _showRename();
        },
      ),
      Padding(padding: EdgeInsets.only(top: 20)),
      Button(
        buttonText: "Fermer",
        buttonOnPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ];
  }

  void _showRename() {
    Navigator.of(context).pop();

    showDialog(
      context: context,
      useSafeArea: true,
      barrierColor: Colors.white.withAlpha(210),
      builder: (context) {
        return SimpleDialog(
          backgroundColor: Colors.black,
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          title: Column(
            children: [
              Text("Renommer le document", textAlign: TextAlign.center),
            ],
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          children: [
            TextField(
              style:
                  TextStyle(color: Colors.black, backgroundColor: Colors.white),
              controller: _textController,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                focusedBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white, width: 3.0),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                hintText: "Saisir le nouveau nom du document",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Wrap(
                  direction: Axis.horizontal,
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    Button(
                      buttonText: "Enregistrer",
                      buttonOnPressed: () {
                        _renameScan(_textController.text);
                      },
                    ),
                    Button(
                      buttonText: "Annuler",
                      buttonOnPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildItem();
  }

  @override
  dispose() {
    _textController.dispose();
    super.dispose();
  }
}
