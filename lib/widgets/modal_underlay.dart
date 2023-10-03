import 'package:flutter/material.dart';

class ModalUnderlay extends StatelessWidget {
  const ModalUnderlay({super.key, this.onTapDown});

  final Function()? onTapDown;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTapDown: (details) => onTapDown!(),
        child:
            Container(decoration: const BoxDecoration(color: Colors.white60)),
      ),
    );
  }
}
