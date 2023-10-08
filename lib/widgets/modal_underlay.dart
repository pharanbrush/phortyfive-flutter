import 'package:flutter/material.dart';

class ModalUnderlay extends StatelessWidget {
  const ModalUnderlay({super.key, this.onTapDown, this.isTransparent = false});

  final Function()? onTapDown;
  final bool isTransparent;

  static const fadeColor = Colors.white60;

  @override
  Widget build(BuildContext context) {
    return ModalBarrier(
      dismissible: true,
      onDismiss: onTapDown,
      color: isTransparent ? Colors.transparent : fadeColor,
    );
  }
}
