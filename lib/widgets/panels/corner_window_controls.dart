import 'package:flutter/material.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
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
    final soundShortcut =
        PfsLocalization.tooltipShortcut(Phshortcuts.toggleSounds);
        
    final theme = Theme.of(context);
    
    final Color watermarkColor = theme.colorScheme.outline;
    final cornerWatermarkTextStyle = theme.textTheme.bodySmall!.copyWith(color: watermarkColor);

    return Positioned(
      right: 4,
      top: 2,
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Wrap(
            spacing: 3,
            direction: Axis.horizontal,
            alignment: WrapAlignment.end,
            children: [
              cornerButton(
                onPressed: () => windowState.isSoundsEnabled.toggle(),
                icon: windowState.isSoundsEnabled.boolValue
                    ? Icons.volume_up
                    : Icons.volume_off,
                tooltip: windowState.isSoundsEnabled.boolValue
                    ? 'Mute sounds ($soundShortcut)'
                    : 'Unmute sounds ($soundShortcut)',
              ),
              cornerButton(
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
              cornerButton(
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
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
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

  static Widget cornerButton(
      {Function()? onPressed,
      required IconData icon,
      String? tooltip,
      bool isSelected = false}) {
    const Color topBarButtonColor = Colors.black12;
    const Color topBarButtonActiveColor = Color.fromARGB(49, 196, 117, 0);

    const double topControlDiameter = 15;
    const Size topControlSize = Size(topControlDiameter, topControlDiameter);

    final buttonStyle = ButtonStyle(
      fixedSize: const MaterialStatePropertyAll(topControlSize),
      backgroundColor: const MaterialStatePropertyAll(Colors.transparent),
      padding: const MaterialStatePropertyAll(EdgeInsets.zero),
      iconColor: PfsTheme.hoverActiveColors(
        idle: topBarButtonColor,
        hover: Colors.black,
        active: topBarButtonActiveColor,
      ),
    );

    const double buttonSpacing = 0;
    const double iconSize = 20;

    return Container(
      margin: const EdgeInsets.only(right: buttonSpacing),
      child: IconButton(
        style: buttonStyle,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        tooltip: tooltip,
        isSelected: isSelected,
      ),
    );
  }
}
