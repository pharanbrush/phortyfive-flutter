import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart' as bitsdojo;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/themes/window_button_colors.dart';

class PfsWindowState {
  bool rightControlsOrientation = true;
  bool isTouch = false;

  final isBottomBarMinimized = ValueNotifier(false);
  final isAlwaysOnTop = ValueNotifier(false);
  final isSoundsEnabled = ValueNotifier(true);

  final bottomBarHeight = ValueNotifier<double>(0);
}

class WindowWrapper extends StatelessWidget {
  const WindowWrapper({
    super.key,
    required this.child,
    required this.windowState,
  });

  final Widget child;
  final PfsWindowState windowState;

  @override
  Widget build(BuildContext context) {
    Widget titlebar() {
      final theme = Theme.of(context);
      final borderSide = theme.extension<PfsAppTheme>()?.appWindowBorderSide;
      final titleBarColor =
          borderSide == null ? Colors.transparent : borderSide.color;

      final isLeftSidedControls = Platform.isMacOS;

      return bitsdojo.WindowTitleBarBox(
        child: Container(
          decoration: BoxDecoration(color: titleBarColor),
          child: RepaintBoundary(
            child: Row(
              children: [
                if (isLeftSidedControls) SizedBox(width: 70),
                if (isLeftSidedControls)
                  KeepWindowOnTopButton(notifier: windowState.isAlwaysOnTop),
                Expanded(
                  child: Stack(
                    children: [
                      if (!isLeftSidedControls)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              Image.memory(
                                PfsTheme.pfsIconBytes,
                                filterQuality: FilterQuality.medium,
                                color: const Color(0x7EFFFFFF),
                                colorBlendMode: BlendMode.modulate,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                PfsLocalization.appTitle,
                                style: TextStyle(
                                    color: Color(0x7E999999), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      bitsdojo.MoveWindow(),
                    ],
                  ),
                ),
                if (!isLeftSidedControls)
                  KeepWindowOnTopButton(notifier: windowState.isAlwaysOnTop),
                if (!isLeftSidedControls) const WindowButtons(),
              ],
            ),
          ),
        ),
      );
    }

    Widget windowBorderWrapper(BuildContext context, {required Widget child}) {
      final theme = Theme.of(context);
      final borderSide = theme.extension<PfsAppTheme>()?.appWindowBorderSide;
      final double borderSideWidth = borderSide?.width ?? 0;

      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: borderSideWidth,
              right: borderSideWidth,
              bottom: borderSideWidth,
            ),
            child: child,
          ),
          Column(
            children: [
              titlebar(),
              Expanded(child: Container()),
            ],
          ),
          if (borderSide != null)
            Material(
              type: MaterialType.transparency,
              shape: Border(
                bottom: borderSide,
                left: borderSide,
                right: borderSide,
              ),
              child: const SizedBox.expand(),
            )
        ],
      );
    }

    return windowBorderWrapper(context, child: child);
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLightTheme =
        Theme.of(context).colorScheme.brightness == Brightness.light;

    final buttonColors =
        isLightTheme ? buttonColorsOnLight : buttonColorsOnDark;

    final closeButtonColors =
        isLightTheme ? closeButtonColorsOnLight : closeButtonColorsOnDark;

    return Row(
      children: [
        bitsdojo.MinimizeWindowButton(colors: buttonColors),
        bitsdojo.MaximizeWindowButton(colors: buttonColors),
        bitsdojo.CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

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
              ? "Click to disable Keep window on top"
              : "Click to enable Keep window on top",
          icon: value
              ? const Icon(FluentIcons.pin_12_filled)
              : const Icon(FluentIcons.pin_12_regular),
          onPressed: toggleNotifier,
        );
      },
    );
  }
}
