import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';

class Phbuttons {
  static Widget topControl(
      {Function()? onPressed,
      required IconData icon,
      String? tooltip,
      bool isSelected = false}) {
    const double buttonSpacing = 0;
    const double iconSize = 20;

    return Container(
      margin: const EdgeInsets.only(right: buttonSpacing),
      child: IconButton(
        style: PfsTheme.topControlStyle,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        tooltip: tooltip,
        isSelected: isSelected,
      ),
    );
  }

  static Widget openFiles() {
    final toolTipText =
        'Open images... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFiles)})\n${PfsLocalization.secondaryPressCapital} to open image folder... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFolder)})';

    return PfsAppModel.scope(
      (context, __, model) {
        final style = FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        );
        return Tooltip(
          message: toolTipText,
          child: GestureDetector(
            onSecondaryTap: () => model.openFilePickerForFolder(),
            child: FilledButton(
              style: style,
              onPressed: () => model.openFilePickerForImages(),
              child: const SizedBox(
                width: 40,
                child: Icon(
                  Icons.folder_open,
                ),
              ),
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
          message:
              '$currentTimerSeconds seconds per image.\n${PfsLocalization.pressCapital} to edit timer. (${PfsLocalization.tooltipShortcut(Phshortcuts.openTimerMenu)})',
          child: TextButton(
            onPressed: onPressed,
            child: textThenIcon('${currentTimerSeconds}s',
                const Icon(Icons.timer_outlined, size: iconSize)),
          ),
        );
      },
    );
  }
}

class ImageSetButton extends StatelessWidget {
  const ImageSetButton({super.key});

  static const double _iconSize = 18;
  static const Icon _icon = Icon(Icons.image, size: _iconSize);

  @override
  Widget build(BuildContext context) {
    return PfsAppModel.scope((_, __, model) {
      final fileCount = model.fileList.getCount();
      final String tooltip =
          '$fileCount images loaded.\n${PfsLocalization.pressCapital} to open a different image set... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFiles)})\n${PfsLocalization.secondaryPressCapital} to open an image folder... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFolder)})';

      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onSecondaryTap: () => model.openFilePickerForFolder(),
          child: TextButton(
            onPressed: () => model.openFilePickerForImages(),
            child: SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Spacer(),
                    Phbuttons.textThenIcon(fileCount.toString(), _icon),
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

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton(
        style: PfsTheme.minorWindowControlButtonStyle,
        onPressed: onPressed,
        child: Icon(
          icon,
          size: PfsTheme.minorWindowControlIconSize,
        ),
      ),
    );
  }
}

class BottomBarTimerControl extends StatelessWidget {
  const BottomBarTimerControl({
    super.key,
    this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final Function()? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
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

    if (isMinimized) {
      return MinorWindowControlButton(
        icon: expandIcon,
        tooltip: 'Expand controls (H)',
        onPressed: onPressed,
      );
    } else {
      return MinorWindowControlButton(
        icon: collapseIcon,
        tooltip: 'Minimize controls (H)',
        onPressed: onPressed,
      );
    }
  }
}
