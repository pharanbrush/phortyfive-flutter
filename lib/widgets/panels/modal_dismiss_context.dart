import 'package:flutter/material.dart';

class ModalDismissContext extends InheritedWidget {
  const ModalDismissContext({
    super.key,
    required this.onDismiss,
    required super.child,
  });

  final VoidCallback? onDismiss;

  static ModalDismissContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ModalDismissContext>();
  }

  @override
  bool updateShouldNotify(ModalDismissContext oldWidget) {
    return true;
  }
}
