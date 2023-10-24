import 'package:flutter/material.dart';

class PanelDismissContext extends InheritedWidget {
  const PanelDismissContext({
    super.key,
    required this.onDismiss,
    required super.child,
  });

  final VoidCallback? onDismiss;

  static PanelDismissContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PanelDismissContext>();
  }

  @override
  bool updateShouldNotify(PanelDismissContext oldWidget) {
    return true;
  }
}
