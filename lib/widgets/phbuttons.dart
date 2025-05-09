import 'dart:ui';

import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/phlutter/material_state_property_utils.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/phlutter/scroll_listener.dart';

class Phbuttons {
  static const double windowTitleBarHeight = 32;

  static Widget openFiles({double width = 40.0}) {
    final toolTipText =
        'Open images... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFiles)})';

    return PfsAppModel.scope(
      (context, __, model) {
        final style = FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        );

        return Tooltip(
          message: toolTipText,
          child: FilledButton(
            style: style,
            onPressed: () => _popupImagesMenu(model),
            child: SizedBox(
              width: width,
              child: const Icon(browseIcon),
            ),
          ),
        );
      },
    );
  }

  static Widget textThenIcon(String text, Icon icon, {double spacing = 3}) {
    return Row(
      children: [
        Text(text),
        SizedBox(width: spacing),
        icon,
      ],
    );
  }

  static Widget timerSettingsButton({required Function() onPressed}) {
    return PhtimerModel.scope(
      (_, __, model) {
        final currentTimerSeconds = model.currentDurationSeconds;
        const iconSize = PfsTheme.timerButtonIconSize;

        return Tooltip(
          message: '$currentTimerSeconds seconds per image.\n'
              '${PfsLocalization.pressCapital} to edit timer. '
              '(${PfsLocalization.tooltipShortcut(Phshortcuts.openTimerMenu)})',
          child: TextButton(
            onPressed: onPressed,
            child: textThenIcon('${currentTimerSeconds}s',
                const Icon(Icons.timer_outlined, size: iconSize)),
          ),
        );
      },
    );
  }

  static Widget nextPreviousOnScrollListener({
    required PfsAppModel model,
    Widget? child,
  }) {
    return ScrollListener(
      onScrollDown: () => model.nextImageNewTimer(),
      onScrollUp: () => model.previousImageNewTimer(),
      child: child,
    );
  }

  static double squeezeRemap({
    required double inputValue,
    required double iMin,
    required double iThreshold,
    required double oMin,
    required double oRegular,
  }) {
    double remap(double iMin, double iMax, double oMin, double oMax, double v) {
      double inverseLerp(double a, double b, double v) => (v - a) / (b - a);
      double t = inverseLerp(iMin, iMax, v);
      return lerpDouble(oMin, oMax, t) ?? oMin;
    }

    final bool shouldRemap = inputValue < iThreshold;
    final double output = shouldRemap
        ? remap(iMin, iThreshold, oMin, oRegular, inputValue)
        : oRegular;
    return output;
  }
}

void _popupImagesMenu(PfsAppModel model) {
  popUpContextualMenu(
    _getOpenImagesMenu(model),
    placement: Placement.topLeft,
  );
}

Menu _getOpenImagesMenu(PfsAppModel model) {
  return Menu(
    items: [
      MenuItem(
        label: 'Open images...',
        onClick: (menuItem) {
          model.openFilePickerForImages();
        },
      ),
      MenuItem.separator(),
      MenuItem(
        label: 'Open image folder...',
        onClick: (menuItem) {
          model.openFilePickerForFolder();
        },
      ),
      MenuItem(
        label: 'Open folder and subfolders...',
        onClick: (menuItem) {
          model.openFilePickerForFolder(includeSubfolders: true);
        },
      )
    ],
  );
}

class ImageSetButton extends StatelessWidget {
  const ImageSetButton({
    super.key,
    this.narrowButton = false,
    this.extraTooltip,
  });

  static const double _iconSize = 18;
  static const Icon _icon = Icon(Icons.image, size: _iconSize);

  final bool narrowButton;
  final String? extraTooltip;

  @override
  Widget build(BuildContext context) {
    return PfsAppModel.scope((_, __, model) {
      final fileCount = model.fileList.getCount();
      final lastFolder = model.lastFolder;
      final String tooltip = '${(extraTooltip != null ? "$extraTooltip\n\n" : "")}Folder: .../$lastFolder\n'
          '$fileCount ${PfsLocalization.imageNoun(fileCount)} loaded.';

      const double wideWidth = 80;
      const double narrowWidth = 18;

      final double currentWidth = narrowButton ? narrowWidth : wideWidth;

      return Tooltip(
        message: tooltip,
        child: TextButton(
          onPressed: () => _popupImagesMenu(model),
          child: AnimatedSizedBoxWidth(
            defaultWidth: narrowWidth,
            width: currentWidth,
            height: 28,
            duration: Phanimations.defaultDuration,
            child: Align(
              alignment: Alignment.center,
              child: OverflowBox(
                maxWidth: currentWidth,
                child: Row(
                  children: [
                    const Spacer(),
                    narrowButton
                        ? _icon
                        : Phbuttons.textThenIcon(fileCount.toString(), _icon),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class MinorWindowControlButton extends StatelessWidget {
  const MinorWindowControlButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
  });

  final Function()? onPressed;
  final IconData icon;
  final String? tooltip;

  static const double iconSize = 20;
  static const buttonSize = Size(20, 20);

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;
    final foregroundColors = hoverColors(
      idle: iconColor.withAlpha(0x44),
      hover: iconColor.withAlpha(0xDD),
    );

    final buttonStyle = ButtonStyle(
      shape: const WidgetStatePropertyAll(CircleBorder()),
      minimumSize: const WidgetStatePropertyAll(buttonSize),
      maximumSize: const WidgetStatePropertyAll(buttonSize),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(0)),
      foregroundColor: foregroundColors,
    );

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: buttonStyle,
      iconSize: iconSize,
      icon: Icon(icon),
    );
  }
}

class CollapseBottomBarButton extends StatelessWidget {
  const CollapseBottomBarButton({
    super.key,
    required this.isMinimized,
    required this.onPressed,
  });

  final bool isMinimized;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    const collapseIcon = Icons.expand_more_rounded;
    const expandIcon = Icons.expand_less_rounded;

    final bottomBarShortcutKey =
        PfsLocalization.tooltipShortcut(Phshortcuts.toggleBottomBar);

    if (isMinimized) {
      return MinorWindowControlButton(
        icon: expandIcon,
        tooltip: 'Expand controls ($bottomBarShortcutKey)',
        onPressed: onPressed,
      );
    } else {
      return MinorWindowControlButton(
        icon: collapseIcon,
        tooltip: 'Minimize controls ($bottomBarShortcutKey)',
        onPressed: onPressed,
      );
    }
  }
}
