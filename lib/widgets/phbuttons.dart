import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';

class Phbuttons {
  static Widget openFiles({double width = 40.0}) {
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
              child: SizedBox(
                width: width,
                child: const Icon(Icons.folder_open),
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
  const ImageSetButton({
    super.key,
    this.narrowButton = false,
  });

  static const double _iconSize = 18;
  static const Icon _icon = Icon(Icons.image, size: _iconSize);

  final bool narrowButton;

  @override
  Widget build(BuildContext context) {
    return PfsAppModel.scope((_, __, model) {
      final fileCount = model.fileList.getCount();
      final String tooltip =
          '$fileCount ${PfsLocalization.imageNoun(fileCount)} loaded.\n${PfsLocalization.pressCapital} to open a different image set... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFiles)})\n${PfsLocalization.secondaryPressCapital} to open an image folder... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFolder)})';

      const double wideWidth = 80;
      const double narrowWidth = 18;
      
      final double currentWidth = narrowButton ? narrowWidth : wideWidth;

      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onSecondaryTap: () => model.openFilePickerForFolder(),
          child: TextButton(
            onPressed: () => model.openFilePickerForImages(),
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

  static final foregroundColors = PfsTheme.hoverColors(
    idle: const Color.fromARGB(90, 0, 0, 0),
    hover: Colors.black87,
  );
  static const double iconSize = 20;
  static const buttonSize = Size(20, 20);
  static final buttonStyle = ButtonStyle(
    shape: const MaterialStatePropertyAll(CircleBorder()),
    minimumSize: const MaterialStatePropertyAll(buttonSize),
    maximumSize: const MaterialStatePropertyAll(buttonSize),
    padding: const MaterialStatePropertyAll(EdgeInsets.all(0)),
    foregroundColor: foregroundColors,
  );

  @override
  Widget build(BuildContext context) {
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
