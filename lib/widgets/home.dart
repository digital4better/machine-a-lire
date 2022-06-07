import 'package:flutter/material.dart';
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
        SizedBox(height: 40,),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ButtonTheme(
              minWidth: double.infinity,
              height: 40,
              buttonColor: Colors.white,
              child: OutlinedButton(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child : Text(
                    "Effectuer un nouveau scan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(width: 5, color: Colors.white)
                ),
                onPressed: () async {
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Vision();
                      },
                    ),
                  );
                },
              )
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ButtonTheme(
              minWidth: double.infinity,
              height: 40,
              buttonColor: Colors.white,
              child: OutlinedButton(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child : Text(
                  "Consulter l'historique des scans",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(width: 5, color: Colors.white)
                ),
                onPressed: () async {
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return History();
                      },
                    ),
                  );
                },
              )
          ),
        ),
      ],
    );
  }
}
