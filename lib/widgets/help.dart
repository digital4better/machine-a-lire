import 'package:flutter/material.dart';
import 'package:malo/components/backButton.dart';
import 'package:malo/components/tutorialSection.dart';

class Help extends StatelessWidget {
  const Help({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Foire aux questions"),
        leading: MaloBackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      TutorialSection(
                        sectionTitle: 'Qu\'est ce que MALO ?',
                        sectionText:
                            'MALO est une application permettant aux personnes mal voyantes, non voyantes, ou ayant des troubles de lecture de numériser un document, pour pouvoir le restituer à voix haute (grâce à TalkBack ou VoiceOver).',
                      ),
                      TutorialSection(
                        sectionTitle: 'Comment numériser un document ?',
                        sectionText:
                            'Pour numériser un nouveau document, appuyez sur le bouton du menu d\'accueil nommé "Numériser un document". \nEnsuite, placez votre document en face de votre appareil.\nDes vibrations vous guideront, plus le document est bien cadré, plus les vibrations seront rapprochées.\nQuand le document est bien lisible, une analyse est lancée. Après quelques secondes, le texte est alors affiché à l\'écran.',
                      ),
                      TutorialSection(
                        sectionTitle: 'Documents sauvegardés',
                        sectionText:
                            'Vous pouvez retrouver les documents que vous avez sauvegardés depuis le bouton du menu d\'accueil nommé "Documents sauvegardés". Depuis ce menu, vous pouvez lire, renommer ou supprimer un document.',
                      ),
                      TutorialSection(
                        sectionTitle:
                            'Le texte détecté est incorrect, que faire ?',
                        sectionText:
                            'Si la détection ne fonctionne pas assez bien, assurez-vous d\'être bien statique lors de la prise de la photo. Vous pouvez aussi essayer de changer d\'arrière-plan pour améliorer le contraste de couleurs.',
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
