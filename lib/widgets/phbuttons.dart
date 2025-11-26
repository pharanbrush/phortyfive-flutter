import 'dart:ui';

import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/phlutter/material_state_property_utils.dart';
import 'package:pfs2/phlutter/sized_box_fitted.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/phlutter/scroll_listener.dart';

class Phbuttons {
  static const double windowTitleBarHeight = 32;

  static Widget openFiles({double width = 40.0, required PfsAppModel model}) {
    final toolTipText =
        'Open images... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFiles)})';

    return Builder(
      builder: (context) {
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
      spacing: spacing,
      children: [
        Text(text),
        Transform.translate(offset: Offset(0, 1), child: icon),
      ],
    );
  }

  static Widget timerSettingsButton({
    required Function() onPressed,
    required PhtimerModel timerModel,
  }) {
    return ListenableBuilder(
      listenable: timerModel.durationChangeNotifier,
      builder: (_, __) {
        final currentTimerSeconds = timerModel.currentDurationSeconds;
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
      final double t = inverseLerp(iMin, iMax, v);
      return lerpDouble(oMin, oMax, t) ?? oMin;
    }

    final bool shouldRemap = inputValue < iThreshold;
    final double output = shouldRemap
        ? remap(iMin, iThreshold, oMin, oRegular, inputValue)
        : oRegular;
    return output;
  }
}

class PanelCloseButton extends StatelessWidget {
  const PanelCloseButton({
    super.key,
    required this.onPressed,
  });

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 25,
      height: 25,
      child: IconButton.filled(
        tooltip: "Close panel",
        padding: EdgeInsets.all(2.0),
        onPressed: onPressed,
        icon: Icon(Icons.close, size: 15),
        //hoverColor: Colors.red,
      ),
    );
  }
}

// nativeapi API

// void _popupImagesMenu(PfsAppModel model) {
//   Menu getOpenImagesMenu(PfsAppModel model) {
//     return Menu()
//       ..addItem(
//         MenuItem("Open images...")
//           ..on<MenuItemClickedEvent>((_) => model.openFilePickerForImages()),
//       )
//       ..addSeparator()
//       ..addItem(
//         MenuItem("Open images...")
//           ..on<MenuItemClickedEvent>((_) => model.openFilePickerForFolder())
//       )
//       ..addItem(
//         MenuItem("Open folder and subfolders...")..on<MenuItemClickedEvent>(
//           (_) => model.openFilePickerForFolder(includeSubfolders: true),
//         ),
//       );
//   }

//   final menu = getOpenImagesMenu(model);
//   menu.open(PositioningStrategy.cursorPosition(), Placement.topStart);
// }

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
    required this.model,
  });

  static const double _iconSize = 17;
  static const Icon _icon = Icon(Icons.image, size: _iconSize);

  final bool narrowButton;
  final String? extraTooltip;
  final PfsAppModel model;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: model.imageListChangedNotifier,
        builder: (context, __) {
          final fileCount = model.imageList.getCount();
          final lastFolder = model.lastFolder;
          final String tooltip =
              '${(extraTooltip != null ? "$extraTooltip\n\n" : "")}Folder: .../$lastFolder\n'
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
                            : Phbuttons.textThenIcon(
                                fileCount.toString(), _icon),
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

class IconAndText extends StatelessWidget {
  const IconAndText({
    super.key,
    required this.text,
    required this.icon,
    this.iconSize,
    this.gap,
  });

  final String text;
  final IconData icon;
  final double? iconSize;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double usedFontSize = (theme.textTheme.labelLarge?.fontSize ?? 12);
    final usedIconSize = iconSize ?? usedFontSize * 1.45;
    final usedGap = gap ?? usedFontSize * 0.6;

    return Row(
      spacing: usedGap,
      children: [
        Transform.translate(
          offset: Offset(0, 1),
          child: Icon(icon, size: usedIconSize),
        ),
        Text(text),
      ],
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

class PfsPopupMenuButton<T> extends PopupMenuButton<T> {
  const PfsPopupMenuButton({
    required super.itemBuilder,
    super.key,
    super.borderRadius,
    super.child,
    super.clipBehavior,
    super.color,
    super.constraints,
    super.elevation,
    super.enableFeedback,
    super.enabled,
    super.icon,
    super.iconColor,
    super.iconSize,
    super.initialValue,
    super.menuPadding,
    super.offset,
    super.onCanceled,
    super.onOpened,
    super.onSelected,
    super.padding,
    super.position,
    super.requestFocus,
    super.routeSettings,
    super.tooltip,
    super.useRootNavigator,
    super.popUpAnimationStyle = const AnimationStyle(
      curve: Curves.easeOutCirc,
      reverseCurve: Curves.easeInCirc,
    ),
  });
}

class PfsPopupMenuItem<T> extends PopupMenuItem<T> {
  const PfsPopupMenuItem({
    required super.child,
    super.key,
    super.enabled,
    super.labelTextStyle,
    super.mouseCursor,
    super.onTap,
    super.height = kMinInteractiveDimension * 0.75,
    super.padding = const EdgeInsets.only(right: 20, left: 16),
    super.textStyle,
    super.value,
  });
}

class NotifierSwitchItem extends StatelessWidget {
  const NotifierSwitchItem({
    super.key,
    required this.notifier,
    required this.title,
    this.onChanged,
  });

  final ValueNotifier<bool> notifier;
  final Widget title;
  final Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, notifierValue, __) {
        return MergeSemantics(
          child: ListTile(
            onTap:
                onChanged == null ? () => handleChange(!notifierValue) : null,
            trailing: ExcludeFocus(
              child: Phswitch(
                value: notifierValue,
                onChanged: handleChange,
              ),
            ),
            title: title,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
        );
      },
    );
  }

  void handleChange(bool newValue) {
    notifier.value = newValue;
    onChanged?.call();
  }
}

class Phswitch extends StatelessWidget {
  const Phswitch({
    super.key,
    required this.value,
    this.onChanged,
    this.height = 26,
  });

  final bool value;
  final double height;
  final void Function(bool newValue)? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBoxFitted(
      height: height,
      child: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
