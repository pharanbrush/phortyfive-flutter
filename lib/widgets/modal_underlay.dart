import 'package:flutter/material.dart';
import 'package:pfs2/widgets/panels/modal_dismiss_context.dart';

class ModalUnderlay extends StatelessWidget {
  const ModalUnderlay({
    super.key,
    this.onDismiss,
    this.isTransparent = false,
  });

  final Function()? onDismiss;
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    final dismissFunction =
        onDismiss ?? ModalDismissContext.of(context)?.onDismiss ?? () {};

    return ModalBarrier(
      dismissible: true,
      onDismiss: dismissFunction,
      color: isTransparent
          ? Colors.transparent
          : Theme.of(context).colorScheme.scrim,
    );
  }
}
