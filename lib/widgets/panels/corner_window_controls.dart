import 'package:flutter/material.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/hover_container.dart';
import 'package:pfs2/widgets/image_phviewer.dart';
import 'package:pfs2/widgets/phbuttons.dart';

class CornerWindowControls extends StatelessWidget {
  const CornerWindowControls({
    super.key,
    required this.windowState,
    required this.imagePhviewer,
    required this.helpMenu,
    required this.settingsMenu,
  });

  final PfsWindowState windowState;
  final ImagePhviewer imagePhviewer;
  final ModalMenu helpMenu, settingsMenu;

  static const double controlsWidth = 130;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color watermarkColor = theme.colorScheme.outline;
    final cornerWatermarkTextStyle =
        theme.textTheme.bodySmall!.copyWith(color: watermarkColor);

    final soundShortcut =
        PfsLocalization.tooltipShortcut(Phshortcuts.toggleSounds);

    final containerBorderRadius =
        theme.extension<PfsAppTheme>()?.borderRadius ??
            BorderRadius.circular(25);

    return Positioned(
      right: 7,
      top: Phbuttons.windowTitleBarHeight,
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          HoverContainer(
            hoverBackgroundColor: theme.scaffoldBackgroundColor,
            borderRadius: containerBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Wrap(
                spacing: 3,
                direction: Axis.horizontal,
                alignment: WrapAlignment.end,
                children: [
                  CornerButton(
                    onPressed: () => settingsMenu.open(),
                    icon: Icons.settings,
                    tooltip: 'Settings',
                  ),
                  NotifierToggleCornerButton(
                    notifier: windowState.isSoundsEnabled,
                    falseIcon: Icons.volume_off,
                    trueIcon: Icons.volume_up,
                    trueTooltip: 'Mute sounds ($soundShortcut)',
                    falseTooltip: 'Unmute sounds ($soundShortcut)',
                  ),
                  NotifierToggleCornerButton(
                    notifier: windowState.isAlwaysOnTop,
                    falseIcon: Icons.picture_in_picture_outlined,
                    trueIcon: Icons.picture_in_picture,
                    highlightIfTrue: true,
                    trueTooltip: PfsLocalization.buttonTooltip(
                      commandName: PfsLocalization.alwaysOnTop,
                      shortcut: Phshortcuts.alwaysOnTop,
                    ),
                    falseTooltip: PfsLocalization.buttonTooltip(
                      commandName: PfsLocalization.alwaysOnTop,
                      shortcut: Phshortcuts.alwaysOnTop,
                    ),
                  ),
                  CornerButton(
                    onPressed: () => helpMenu.open(),
                    icon: Icons.help_rounded,
                    tooltip: PfsLocalization.buttonTooltip(
                      commandName: PfsLocalization.help,
                      shortcut: Phshortcuts.help,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: DefaultTextStyle(
              textAlign: TextAlign.right,
              style: cornerWatermarkTextStyle,
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 5,
                children: [
                  const Text('For testing only\n'
                      '${PfsLocalization.version}'),
                  ValueListenableBuilder(
                    valueListenable: imagePhviewer.zoomLevelListenable,
                    builder: (_, __, ___) {
                      return Visibility(
                        visible: !imagePhviewer.isZoomLevelDefault,
                        child: Text(
                            'Zoom ${imagePhviewer.currentZoomScalePercent}%'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotifierToggleCornerButton extends StatelessWidget {
  const NotifierToggleCornerButton({
    super.key,
    required this.notifier,
    required this.falseIcon,
    required this.trueIcon,
    this.falseTooltip,
    this.trueTooltip,
    this.highlightIfTrue = false,
  });

  final ValueNotifier<bool> notifier;
  final IconData falseIcon, trueIcon;
  final String? falseTooltip, trueTooltip;
  final bool highlightIfTrue;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, valueIsTrue, __) {
        return CornerButton(
          onPressed: () => notifier.toggle(),
          icon: valueIsTrue ? trueIcon : falseIcon,
          tooltip: valueIsTrue ? trueTooltip : falseTooltip,
          isSelected: highlightIfTrue && valueIsTrue,
        );
      },
    );
  }
}

class CornerButton extends StatelessWidget {
  const CornerButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isSelected = false,
  });

  final Function()? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    const double topControlDiameter = 32;
    const Size topControlSize = Size(topControlDiameter, topControlDiameter);
    const sizes = MaterialStatePropertyAll(topControlSize);

    const buttonStyle = ButtonStyle(
      fixedSize: sizes,
      minimumSize: sizes,
      iconSize: MaterialStatePropertyAll(topControlDiameter * .55),
      padding: MaterialStatePropertyAll(EdgeInsets.zero),
    );

    return IconButton(
      style: buttonStyle,
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      isSelected: isSelected,
    );
  }
}
