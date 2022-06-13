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
  late List<int> isIndexClicked;

  @override
  void initState() {
    super.initState();
    _getFilesList();
  }

  Future<void> _getFilesList() async {
    Directory('${(await getApplicationDocumentsDirectory()).path}/scans')
        .create()
        .then((Directory dir) {
      setState(() {
        filesList = dir.listSync();
        isIndexClicked = List.filled(filesList.length, 0);
      });
    });
  }

  void startReading(String filePath) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Narrator(
            filePath,
            isTextExtracted: true,
          );
        },
      ),
    );
  }

  void _deleteScan(String filePath) async {
    await File(filePath).delete();
    _getFilesList();
    setState(() {});
  }

  void _renameScan(String filePath, String newName) async {

    int lastSeparator = filePath.lastIndexOf(Platform.pathSeparator);
    String newPath = filePath.substring(0, lastSeparator + 1) + newName + ".txt";

    await File(filePath).rename(newPath);

    _getFilesList();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState((){
            isIndexClicked = List.filled(filesList.length, 0);
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
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
              innerPadding: true,
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
                        if(isIndexClicked[index] == 0) {
                          return Button(
                            textSize: 15,
                            buttonText: filePath.substring(
                                filePath.indexOf('scans/') + 6, filePath.length - 4
                            ),
                            buttonOnPressed: () {
                              List<int> isIndexClickedNew = List.filled(filesList.length, 0);
                              isIndexClickedNew[index] = 1;
                              setState((){
                                isIndexClicked = isIndexClickedNew;
                              });
                            },
                          );
                        }
                        else if (isIndexClicked[index] == 1) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Button(
                                textSize: 15,
                                buttonText: "Lire",
                                buttonOnPressed: (){startReading(filePath);},
                              ),
                              Button(
                                textSize: 15,
                                buttonText: "Supprimer",
                                buttonOnPressed: (){_deleteScan(filePath);},
                              ),
                              Button(
                                textSize: 15,
                                buttonText: "Modifier",
                                buttonOnPressed: (){
                                  List<int> isIndexClickedNew = List.filled(filesList.length, 0);
                                  isIndexClickedNew[index] = 2;
                                  setState((){
                                    isIndexClicked = isIndexClickedNew;
                                  });
                                },
                              ),
                            ],
                          );
                        } else {
                          TextEditingController _textController =  TextEditingController();
                          _textController.text = filePath.substring(
                              filePath.indexOf('scans/') + 6, filePath.length - 4
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    style: TextStyle(color: Colors.white),
                                    controller: _textController,
                                    decoration: InputDecoration(
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: const BorderSide(color: Colors.white, width: 3.0),
                                      ),
                                      enabledBorder: const OutlineInputBorder(
                                        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                      ),
                                      hintText: "Entrez le nouveau nom du document",
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Button(
                                    textSize: 15,
                                    buttonText: "Valider",
                                    buttonOnPressed: (){_renameScan(filePath, _textController.text);}
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          height: 0,
                        );
                      },
                      itemCount: filesList.length
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
