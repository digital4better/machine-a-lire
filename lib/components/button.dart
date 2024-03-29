import 'package:flutter/material.dart';

class MaloButton extends StatelessWidget {
  const MaloButton({
    Key? key,
    required this.text,
    required this.onPress,
    this.prefixImage,
  }) : super(key: key);

  final String text;
  final VoidCallback onPress;
  final String? prefixImage;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        primary: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(60),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (this.prefixImage != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Image(
                  image: AssetImage(this.prefixImage!),
                  height: 20,
                ),
              ),
            Text(
              text,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
