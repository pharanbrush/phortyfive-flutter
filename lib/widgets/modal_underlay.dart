import 'package:flutter/material.dart';

class ModalUnderlay extends StatelessWidget {
  const ModalUnderlay({super.key, this.onDismiss, this.isTransparent = false});

  final Function()? onDismiss;
  final bool isTransparent;

  static const fadeColor = Colors.white60;

  @override
  Widget build(BuildContext context) {
    return ModalBarrier(
      dismissible: true,
      onDismiss: onDismiss,
      color: isTransparent ? Colors.transparent : fadeColor,
    );
  }
}
