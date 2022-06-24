import 'package:flutter/material.dart';

class MaloBackButton extends StatelessWidget {
  const MaloBackButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Ink(
        decoration: const ShapeDecoration(
          color: Colors.white,
          shape: CircleBorder(),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            semanticLabel: "Retour",
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
