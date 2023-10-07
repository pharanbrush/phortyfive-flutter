import 'package:flutter/material.dart';

class OverlayButton extends StatelessWidget {
  OverlayButton({super.key, required this.child, this.onPressed});

  final Widget child;
  final Function()? onPressed;

  static Color getIconColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return const Color(0xFF242424);
    }

    return Colors.transparent;
  }

  static Color getButtonColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return const Color(0x22DDDDDD);
    }

    return Colors.transparent;
  }

  final ButtonStyle style = ButtonStyle(
    shape: MaterialStateProperty.all(
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
    ),
    iconColor: MaterialStateProperty.resolveWith(getIconColor),
    overlayColor: MaterialStateProperty.resolveWith(getButtonColor),
  );

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: TextButton(
        style: style,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
