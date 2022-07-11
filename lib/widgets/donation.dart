import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:malo/components/backButton.dart';
import 'package:malo/components/button.dart';
import 'package:url_launcher/url_launcher.dart';

class Donation extends StatefulWidget {
  const Donation({Key? key}) : super(key: key);

  @override
  State<Donation> createState() => _DonationState();
}

class _DonationState extends State<Donation> {
  static const String donationUrl =
      "https://www.helloasso.com/associations/aciah/formulaires/1";

  TextEditingController _textController = TextEditingController();
  late StreamSubscription<dynamic> _subscription;

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      // if (purchaseDetails.status == PurchaseStatus.pending) {
      //   _showPendingUI();
      // } else {
      //   if (purchaseDetails.status == PurchaseStatus.error) {
      //     _handleError(purchaseDetails.error!);
      //   } else if (purchaseDetails.status == PurchaseStatus.purchased ||
      //       purchaseDetails.status == PurchaseStatus.restored) {
      //     bool valid = await _verifyPurchase(purchaseDetails);
      //     if (valid) {
      //       _deliverProduct(purchaseDetails);
      //     } else {
      //       _handleInvalidPurchase(purchaseDetails);
      //     }
      //   }
      //   if (purchaseDetails.pendingCompletePurchase) {
      //     await InAppPurchase.instance.completePurchase(purchaseDetails);
      //   }
      // }
    });
  }

  Future _doPurchase() async {
    // TODO : set the right kId here once it's created in appstoreconnect.apple.com.
    // const Set<String> _kIds = <String>{'donation'};
    // final ProductDetailsResponse response =
    //     await InAppPurchase.instance.queryProductDetails(_kIds);
    //
    // if (response.notFoundIDs.isNotEmpty) {
    //   // Handle the error.
    // }
    //
    // List<ProductDetails> products = response.productDetails;
    // final ProductDetails productDetails = products.first;
    // final PurchaseParam purchaseParam =
    //     PurchaseParam(productDetails: productDetails);

    print(_textController.text);

    //InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
  }

  @override
  void initState() {
    if (Platform.isIOS) {
      final Stream purchaseUpdated = InAppPurchase.instance.purchaseStream;
      _subscription = purchaseUpdated.listen((purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      }, onDone: () {
        _subscription.cancel();
      }, onError: (error) {
        // handle error here.
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      _subscription.cancel();
    }

    _textController.dispose();

    super.dispose();
  }

  Widget _buildDonation() {
    if (Platform.isAndroid) {
      return _buildAndroidDonation();
    } else {
      return _buildIosDonation();
    }
  }

  Widget _buildIosDonation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: TextField(
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            controller: _textController,
            decoration: InputDecoration(
              label: Text(
                "Montant du don",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Colors.white,
                  width: 3.0,
                ),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
              hintText: "Saisir le montant de votre don",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        MaloButton(
          prefixImage: "assets/images/heart.png",
          text: "Faire un don",
          onPress: () async {
            try {
              await _doPurchase();
            } catch (e) {
              throw 'Could not launch $donationUrl (reason: $e)';
            }
          },
        ),
      ],
    );
  }

  Widget _buildAndroidDonation() {
    return MaloButton(
      prefixImage: "assets/images/heart.png",
      text: "Faire un don",
      onPress: () async {
        try {
          await launchUrl(Uri.parse(donationUrl));
        } catch (e) {
          throw 'Could not launch $donationUrl (reason: $e)';
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Faire un don"),
        leading: MaloBackButton(),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                child: _buildDonation(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
