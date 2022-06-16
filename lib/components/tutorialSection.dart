import 'package:flutter/material.dart';

class TutorialSection extends StatefulWidget {
  const TutorialSection({
    Key? key,
    required this.sectionTitle,
    required this.sectionText,
  }) : super(key: key);

  final String sectionTitle;
  final String sectionText;

  @override
  State<TutorialSection> createState() => _TutorialSectionState();
}

class _TutorialSectionState extends State<TutorialSection> {
  bool isOpened = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          onTapHint: isOpened
              ? widget.sectionTitle + " fermer"
              : widget.sectionTitle + " ouvrir",
          child: ElevatedButton(
            child: Text(
              widget.sectionTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size.fromHeight(30),
              primary: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isOpened = !isOpened;
              });
            },
          ),
        ),
        if (isOpened) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.white),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10),
            margin: EdgeInsets.only(top: 5, bottom: 30),
            child: Text(
              widget.sectionText,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ]
      ],
    );
  }
}
