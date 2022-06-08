import 'package:flutter/material.dart';
import 'package:malo/components/button.dart';
import 'package:malo/widgets/history.dart';
import 'package:malo/widgets/vision.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/images/app_splash.png'),
        SizedBox(
          height: 40,
        ),
        Button(
          buttonText: "Effectuer un nouveau scan",
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
        Button(
          buttonText: "Consulter l'historique des scans",
          buttonOnPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return History();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
