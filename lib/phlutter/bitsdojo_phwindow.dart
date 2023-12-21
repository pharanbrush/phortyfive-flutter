import 'package:flutter/material.dart';

class KeepWindowOnTopButton extends StatefulWidget {
  const KeepWindowOnTopButton({
    super.key,
    this.notifier,
  });

  final ValueNotifier<bool>? notifier;

  @override
  State<KeepWindowOnTopButton> createState() => _KeepWindowOnTopButtonState();
}

class _KeepWindowOnTopButtonState extends State<KeepWindowOnTopButton> {
  late ValueNotifier<bool> notifier = widget.notifier ?? ValueNotifier(false);
  void toggleNotifier() => notifier.value = !notifier.value;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, value, __) {
        return IconButton(
          style: const ButtonStyle(
            iconSize: MaterialStatePropertyAll(16),
            shape: MaterialStatePropertyAll(LinearBorder()),
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
