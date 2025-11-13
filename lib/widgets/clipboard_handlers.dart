import 'package:flutter/widgets.dart';

typedef ClipboardCopyTextHandler = void Function(
    {required String text, String? toastMessage});

class ClipboardHandlers extends InheritedWidget {
  const ClipboardHandlers({
    super.key,
    required super.child,
    required this.copyText,
    required this.copyCurrentImage,
  });

  final ClipboardCopyTextHandler copyText;
  final VoidCallback copyCurrentImage;

  static ClipboardHandlers? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ClipboardHandlers>();
  }

  @override
  bool updateShouldNotify(ClipboardHandlers oldWidget) {
    return true;
  }
}
