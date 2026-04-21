import 'package:flutter/material.dart';

class SmallHeading extends StatelessWidget {
  const SmallHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final smallHeadingStyle = Theme.of(context).textTheme.titleSmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: smallHeadingStyle),
    );
  }
}
