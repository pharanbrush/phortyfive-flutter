import 'package:flutter/material.dart';

class ModalUnderlay extends StatelessWidget {
  const ModalUnderlay({super.key, this.onTapDown, this.isTransparent = false});

  final Function()? onTapDown;
  final bool isTransparent;

  static const fadeStyle = BoxDecoration(color: Colors.white60);
  static const transparentStyle = BoxDecoration(color: Colors.transparent);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTapDown: (details) => onTapDown!(),
        child:
            Container(decoration: isTransparent ? transparentStyle : fadeStyle),
      ),
    );
  }
}
