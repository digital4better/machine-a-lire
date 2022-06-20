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
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              widget.sectionTitle,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.white, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10),
          margin: EdgeInsets.only(top: 5, bottom: 30),
          child: Text(
            widget.sectionText,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
