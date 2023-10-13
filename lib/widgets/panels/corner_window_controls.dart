import 'package:flutter/material.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/widgets/image_phviewer.dart';

class CornerWindowControls extends StatelessWidget {
  const CornerWindowControls({
    super.key,
    required this.windowState,
    required this.imagePhviewer,
  });

  final PfsWindowState windowState;
  final ImagePhviewer imagePhviewer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color watermarkColor = theme.colorScheme.outline;
    final cornerWatermarkTextStyle =
        theme.textTheme.bodySmall!.copyWith(color: watermarkColor);

    final soundShortcut =
        PfsLocalization.tooltipShortcut(Phshortcuts.toggleSounds);

    return Positioned(
      right: 8,
      top: 8,
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Wrap(
            spacing: 3,
            direction: Axis.horizontal,
            alignment: WrapAlignment.end,
            children: [
              CornerButton(
                onPressed: () => windowState.isSoundsEnabled.toggle(),
                icon: windowState.isSoundsEnabled.boolValue
                    ? Icons.volume_up
                    : Icons.volume_off,
                tooltip: windowState.isSoundsEnabled.boolValue
                    ? 'Mute sounds ($soundShortcut)'
                    : 'Unmute sounds ($soundShortcut)',
              ),
              CornerButton(
                onPressed: () => windowState.isAlwaysOnTop.toggle(),
                icon: windowState.isAlwaysOnTop.boolValue
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                tooltip: PfsLocalization.buttonTooltip(
                  commandName: PfsLocalization.alwaysOnTop,
                  shortcut: Phshortcuts.alwaysOnTop,
                ),
                isSelected: windowState.isAlwaysOnTop.boolValue,
              ),
              CornerButton(
                onPressed: () => windowState.isShowingCheatSheet.set(true),
                icon: Icons.help_rounded,
                tooltip: PfsLocalization.buttonTooltip(
                  commandName: PfsLocalization.help,
                  shortcut: Phshortcuts.help,
                ),
              ),
              //Phbuttons.topControl(() {}, Icons.info_outline_rounded, 'About...'),
            ],
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
                  const Text('For testing only\n${PfsLocalization.version}'),
                  if (imagePhviewer.currentZoomScale != 1.0)
                    Text('Zoom ${imagePhviewer.currentZoomScalePercent}%'),
                ],
              ),
            ),
          ),
        ],
      ),
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
    const double topControlDiameter = 35;
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