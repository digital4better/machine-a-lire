
import 'package:flutter/material.dart';
import 'package:malo/components/button.dart';
import 'package:accordion/accordion.dart';
import 'home.dart';

class Help extends StatelessWidget {
  const Help({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Comment utiliser MALO ?',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30,),
            Accordion(
                maxOpenSections: 1,
                headerBackgroundColor: Colors.white,
                children: [
                  AccordionSection(
                      contentBackgroundColor: Colors.black,
                      contentBorderColor: Colors.white,
                      header: Text(
                        'Qu\'est ce que MALO ?',
                        //style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'MALO est une application permettant nottamment aux personnes mal-voyantes de scanner un document papier, et de lire son texte à voix haute.',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ),
                  AccordionSection(
                    contentBackgroundColor: Colors.black,
                    contentBorderColor: Colors.white,
                    header: Text(
                      'Comment scanner un document ?',
                      //style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'Pour scanner un document, lancez un nouveau scan, puis placez la feuille face au téléphone. Des vibrations vous indiquent si le document n\'est pas bien cadré. Quand le document est bien lisible, une photo est prise, et une analyse est lancée. Après quelques secondes, le texte imprimé est alors affiché à l\'écran de votre téléphone.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AccordionSection(
                    contentBackgroundColor: Colors.black,
                    contentBorderColor: Colors.white,
                    header: Text(
                      'Historique des scans',
                      //style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'Vous pouvez retrouver dans l\'historique les documents que vous avez sauvegardé. Depuis l\'historique, vous pouvez lire, supprimer ou encore renommer un scan',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AccordionSection(
                    contentBackgroundColor: Colors.black,
                    contentBorderColor: Colors.white,
                    header: Text(
                      'Le texte détécté est incorrect, que faire ?',
                      //style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'Si la detection ne fonctionne pas assez bien, assurez vous d\'être bien statique lors de la prise de la photo. Vous pouvez aussi essayer de changer d\'arrière plan pour améliorer le contraste de couleurs.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]
            ),
            Expanded(child: Container()),
            Button(
              buttonText: "Retourner au menu",
              buttonOnPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return Home();
                    },
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
