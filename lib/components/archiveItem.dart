import 'dart:io';

import 'package:flutter/material.dart';
import 'package:malo/components/button.dart';
import 'package:malo/components/outlinedButton.dart';
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

  showOptions() {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Material(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            constraints: const BoxConstraints.expand(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Text(
                        "Que souhaitez-vous faire ?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: _buildOptionsList()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      barrierDismissible: false,
      barrierColor: Colors.black,
      barrierLabel: '',
    );
  }

  Widget _buildOptionsList() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MaloButton(
          text: "Lire ce document",
          onPress: () {
            _startReading();
          },
        ),
        Padding(padding: EdgeInsets.only(top: 20)),
        MaloButton(
          text: "Le renommer",
          onPress: () {
            _textController.text = _fileName;
            _showRename();
          },
        ),
        Padding(padding: EdgeInsets.only(top: 20)),
        MaloButton(
          text: "Le supprimer",
          onPress: () {
            _deleteScan();
          },
        ),
        Padding(padding: EdgeInsets.only(top: 20)),
        MaloButton(
          text: "Revenir à la liste",
          onPress: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildItem() {
    return MaloOutlinedButton(
      text: _fileName,
      onPress: showOptions,
    );
  }

  void _showRename() {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Material(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            constraints: const BoxConstraints.expand(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Text(
                        "Renommer le document",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                                onPress: () {
                                  _renameScan(_textController.text);
                                },
                              ),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 30)),
                              MaloButton(
                                text: "Annuler",
                                onPress: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 30)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      barrierDismissible: false,
      barrierColor: Colors.black,
      barrierLabel: '',
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
