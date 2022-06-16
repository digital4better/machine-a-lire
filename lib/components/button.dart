import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({
    Key? key,
    required this.buttonText,
    required this.buttonOnPressed,
    this.textSize = 15,
    this.innerPadding = true,
  }) : super(key: key);

  final String buttonText;
  final VoidCallback buttonOnPressed;
  final double textSize;
  final bool innerPadding;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      height: 30,
      buttonColor: Colors.white,
      child: OutlinedButton(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: innerPadding ? 10 : 0),
          child: Text(
            buttonText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: textSize,
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            width: 2,
            color: Colors.white,
          ),
        ),
        onPressed: buttonOnPressed,
      ),
    );
  }
}
