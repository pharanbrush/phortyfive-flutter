import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ModalPanel {
  ModalPanel({
    required this.builder,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.onBeforeOpen,
    this.onClosed,
    this.onOpened,
    this.isUnderlayTransparent = false,
  });

  static const defaultDuration = Duration(milliseconds: 200);
  static const fastDuration = Duration(milliseconds: 100);

  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  final Widget Function() builder;
  final Function()? onBeforeOpen;
  final Function()? onOpened;

  final Function()? onClosed;
  final bool isUnderlayTransparent;

  final ValueNotifier<bool> _isOpen = ValueNotifier(false);

  bool get isOpen => _isOpen.value;

  ValueListenable<bool> get openStateListenable => _isOpen;

  void open() {
    onBeforeOpen?.call();
    _isOpen.value = true;
    onOpened?.call();
  }

  void close() {
    _isOpen.value = false;
    onClosed?.call();
  }

  Widget widget(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _isOpen,
      builder: (_, value, __) {
        return ModalDismissContext(
          onDismiss: close,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: fastDuration,
                child: value
                    ? (isUnderlayTransparent
                        ? const ModalUnderlay.transparent()
                        : const ModalUnderlay())
                    : null,
              ),
              AnimatedSwitcher(
                transitionBuilder: transitionBuilder,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                duration: defaultDuration,
                reverseDuration: fastDuration,
                child: value ? builder() : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModalUnderlay extends StatelessWidget {
  const ModalUnderlay({
    super.key,
    this.onDismiss,
    this.isTransparent = false,
  });

  const ModalUnderlay.transparent({super.key, this.onDismiss})
      : isTransparent = true;

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
