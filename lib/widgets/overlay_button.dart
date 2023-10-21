import 'package:flutter/material.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';

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
    shape: MaterialStateProperty.all(shape),
    iconColor: PfsTheme.hoverColors(
      idle: iconColor.withAlpha(0x00),
      hover: iconColor,
    ),
    overlayColor: PfsTheme.hoverColors(
      idle: hoverAreaColor.withAlpha(0x00),
      hover: hoverAreaColor,
    ),
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
