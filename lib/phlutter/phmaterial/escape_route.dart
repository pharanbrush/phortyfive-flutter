import 'package:flutter/widgets.dart';

class EscapeNavigator extends InheritedWidget {
  EscapeNavigator({
    super.key,
    required super.child,
  });

  final stack = <EscapeRoute>[];

  static EscapeNavigator? of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<EscapeNavigator>()
        as EscapeNavigator;
  }

  void push(EscapeRoute route) {
    if (stack.isNotEmpty) {
      final current = stack.last;
      if (current.name == route.name) {
        return;
      }
    }

    stack.add(route);
  }

  void tryEscape() {
    if (stack.isEmpty) return;

    final current = stack.last;
    current.onEscape.call();
    if (current.willPopOnEscape) stack.removeLast();
  }

  void tryPop(String name) {
    if (stack.isEmpty) return;

    final current = stack.last;
    if (current.name == name) {
      stack.removeLast();
    }
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

class EscapeRoute {
  EscapeRoute({
    required this.name,
    required this.onEscape,
    required this.willPopOnEscape,
  });

  final String name;
  final void Function() onEscape;
  final bool willPopOnEscape;
}
