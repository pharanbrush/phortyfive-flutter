import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';

class Phbuttons {
  static const String revealInExplorerText = 'Show in Explorer';

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

  static Widget bottomButton(
      Function()? onPressed, IconData icon, String? tooltip) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
    );
  }

  static Widget openFiles() {
    const toolTipText =
        'Open images... (Ctrl+O)\nRight-click to open image folder... (Ctrl+Shift+O)';

    var style = FilledButton.styleFrom(backgroundColor: PfsTheme.accentColor);

    return PfsAppModel.scope(
      (_, __, model) {
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
                  //color: PfsTheme.filledButtonContentColor,
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
    return PfsAppModel.scope(
      (_, __, model) {
        final currentTimerSeconds = model.timer.duration.inSeconds;
        const iconSize = PfsTheme.timerBarIconSize;

        return Tooltip(
          message:
              '${model.timer.duration.inSeconds} seconds per image.\nClick to edit timer. (F2)',
          child: TextButton(
            onPressed: onPressed,
            style: PfsTheme.bottomBarButtonStyle,
            child: textThenIcon('${currentTimerSeconds}s',
                const Icon(Icons.timer_outlined, size: iconSize)),
          ),
        );
      },
    );
  }

  static Widget imageSetButton() {
    return PfsAppModel.scope((_, __, model) {
      const double iconSize = 18;
      const Icon icon = Icon(Icons.image, size: iconSize);

      final fileCount = model.fileList.getCount();
      final String tooltip =
          '$fileCount images loaded.\nClick to open a different image set... (Ctrl+O)\nRight-click to open an image folder... (Ctrl+Shift+O)';

      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onSecondaryTap: () => model.openFilePickerForFolder(),
          child: TextButton(
            style: PfsTheme.bottomBarButtonStyle,
            onPressed: () => model.openFilePickerForImages(),
            child: SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Spacer(),
                    textThenIcon(fileCount.toString(), icon),
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

  static Widget collapseBottomBarButton({
    required bool isMinimized,
    Function()? onPressed,
  }) {
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
    return Tooltip(
      message: tooltip,
      child: IconButton(
        style: PfsTheme.bottomBarButtonStyle,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
