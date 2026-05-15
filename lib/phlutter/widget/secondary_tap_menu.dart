import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

const kResetValueLabel = "Reset value";

typedef MenuBuilderCallback = void Function(Menu menu);

extension MenuExtensions on Menu {
  MenuItem addMenuItem(String label, {VoidCallback? onClick}) {
    final menuItem = MenuItem(label);
    addItem(menuItem);
    if (onClick != null) {
      menuItem.on<MenuItemClickedEvent>((_) => onClick());
    }
    return menuItem;
  }

  MenuItem addMenuItemObject(MenuItem menuItem) {
    addItem(menuItem);
    menuItem.enabled = menuItem.enabled;
    menuItem.state = menuItem.state;
    return menuItem;
  }
}

class SecondaryTapMenu extends StatelessWidget {
  const SecondaryTapMenu({
    super.key,
    required this.menuBuilder,
    required this.child,
  });

  final MenuBuilderCallback menuBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: () {
        final menu = Menu();
        menuBuilder(menu);
        menu.open(PositioningStrategy.cursorPosition());
      },
      child: child,
    );
  }
}

class SecondaryTapResetMenu extends SecondaryTapMenu {
  SecondaryTapResetMenu({
    super.key,
    String label = "Reset",
    required VoidCallback action,
    required super.child,
  }) : super(
         menuBuilder: (menu) => menu.addMenuItem(label, onClick: action),
       );
}

extension SecondaryTapExtensions on Widget {
  SecondaryTapMenu secondaryTapMenu({
    Key? key,
    required MenuBuilderCallback menuBuilder,
  }) {
    return SecondaryTapMenu(
      key: key,
      menuBuilder: menuBuilder,
      child: this,
    );
  }

  SecondaryTapResetMenu resetMenu({
    Key? key,
    String label = "Reset",
    required VoidCallback action,
  }) {
    return SecondaryTapResetMenu(
      label: label,
      action: action,
      child: this,
    );
  }

  SecondaryTapResetMenu resetNotifierToZeroMenu({
    Key? key,
    String label = kResetValueLabel,
    required ValueNotifier<num> notifier,
  }) {
    return SecondaryTapResetMenu(
      label: label,
      action: (notifier.value is double)
          ? () => notifier.value = 0.0
          : () => notifier.value = 0,
      child: this,
    );
  }

  SecondaryTapResetMenu resetNotifierToOneMenu({
    Key? key,
    String label = kResetValueLabel,
    required ValueNotifier<num> notifier,
  }) {
    return SecondaryTapResetMenu(
      label: label,
      action: (notifier.value is double)
          ? () => notifier.value = 1.0
          : () => notifier.value = 1,
      child: this,
    );
  }

  SecondaryTapResetMenu resetNotifierToNullMenu<T>({
    Key? key,
    String label = kResetValueLabel,
    required ValueNotifier<T?> notifier,
  }) {
    return SecondaryTapResetMenu(
      label: label,
      action: () => notifier.value = null,
      child: this,
    );
  }
}
