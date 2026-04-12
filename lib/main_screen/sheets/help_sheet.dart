import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/phanimations.dart';

class HelpSheet extends StatelessWidget {
  const HelpSheet({
    super.key,
  });

  static const double sheetHeight = 500;
  static const Icon headingIcon = Icon(
    Icons.keyboard,
    size: 40,
  );

  @override
  Widget build(BuildContext context) {
    final windowSize = MediaQuery.sizeOf(context);

    final bool isWindowShort = windowSize.height < 520;
    final bool isWindowVeryShort = windowSize.height < 420;
    final bool isWindowNarrow = windowSize.width < 680;
    final bool isWindowVeryNarrow = windowSize.width < 580;

    const normalPadding = EdgeInsets.symmetric(horizontal: 30);
    const narrowPadding = EdgeInsets.symmetric(horizontal: 7);

    final dynamicPadding = isWindowNarrow ? narrowPadding : normalPadding;

    final headingStyle = Theme.of(context).textTheme.headlineSmall;

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              height: sheetHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(0xEE),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isWindowVeryShort)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: SizedBox(
                        child: Column(
                          children: [
                            if (!isWindowShort) headingIcon,
                            Text(
                              "Keyboard Shortcuts",
                              style: headingStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 720,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        AnimatedPadding(
                          duration: Phanimations.fastDuration,
                          padding: dynamicPadding,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ShortcutListItem.fromSingleActivator(
                                text: "Next image",
                                activator: Phshortcuts.verticalNext,
                              ),
                              ShortcutListItem.fromSingleActivator(
                                text: "Previous image",
                                activator: Phshortcuts.verticalPrevious,
                              ),
                              const Text(''),
                              ShortcutListItem.fromSingleActivator(
                                text: "Play/Pause",
                                activator: Phshortcuts.playPause,
                              ),
                              ShortcutListItem.fromSingleActivator(
                                text: "Restart timer",
                                activator: Phshortcuts.restartTimer,
                              ),
                              ShortcutListItem.fromSingleActivator(
                                text: "Change timer duration",
                                activator: Phshortcuts.openTimerMenu,
                              ),
                            ],
                          ),
                        ),
                        if (!isWindowVeryNarrow)
                          AnimatedPadding(
                            duration: Phanimations.fastDuration,
                            padding: dynamicPadding,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ShortcutListItem.fromSingleActivator(
                                  text: "Open images...",
                                  activator: Phshortcuts.openFiles,
                                ),
                                ShortcutListItem.fromSingleActivator(
                                  text:
                                      'Toggle "${PfsLocalization.alwaysOnTop}"',
                                  activator: Phshortcuts.alwaysOnTop,
                                ),
                                ShortcutListItem.fromSingleActivator(
                                  text: "Show/hide bottom bar",
                                  activator: Phshortcuts.toggleBottomBar,
                                ),
                                ShortcutListItem.fromSingleActivator(
                                  text: "Open help sheet",
                                  activator: Phshortcuts.help,
                                ),
                                ShortcutListItem.fromSingleActivator(
                                  text: "Mute/unmute sounds",
                                  activator: Phshortcuts.toggleSounds,
                                ),
                              ],
                            ),
                          ),
                        if (isWindowVeryNarrow)
                          AnimatedPadding(
                            duration: Phanimations.fastDuration,
                            padding: dynamicPadding,
                            child: Center(
                              widthFactor: 5,
                              heightFactor: 5,
                              child: Text(
                                "...",
                                style: headingStyle,
                              ),
                            ),
                          ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  if (!isWindowVeryShort)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: 600,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Icon(
                                Icons.file_open_outlined,
                                size: 30,
                              ),
                            ),
                            const Text(
                              'You can also load new images using drag and drop,\nor paste screenshots.',
                            ),
                            if (!isWindowVeryNarrow)
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShortcutListItem extends StatelessWidget {
  const ShortcutListItem({
    super.key,
    this.text,
    this.keyLabel,
    this.modifier,
    this.modifier2,
  });

  static const ctrlLabel = "Ctrl";
  static const cmdLabel = "Cmd";
  final String? text, keyLabel, modifier, modifier2;

  ShortcutListItem.fromSingleActivator({
    Key? key,
    String? text,
    required SingleActivator activator,
  }) : this(
         key: key,
         text: text,
         keyLabel: activator.trigger.keyLabel,
         modifier: Platform.isMacOS && activator.meta
             ? cmdLabel
             : activator.control
             ? ctrlLabel
             : null,
       );

  @override
  Widget build(BuildContext context) {
    const double textWidth = 160;
    const double keysWidth = 100;
    const double padding = 3;

    return Padding(
      padding: const EdgeInsets.all(padding),
      child: Row(
        children: [
          if (text != null)
            SizedBox(
              width: textWidth,
              child: Text(text!),
            ),
          SizedBox(
            width: keysWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (modifier != null) KeySymbol(modifier!),
                if (modifier != null) const Text(' + '),
                if (modifier2 != null) KeySymbol(modifier2!),
                if (modifier2 != null) const Text(' + '),
                KeySymbol(keyLabel!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KeySymbol extends StatelessWidget {
  const KeySymbol(
    this.label, {
    super.key,
  });

  final String label;

  static const double height = 32;
  static const double minWidth = 32;
  static const double verticalPadding = 3;
  static const double horizontalPadding = 8;
  static const double borderRadius = 5;
  static const Color keyColor = Color(0xFF272727);
  static const Color keyLegendColor = Color.fromARGB(255, 235, 235, 235);
  static const Border border = Border.fromBorderSide(
    BorderSide(
      color: Color.fromARGB(87, 114, 114, 114),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: minWidth, minHeight: height),
      padding: const EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        border: border,
        color: keyColor,
      ),
      child: Text(
        label,
        style: const TextStyle(color: keyLegendColor),
      ),
    );
  }
}
