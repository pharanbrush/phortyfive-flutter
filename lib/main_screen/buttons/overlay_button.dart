import 'package:flutter/material.dart';
import 'package:pfs2/phlutter/material_state_property_utils.dart';

class OverlayButton extends StatelessWidget {
  const OverlayButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  final Widget child;
  final Function()? onPressed;

  static const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );

  static const iconColor = Color(0xFF242424);
  static const hoverAreaColor = Color(0x22DDDDDD);

  static final ButtonStyle style = ButtonStyle(
    shape: WidgetStateProperty.all(shape),
    iconColor: hoverColors(
      idle: iconColor.withAlpha(0x00),
      hover: iconColor,
    ),
    overlayColor: hoverColors(
      idle: hoverAreaColor.withAlpha(0x00),
      hover: hoverAreaColor,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: style,
      onPressed: onPressed,
      child: child,
    );
  }
}
