import 'package:flutter/material.dart';

class FirstActionSheet extends StatelessWidget {
  const FirstActionSheet({super.key});

  static const windowAlignmentMargin = EdgeInsets.fromLTRB(0, 0, 25, 45);

  @override
  Widget build(BuildContext context) {
    const double iconSize = 100;
    final Color boxColor = Colors.grey.shade100;
    final Color borderColor = Colors.grey.shade200;
    const Color contentColor = Colors.black38;
    const TextStyle textStyleMain = TextStyle(
      color: contentColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    const TextStyle textStyleSecondary = TextStyle(
      color: contentColor,
    );

    const Icon icon = Icon(Icons.image, size: iconSize, color: contentColor);
    const Icon downIcon =
        Icon(Icons.keyboard_double_arrow_down_rounded, color: contentColor);

    final box = SizedBox(
      width: 350,
      height: 250,
      child: Material(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(color: borderColor),
            color: boxColor,
          ),
          child: Stack(children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 25,
                ),
                icon,
                Text(
                  'Get started by loading images!',
                  style: textStyleMain,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'You can also drag & drop images into the window.',
                  style: textStyleSecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                child: downIcon,
              ),
            ),
          ]),
        ),
      ),
    );

    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: windowAlignmentMargin,
        child: box,
      ),
    );
  }
}
