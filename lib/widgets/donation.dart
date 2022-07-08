import 'package:flutter/material.dart';
import 'package:malo/components/backButton.dart';
import 'package:malo/components/button.dart';
import 'package:url_launcher/url_launcher.dart';

class Donation extends StatelessWidget {
  const Donation({Key? key}) : super(key: key);

  static const String donationUrl =
      "https://www.helloasso.com/associations/aciah/formulaires/1";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Faire un don"),
        leading: MaloBackButton(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Text(
                          "C’est grâce à vos dons que l’ACIAH peut oeuvrer pour un numérique accessible à tous.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: SizedBox(
                          height: 100,
                          child: Image(
                            image: AssetImage("assets/images/aciah.png"),
                            width: 70,
                            fit: BoxFit.scaleDown,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Text(
                          "MALO est une initiative portée par l’association ACIAH (Accessibilité, Communication, Information, Accompagnement du Handicap).\n\nL’application est et restera gratuite pour rester accessible à tous.\n\nPour mener à bien tous ses projets, l’ACIAH a besoin de fonds. En soutenant l’ACIAH vous participez au changement.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: MaloButton(
                          prefixIcon: Icons.accessibility_sharp,
                          text: "Faire un don",
                          onPress: () async {
                            try {
                              await launchUrl(Uri.parse(donationUrl));
                            } catch (e) {
                              throw 'Could not launch $donationUrl (reason: $e)';
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
