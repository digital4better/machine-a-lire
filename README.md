# MALO

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