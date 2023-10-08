import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';

class Phbuttons {
  static const Color accentColor = Colors.blueAccent;
  static const Color topBarButtonColor = Colors.black12;

  static Widget topControl(
      Function()? onPressed, IconData icon, String? tooltip) {
    const double buttonSpacing = 5;
    const double iconSize = 20;
    const size = Size(25, 25);
    final style = TextButton.styleFrom(
      minimumSize: size,
      maximumSize: size,
      padding: const EdgeInsets.all(0),
    );

    return Container(
      margin: const EdgeInsets.only(right: buttonSpacing),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        color: topBarButtonColor,
        tooltip: tooltip,
        style: style,
      ),
    );
  }

  static Widget timerControl(
      Function()? onPressed, IconData icon, String? tooltip) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      focusColor: const Color(0xFFFFE4C0),
    );
  }

  static Widget bottomButton(
      Function()? onPressed, IconData icon, String? tooltip) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      focusColor: const Color(0xFFFFE4C0),
    );
  }

  static Widget playPauseTimer(Animation<double> progress) {
    return PfsAppModel.scope((_, __, model) {      
      const playButtonTooltip = 'Timer paused. Press to resume (P)';
      const pauseButtonTooltip = 'Timer running. Press to pause (P)';
      final icon = AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: progress,
      );
      const Color pausedColor = Color.fromARGB(255, 255, 196, 0);
      const Color playingColor = accentColor;

      bool allowTimerControl = model.allowTimerPlayPause;
      Color buttonColor = allowTimerControl
          ? (model.isTimerRunning ? playingColor : pausedColor)
          : Colors.grey.shade500;

      final style = FilledButton.styleFrom(backgroundColor: buttonColor);
      final tooltipText =
          model.isTimerRunning ? pauseButtonTooltip : playButtonTooltip;

      return Tooltip(
        message: tooltipText,
        child: FilledButton(
          style: style,
          onPressed: () => model.playPauseToggleTimer(),
          child: SizedBox(
            width: 50,
            child: Align(alignment: Alignment.center, child: icon),
          ),
        ),
      );
    });
  }

  static Widget openFiles() {
    const toolTipText =
        'Open images... (Ctrl+O)\nRight-click to open image folder... (Ctrl+Shift+O)';
    const color = Colors.white;

    var style = FilledButton.styleFrom(backgroundColor: accentColor);

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
                child: Icon(Icons.folder_open, color: color),
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

  static Widget timerButton({required Function() onPressed}) {
    return PfsAppModel.scope(
      (_, __, model) {
        final currentTimerSeconds = model.timer.duration.inSeconds;
        const double iconSize = 18;
        const opacity = 0.4;

        return Opacity(
          opacity: opacity,
          child: Tooltip(
            message:
                '${model.timer.duration.inSeconds} seconds per image.\nClick to edit timer. (F2)',
            child: TextButton(
                onPressed: onPressed,
                child: textThenIcon('${currentTimerSeconds}s',
                    const Icon(Icons.timer_outlined, size: iconSize))),
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

      imageStats() {
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
                      textThenIcon(fileCount.toString(), icon),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Opacity(
        opacity: 0.4,
        child: imageStats(),
      );
    });
  }

  static Widget collapseBottomBarButton(
      {required bool isMinimized, Function()? onPressed}) {
    const buttonSize = Size(25, 25);
    const collapseIcon = Icons.expand_more_rounded;
    const expandIcon = Icons.expand_less_rounded;

    final IconData buttonIcon = isMinimized ? expandIcon : collapseIcon;
    final String tooltip =
        isMinimized ? 'Expand controls (H)' : 'Minimize controls (H)';
    const iconColor = Colors.black38;

    const double iconSize = 20;

    final style = TextButton.styleFrom(
      minimumSize: buttonSize,
      maximumSize: buttonSize,
      padding: const EdgeInsets.all(0),
    );

    return Tooltip(
      message: tooltip,
      child: TextButton(
        style: style,
        onPressed: onPressed,
        child: Icon(
          buttonIcon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}
