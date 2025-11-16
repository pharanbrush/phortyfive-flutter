import 'package:flutter/widgets.dart';

class ModelScope<T> extends InheritedWidget {
  const ModelScope({
    super.key,
    required super.child,
    required this.model,
  });

  final T model;

  @override
  bool updateShouldNotify(ModelScope<T> oldWidget) {
    return oldWidget.model != model;
  }
}
