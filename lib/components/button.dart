import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({
    Key? key,
    required this.buttonText,
    required this.buttonOnPressed
  }) : super(key: key);

  final String buttonText;
  final VoidCallback buttonOnPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ButtonTheme(
          minWidth: double.infinity,
          height: 40,
          buttonColor: Colors.white,
          child: OutlinedButton(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child : Text(
                buttonText,
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
            onPressed: buttonOnPressed
          )
      ),
    );
  }
}
