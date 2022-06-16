import 'package:flutter/material.dart';
import 'package:malo/components/button.dart';
import 'package:malo/widgets/archive.dart';
import 'package:malo/widgets/vision.dart';

import 'help.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/app_splash.png'),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Button(
                  textSize: 24,
                  buttonText: "Scanner un document",
                  buttonOnPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return Vision();
                        },
                      ),
                    );
                  },
                ),
                Padding(padding: EdgeInsets.only(top: 30)),
                Button(
                  textSize: 24,
                  buttonText: "Documents archivés",
                  buttonOnPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return Archive();
                        },
                      ),
                    );
                  },
                ),
                Padding(padding: EdgeInsets.only(top: 30)),
                Button(
                  textSize: 24,
                  buttonText: "Besoin d'aide ?",
                  buttonOnPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return Help();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
