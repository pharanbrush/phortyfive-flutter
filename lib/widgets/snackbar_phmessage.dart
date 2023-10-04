import 'package:flutter/material.dart';

class SnackbarPhmessage extends StatelessWidget {
  const SnackbarPhmessage({super.key, required this.text, this.icon});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const Color textColor = Colors.white;

    return Row(children: [
      Icon(icon, color: textColor),
      const SizedBox(width: 10),
      Text(text)
    ]);
  }
}
