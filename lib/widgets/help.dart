import 'package:flutter/material.dart';
import 'package:malo/components/tutorialSection.dart';

class Help extends StatelessWidget {
  const Help({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Aides"),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TutorialSection(
                      sectionTitle: 'Qu\'est ce que MALO ?',
                      sectionText:
                          'MALO est une application permettant nottamment aux personnes mal-voyantes de scanner un document papier, et de lire son texte à voix haute.',
                    ),
                    TutorialSection(
                        sectionTitle: 'Comment scanner un document ?',
                        sectionText:
                            'Pour scanner un document, lancez un nouveau scan, puis placez la feuille face au téléphone. Des vibrations vous indiquent si le document n\'est pas bien cadré. Quand le document est bien lisible, une photo est prise, et une analyse est lancée. Après quelques secondes, le texte imprimé est alors affiché à l\'écran de votre téléphone.'),
                    TutorialSection(
                        sectionTitle: 'Historique des scans',
                        sectionText:
                            'Vous pouvez retrouver dans l\'historique les documents que vous avez sauvegardé. Depuis l\'historique, vous pouvez lire, supprimer ou encore renommer un scan'),
                    TutorialSection(
                        sectionTitle:
                            'Le texte détécté est incorrect, que faire ?',
                        sectionText:
                            'Si la detection ne fonctionne pas assez bien, assurez vous d\'être bien statique lors de la prise de la photo. Vous pouvez aussi essayer de changer d\'arrière plan pour améliorer le contraste de couleurs.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
