# MALO (english)

MALO is an Open Source Reading Machine developed by Digital4Better for ACIAH, an association working
for the support and inclusion of people with disabilities. The application allows blind or visually
impaired people to vocalise the content of a paper document.

## Technical Description

The first step in the process is to accurately detect the document you wish to to vocalise. The
image also needs to be processed in order to detect the text in optimal conditions. A custom library
based on opencv and written in C++ was created and integrated into the project to provide functions
for document detection and image processing. It is structured as a flutter sub-project, named 
"native_opencv".

Once the document has been detected and the image processed, the latter is passed to an OCR (optical
character recognition), which allows the translation of text in an image into digital text. In our 
case, the OCR we use is Tesseract.

## Possible improvements

Some improvements could be made to MALO. Here are some possible improvements.

### Android / iOS

Currently, a separate branch allows the application to run on iOS. This is due to the structure of 
the native_opencv library within the project. We have not found a single architecture that allows 
the application to run on Android and iOS simultaneously. However, it is certainly possible to 
reconcile the two branches.

### Document Orientation Detection

Currently, the application is not able to detect whether the document is turned 180° or not. This is
because SwiftyTesseract, the iOS plugin used to implement Tesseract, does not let us choose which 
OCR mode to use (psm), and therefore does not let us detect the orientation of the text during 
detection. However, on Android, it is possible to choose the psm mode, so the OCR returns a 
confidence index of the document orientation. We could use this index to deduce whether or not we 
should rotate the sheet by 180°.
Note that the rotation function has been implemented in the native_opencv plugin, and is ready to 
use.

### Text Detection

Text detection can of course always be improved, although it is quite good at the moment.

- Other OCRs exist, some of which could give us better results.
- The image pre-processing could be improved to allow the OCR to work in the best possible 
conditions, although its current state is satisfactory.
- A spell checker could be implemented to perfect the text detected by the OCR. However, having 
explored this solution, it has some major drawbacks: increased computation time, and dependence on 
an internet connection to call the API.

# MALO (français)

MALO est une Machine A Lire Open Source développée par Digital4Better pour l'ACIAH, une association
oeuvrant pour l'accompagnement et l'inclusion des personnes atteintes de handicap. L'application 
permet notamment aux personnes non ou mal voyantes de vocaliser le contenu d'un document papier.

## Présentation Technique

La première étape du processus consiste à détecter précisement le docuement que l'on souhaite
vocaliser. Il faut aussi traiter l'image pour effectuer la detection du texte dans des conditions
optimales. Une librairie personnalisée basée sur opencv et écrite en c++ a été créée et intégrée au
projet pour apporter des fonctions permettant la détection du document et le traitement de l'image.
Elle est structurée sous la forme d'un sous projet flutter, nommé "native_opencv".

Une fois le document détecté et l'image traitée , cette dernière est passée dans un OCR (optical
character recognition), qui permet la traduction du texte dans une image en texte numérique. Dans
notre cas, l'OCR que nous utilisons est Tesseract.

## Améliorations possibles

Quelques améliorations pourraient être apportées à MALO. Voici quelques pistes d'amélioration.

### Android / iOS

Actuellement, une branche séparée permet à l'application de fonctionner sur iOS. Ceci est dû à la
structure de la librairie native_opencv au sein du projet. Nous n'avons en effet par trouvé
d'architecture unique permettant à l'application de fonctionner sur Android et iOS simultanément.
Cependent, il est certainement possible de concilier les deux branches.

### Detection du sens du document

Actuellement, l'application n'est pas en mesure de detecter si le document est retourné à 180° ou
non. Ceci est dû au fait que SwiftyTesseract, le plugin iOS utilisé pour l'implémentation de 
Tesseract, ne nous laisse pas le choix dans l'utilisation du mode d'OCR (psm), et ne nous laisse
donc pas détecter l'orientation du texte lors de la detection.
Ceci dit, sur Android, il est possible de choisir le mode de psm, et l'OCR nous renvoit donc un
indice de confiance d'orientation du document. Nous pourrions utiliser cet indice pour retourner ou
non la feuille de 180°.
Notons que la fonction de rotation a été implémentée dans le plugin native_opencv, et est prête à
l'emploi.

### Detection du texte

La detection du texte peut bien évidemment toujours être améliorée, même si elle est plutôt 
satisfaisante à l'heure actuelle.

 - D'autres OCR existent, certains pourraient nous donner de meilleurs résultats.
 - Le pré-traitement de l'image pourrait être amélioré pour permettre à l'OCR de fonctionner dans
les meilleures conditions possibles, bien que son état actuel soit satisfaisant.
 - Un correcteur orthographique pourrait être implémenté pour parfaire le texte detecté par l'OCR.
Ceci dit, après avoir exploré cette solution, elle présente des inconvénients majeurs :
prolongement du temps de calcul, et dépendance à une connexion internet pour faire appel à l'API.

## Ressources 
- https://dropbox.tech/machine-learning/fast-and-accurate-document-detection-for-scanning
- https://github.com/flutter-clutter/flutter-simple-edge-detection
- https://www.flutterclutter.dev/flutter/tutorials/implementing-edge-detection-in-flutter/2020/1509/
- https://developer.apple.com/documentation/vision/vndetectrectanglesrequest
- https://hochgatterer.me/blog/invoice-scanning/
