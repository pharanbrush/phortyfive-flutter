import 'package:flutter/material.dart';

class KeepWindowOnTopButton extends StatelessWidget {
  const KeepWindowOnTopButton({
    super.key,
    required this.notifier,
  });

  final ValueNotifier<bool> notifier;
  void toggleNotifier() => notifier.value = !notifier.value;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, value, __) {
        return IconButton(
          style: const ButtonStyle(
            iconSize: WidgetStatePropertyAll(16),
            shape: WidgetStatePropertyAll(LinearBorder()),
          ),
          isSelected: value,
          tooltip: value
              ? 'Click to disable Keep window on top'
              : 'Click to enable Keep window on top',
          icon: value
              ? const Icon(Icons.picture_in_picture_alt)
              : const Icon(Icons.picture_in_picture_alt_outlined),
          onPressed: toggleNotifier,
        );
      },
    );
  }
}
